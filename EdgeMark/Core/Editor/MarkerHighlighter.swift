import AppKit

/// Applies the Marker 1 line color as an overlay on top of the editor's
/// normal plain-text styling.
///
/// Uses TextKit 2 rendering attributes (`NSTextLayoutManager`) when
/// available, otherwise TextKit 1 temporary attributes (`NSLayoutManager`).
/// Both layer on top of the storage's persistent attributes, so the base
/// text color is never lost.
///
/// The overlay is tracked per text view and applied INCREMENTALLY: only the
/// ranges whose color actually changed are touched. This matters because
/// TextKit attribute operations are laid-out-glyph-scoped — clearing or
/// invalidating over the FULL document range forces layout/glyph generation
/// across the whole note, which caused a visible ~0.5s color lag when the
/// previous implementation cleared the entire document on every pass.
enum MarkerHighlighter {

    // MARK: - Per-view applied state

    /// Snapshot of the last overlay applied to a text view, used to diff the
    /// next pass. Keyed weakly so entries vanish with their text views.
    private final class AppliedState {
        var ranges: [NSRange] = []
        var enabled = false
        var prefix = ""
        var colorHex = ""
        var documentLength = -1
    }

    private static let appliedStates = NSMapTable<NSTextView, AppliedState>(
        keyOptions: .weakMemory,
        valueOptions: .strongMemory
    )

    private static func appliedState(for textView: NSTextView) -> AppliedState {
        if let state = appliedStates.object(forKey: textView) {
            return state
        }
        let state = AppliedState()
        appliedStates.setObject(state, forKey: textView)
        return state
    }

    /// Returns NSRanges (in the NSString's UTF-16 length) for lines that
    /// start with the configured prefix. Empty when disabled or prefix empty.
    static func markerRanges(in text: String, prefix: String) -> [NSRange] {
        guard !prefix.isEmpty, !text.isEmpty else { return [] }
        let ns = text as NSString
        let total = ns.length
        var out: [NSRange] = []
        var loc = 0
        while loc < total {
            let lineRange = ns.lineRange(for: NSRange(location: loc, length: 0))
            // Check if the line's content starts with prefix.
            // ns.lineRange includes the trailing newline; we test the prefix at line start.
            if lineRange.length >= prefix.utf16.count {
                let prefixRange = NSRange(location: lineRange.location, length: prefix.utf16.count)
                let candidate = ns.substring(with: prefixRange)
                if candidate == prefix {
                    out.append(lineRange)
                }
            }
            let next = NSMaxRange(lineRange)
            if next <= loc { break }
            loc = next
        }
        return out
    }

    /// Updates the marker overlay on a text view. Cheap and safe to call
    /// frequently: when nothing changed since the last pass (same settings,
    /// same document length, same marker ranges) it only refreshes typing
    /// attributes, and when something did change it touches only the
    /// affected line ranges — never the whole document.
    static func apply(to textView: NSTextView) {
        let settings = AppSettings.shared
        let prefix = settings.marker1Prefix
        let enabled = settings.marker1Enabled && !prefix.isEmpty
        let markerColor = settings.nsMarker1Color

        let ns = textView.string as NSString
        let ranges = (enabled && ns.length > 0) ? markerRanges(in: textView.string, prefix: prefix) : []

        let state = appliedState(for: textView)
        let unchanged = state.enabled == enabled
            && state.prefix == prefix
            && state.colorHex == settings.marker1ColorHex
            && state.documentLength == ns.length
            && state.ranges == ranges
        if unchanged {
            updateTypingAttributes(for: textView, enabled: enabled, markerColor: markerColor, prefix: prefix)
            return
        }

        // Ranges to clear: the previously applied ranges (expanded to their full
        // current line boundaries so text shifted by an edit is still covered)
        // plus the new ranges (covers color/prefix changes in place).
        var clearRanges: [NSRange] = []
        for r in state.ranges {
            guard r.location < ns.length else { continue }
            let clamped = NSRange(location: r.location, length: min(r.length, ns.length - r.location))
            clearRanges.append(ns.lineRange(for: NSRange(location: clamped.location, length: max(clamped.length, 1))))
        }
        clearRanges.append(contentsOf: ranges)

        // Ensure layout is complete before touching rendering/temporary attributes.
        // At open time the TextKit layout may not have generated glyphs yet, so
        // adding rendering attributes would silently do nothing and the cached
        // AppliedState would prevent a retry (stuck unhighlighted until an edit).
        if ns.length > 0 {
            if let tlm = textView.textLayoutManager {
                tlm.ensureLayout(for: tlm.documentRange)
            }
            if let lm = textView.layoutManager, let container = textView.textContainer ?? lm.textContainers.first {
                lm.ensureLayout(for: container)
            }
        }

        var appliedOK = true
        // Prefer TextKit 2 layout manager if present.
        if let tlm = textView.textLayoutManager,
           let tcm = tlm.textContentManager {
            let docRange = tlm.documentRange
            for r in clearRanges where r.length > 0 {
                if let tRange = nsRangeToTextRange(r, in: tcm, docRange: docRange) {
                    tlm.removeRenderingAttribute(.foregroundColor, for: tRange)
                } else {
                    appliedOK = false
                }
            }
            if enabled {
                for r in ranges where r.length > 0 {
                    if let tRange = nsRangeToTextRange(r, in: tcm, docRange: docRange) {
                        tlm.addRenderingAttribute(.foregroundColor, value: markerColor, for: tRange)
                    } else {
                        appliedOK = false
                    }
                }
            }
        } else if let lm = textView.layoutManager {
            // TextKit 1 fallback. Temporary attributes only render for laid-out
            // glyphs, so keep the touched ranges as small as possible.
            for r in clearRanges where r.length > 0 {
                lm.removeTemporaryAttribute(.foregroundColor, forCharacterRange: r)
            }
            if enabled {
                for r in ranges where r.length > 0 {
                    lm.addTemporaryAttribute(.foregroundColor, value: markerColor, forCharacterRange: r)
                }
            }
        } else {
            // Last resort: directly mutate storage. Only reachable when neither
            // layout manager exists (e.g. headless/unit-test environments).
            fallbackStorageApply(to: textView, enabled: enabled, markerColor: markerColor, prefix: prefix)
        }

        // If TextKit 2 conversion failed (layout not ready), don't cache the
        // state as successfully applied — schedule a retry and fall back to
        // storage so the highlight is at least visible.
        if !appliedOK, enabled, !ranges.isEmpty {
            fallbackStorageApply(to: textView, enabled: enabled, markerColor: markerColor, prefix: prefix)
            DispatchQueue.main.async {
                // Retry with layout now ready; the cached state is still stale
                // so the next apply will not hit the early-return.
                apply(to: textView)
            }
            // Don't update state yet — let the retry cache it.
            updateTypingAttributes(for: textView, enabled: enabled, markerColor: markerColor, prefix: prefix)
            return
        }

        state.ranges = ranges
        state.enabled = enabled
        state.prefix = prefix
        state.colorHex = settings.marker1ColorHex
        state.documentLength = ns.length
        updateTypingAttributes(for: textView, enabled: enabled, markerColor: markerColor, prefix: prefix)
    }

    // MARK: - Typing attributes

    /// When the caret is inside a marker line, new typing should be marker
    /// colored. Otherwise it should be the normal text color.
    private static func updateTypingAttributes(for textView: NSTextView, enabled: Bool, markerColor: NSColor, prefix: String) {
        guard enabled else {
            // Restore default typing color.
            var attrs = textView.typingAttributes
            attrs[.foregroundColor] = AppSettings.shared.nsTextColor
            textView.typingAttributes = attrs
            return
        }
        let sel = textView.selectedRange()
        // Determine if caret line starts with prefix.
        let ns = textView.string as NSString
        guard sel.location != NSNotFound, ns.length >= 0 else { return }
        let clamped = min(sel.location, ns.length)
        let lineRange = ns.lineRange(for: NSRange(location: clamped, length: 0))
        let isMarkerLine: Bool = {
            guard lineRange.length >= prefix.utf16.count else { return false }
            let r = NSRange(location: lineRange.location, length: prefix.utf16.count)
            return ns.substring(with: r) == prefix
        }()
        var attrs = textView.typingAttributes
        attrs[.foregroundColor] = isMarkerLine ? markerColor : AppSettings.shared.nsTextColor
        textView.typingAttributes = attrs
    }

    // MARK: - Helpers

    private static func nsRangeToTextRange(_ nsRange: NSRange, in tcm: NSTextContentManager, docRange: NSTextRange) -> NSTextRange? {
        guard let start = tcm.location(docRange.location, offsetBy: nsRange.location),
              let end = tcm.location(start, offsetBy: nsRange.length) else { return nil }
        return NSTextRange(location: start, end: end)
    }

    private static func fallbackStorageApply(to textView: NSTextView, enabled: Bool, markerColor: NSColor, prefix: String) {
        guard let storage = textView.textStorage else { return }
        let fullLen = (textView.string as NSString).length
        // Re-apply uniform base color then marker.
        let baseColor = AppSettings.shared.nsTextColor
        if fullLen > 0 {
            storage.addAttribute(.foregroundColor, value: baseColor, range: NSRange(location: 0, length: fullLen))
        }
        guard enabled else { return }
        let ranges = markerRanges(in: textView.string, prefix: prefix)
        for r in ranges {
            storage.addAttribute(.foregroundColor, value: markerColor, range: r)
        }
    }

    /// Convenience: find all editor NSTextViews in all windows and apply.
    /// Safe to call on any thread (dispatches to main).
    static func applyToAllVisibleEditors() {
        DispatchQueue.main.async {
            for window in NSApp.windows {
                guard let content = window.contentView else { continue }
                findAndApply(in: content)
            }
        }
    }

    private static func findAndApply(in view: NSView) {
        // Check self
        if let tv = view as? NSTextView {
            // To avoid coloring the small settings text field for the prefix,
            // ignore field editors and views with tiny bounds.
            if tv.isFieldEditor { /* skip */ } else if tv.frame.width < 50 || tv.frame.height < 50 {
                if tv.string.count > 0 || tv.isEditable {
                    apply(to: tv)
                }
            } else {
                apply(to: tv)
            }
        }
        for sub in view.subviews {
            findAndApply(in: sub)
        }
    }

    /// Global observers — call once at app launch. The per-editor coordinator
    /// applies synchronously on edits; these catch any text view it misses
    /// and are near-free when nothing changed (see the fast path in apply).
    static func startObserving() {
        NotificationCenter.default.addObserver(forName: NSText.didChangeNotification, object: nil, queue: .main) { note in
            guard let tv = note.object as? NSTextView else { return }
            if tv.isFieldEditor { return }
            DispatchQueue.main.async {
                apply(to: tv)
            }
        }
        NotificationCenter.default.addObserver(forName: NSTextView.didChangeSelectionNotification, object: nil, queue: .main) { note in
            guard let tv = note.object as? NSTextView else { return }
            if tv.isFieldEditor { return }
            // Selection change means caret moved — typing color may need update.
            DispatchQueue.main.async {
                apply(to: tv)
            }
        }
        NotificationCenter.default.addObserver(forName: .markerSettingsChanged, object: nil, queue: .main) { _ in
            applyToAllVisibleEditors()
        }
    }
}
