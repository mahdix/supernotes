import AppKit

/// Applies the Marker 1/2/3/4/5 line colors as overlays on top of the editor's
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
        var ranges1: [NSRange] = []
        var ranges2: [NSRange] = []
        var ranges3: [NSRange] = []
        var ranges4: [NSRange] = []
        var ranges5: [NSRange] = []
        var enabled1 = false
        var enabled2 = false
        var enabled3 = false
        var enabled4 = false
        var enabled5 = false
        var prefix1 = ""
        var prefix2 = ""
        var prefix3 = ""
        var prefix4 = ""
        var prefix5 = ""
        var colorHex1 = ""
        var colorHex2 = ""
        var colorHex3 = ""
        var colorHex4 = ""
        var colorHex5 = ""
        var documentLength = -1

        // Legacy single-marker fields kept for migration diff (not used for new logic
        // but prevents stale state's `ranges` from leaking if accessed elsewhere).
        var ranges: [NSRange] = []
        var enabled = false
        var prefix = ""
        var colorHex = ""
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

    /// Classifies each line to at most one marker. When a line matches multiple
    /// prefixes, the longest prefix wins (most specific); tie goes to the lower
    /// marker index (1 < 2 < 3 < 4 < 5). This prevents overlapping ranges when e.g.
    /// marker1 = "!" and marker2 = "!!".
    static func classifiedMarkerRanges(
        in text: String,
        markers: [(prefix: String, enabled: Bool)]
    ) -> [[NSRange]] {
        guard !text.isEmpty, !markers.isEmpty else {
            return Array(repeating: [], count: markers.count)
        }
        let ns = text as NSString
        let total = ns.length
        var out: [[NSRange]] = Array(repeating: [], count: markers.count)
        var loc = 0
        while loc < total {
            let lineRange = ns.lineRange(for: NSRange(location: loc, length: 0))
            var bestIndex: Int?
            var bestLen = -1
            for (idx, m) in markers.enumerated() {
                guard m.enabled, !m.prefix.isEmpty else { continue }
                let pLen = m.prefix.utf16.count
                guard lineRange.length >= pLen else { continue }
                let prefixRange = NSRange(location: lineRange.location, length: pLen)
                if ns.substring(with: prefixRange) == m.prefix {
                    if pLen > bestLen {
                        bestLen = pLen
                        bestIndex = idx
                    }
                }
            }
            if let idx = bestIndex {
                out[idx].append(lineRange)
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
        let prefix1 = settings.marker1Prefix
        let enabled1 = settings.marker1Enabled && !prefix1.isEmpty
        let markerColor1 = settings.nsMarker1Color
        let colorHex1 = settings.marker1ColorHex

        let prefix2 = settings.marker2Prefix
        let enabled2 = settings.marker2Enabled && !prefix2.isEmpty
        let markerColor2 = settings.nsMarker2Color
        let colorHex2 = settings.marker2ColorHex

        let prefix3 = settings.marker3Prefix
        let enabled3 = settings.marker3Enabled && !prefix3.isEmpty
        let markerColor3 = settings.nsMarker3Color
        let colorHex3 = settings.marker3ColorHex

        let prefix4 = settings.marker4Prefix
        let enabled4 = settings.marker4Enabled && !prefix4.isEmpty
        let markerColor4 = settings.nsMarker4Color
        let colorHex4 = settings.marker4ColorHex

        let prefix5 = settings.marker5Prefix
        let enabled5 = settings.marker5Enabled && !prefix5.isEmpty
        let markerColor5 = settings.nsMarker5Color
        let colorHex5 = settings.marker5ColorHex

        let ns = textView.string as NSString
        let hasAnyEnabled = enabled1 || enabled2 || enabled3 || enabled4 || enabled5
        let classified: [[NSRange]]
        if hasAnyEnabled && ns.length > 0 {
            classified = classifiedMarkerRanges(
                in: textView.string,
                markers: [
                    (prefix: prefix1, enabled: enabled1),
                    (prefix: prefix2, enabled: enabled2),
                    (prefix: prefix3, enabled: enabled3),
                    (prefix: prefix4, enabled: enabled4),
                    (prefix: prefix5, enabled: enabled5),
                ]
            )
        } else {
            classified = [[], [], [], [], []]
        }
        let ranges1 = classified[0]
        let ranges2 = classified[1]
        let ranges3 = classified[2]
        let ranges4 = classified[3]
        let ranges5 = classified[4]

        let state = appliedState(for: textView)
        let unchanged = state.enabled1 == enabled1
            && state.enabled2 == enabled2
            && state.enabled3 == enabled3
            && state.enabled4 == enabled4
            && state.enabled5 == enabled5
            && state.prefix1 == prefix1
            && state.prefix2 == prefix2
            && state.prefix3 == prefix3
            && state.prefix4 == prefix4
            && state.prefix5 == prefix5
            && state.colorHex1 == colorHex1
            && state.colorHex2 == colorHex2
            && state.colorHex3 == colorHex3
            && state.colorHex4 == colorHex4
            && state.colorHex5 == colorHex5
            && state.documentLength == ns.length
            && state.ranges1 == ranges1
            && state.ranges2 == ranges2
            && state.ranges3 == ranges3
            && state.ranges4 == ranges4
            && state.ranges5 == ranges5
        if unchanged {
            updateTypingAttributes(for: textView)
            return
        }

        // Ranges to clear: the previously applied ranges (expanded to their full
        // current line boundaries so text shifted by an edit is still covered)
        // plus the new ranges (covers color/prefix changes in place).
        var clearRanges: [NSRange] = []
        for r in state.ranges1 + state.ranges2 + state.ranges3 + state.ranges4 + state.ranges5 {
            guard r.location < ns.length else { continue }
            let clamped = NSRange(location: r.location, length: min(r.length, ns.length - r.location))
            clearRanges.append(ns.lineRange(for: NSRange(location: clamped.location, length: max(clamped.length, 1))))
        }
        clearRanges.append(contentsOf: ranges1)
        clearRanges.append(contentsOf: ranges2)
        clearRanges.append(contentsOf: ranges3)
        clearRanges.append(contentsOf: ranges4)
        clearRanges.append(contentsOf: ranges5)

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
            if enabled1 {
                for r in ranges1 where r.length > 0 {
                    if let tRange = nsRangeToTextRange(r, in: tcm, docRange: docRange) {
                        tlm.addRenderingAttribute(.foregroundColor, value: markerColor1, for: tRange)
                    } else {
                        appliedOK = false
                    }
                }
            }
            if enabled2 {
                for r in ranges2 where r.length > 0 {
                    if let tRange = nsRangeToTextRange(r, in: tcm, docRange: docRange) {
                        tlm.addRenderingAttribute(.foregroundColor, value: markerColor2, for: tRange)
                    } else {
                        appliedOK = false
                    }
                }
            }
            if enabled3 {
                for r in ranges3 where r.length > 0 {
                    if let tRange = nsRangeToTextRange(r, in: tcm, docRange: docRange) {
                        tlm.addRenderingAttribute(.foregroundColor, value: markerColor3, for: tRange)
                    } else {
                        appliedOK = false
                    }
                }
            }
            if enabled4 {
                for r in ranges4 where r.length > 0 {
                    if let tRange = nsRangeToTextRange(r, in: tcm, docRange: docRange) {
                        tlm.addRenderingAttribute(.foregroundColor, value: markerColor4, for: tRange)
                    } else {
                        appliedOK = false
                    }
                }
            }
            if enabled5 {
                for r in ranges5 where r.length > 0 {
                    if let tRange = nsRangeToTextRange(r, in: tcm, docRange: docRange) {
                        tlm.addRenderingAttribute(.foregroundColor, value: markerColor5, for: tRange)
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
            if enabled1 {
                for r in ranges1 where r.length > 0 {
                    lm.addTemporaryAttribute(.foregroundColor, value: markerColor1, forCharacterRange: r)
                }
            }
            if enabled2 {
                for r in ranges2 where r.length > 0 {
                    lm.addTemporaryAttribute(.foregroundColor, value: markerColor2, forCharacterRange: r)
                }
            }
            if enabled3 {
                for r in ranges3 where r.length > 0 {
                    lm.addTemporaryAttribute(.foregroundColor, value: markerColor3, forCharacterRange: r)
                }
            }
            if enabled4 {
                for r in ranges4 where r.length > 0 {
                    lm.addTemporaryAttribute(.foregroundColor, value: markerColor4, forCharacterRange: r)
                }
            }
            if enabled5 {
                for r in ranges5 where r.length > 0 {
                    lm.addTemporaryAttribute(.foregroundColor, value: markerColor5, forCharacterRange: r)
                }
            }
        } else {
            // Last resort: directly mutate storage. Only reachable when neither
            // layout manager exists (e.g. headless/unit-test environments).
            fallbackStorageApply(to: textView, ranges1: ranges1, ranges2: ranges2, ranges3: ranges3, ranges4: ranges4, ranges5: ranges5)
        }

        let hasAnyRanges = !ranges1.isEmpty || !ranges2.isEmpty || !ranges3.isEmpty || !ranges4.isEmpty || !ranges5.isEmpty
        // If TextKit 2 conversion failed (layout not ready), don't cache the
        // state as successfully applied — schedule a retry and fall back to
        // storage so the highlight is at least visible.
        if !appliedOK, hasAnyRanges {
            fallbackStorageApply(to: textView, ranges1: ranges1, ranges2: ranges2, ranges3: ranges3, ranges4: ranges4, ranges5: ranges5)
            DispatchQueue.main.async {
                // Retry with layout now ready; the cached state is still stale
                // so the next apply will not hit the early-return.
                apply(to: textView)
            }
            // Don't update state yet — let the retry cache it.
            updateTypingAttributes(for: textView)
            return
        }

        state.ranges1 = ranges1
        state.ranges2 = ranges2
        state.ranges3 = ranges3
        state.ranges4 = ranges4
        state.ranges5 = ranges5
        state.enabled1 = enabled1
        state.enabled2 = enabled2
        state.enabled3 = enabled3
        state.enabled4 = enabled4
        state.enabled5 = enabled5
        state.prefix1 = prefix1
        state.prefix2 = prefix2
        state.prefix3 = prefix3
        state.prefix4 = prefix4
        state.prefix5 = prefix5
        state.colorHex1 = colorHex1
        state.colorHex2 = colorHex2
        state.colorHex3 = colorHex3
        state.colorHex4 = colorHex4
        state.colorHex5 = colorHex5
        state.documentLength = ns.length
        // Keep legacy fields in sync for any external inspection
        state.ranges = ranges1 + ranges2 + ranges3 + ranges4 + ranges5
        state.enabled = hasAnyEnabled
        state.prefix = prefix1
        state.colorHex = colorHex1
        updateTypingAttributes(for: textView)
    }

    // MARK: - Typing attributes

    /// When the caret is inside a marker line, new typing should be marker
    /// colored. Otherwise it should be the normal text color.
    private static func updateTypingAttributes(for textView: NSTextView) {
        let settings = AppSettings.shared
        let markers: [(prefix: String, enabled: Bool, color: NSColor)] = [
            (settings.marker1Prefix, settings.marker1Enabled && !settings.marker1Prefix.isEmpty, settings.nsMarker1Color),
            (settings.marker2Prefix, settings.marker2Enabled && !settings.marker2Prefix.isEmpty, settings.nsMarker2Color),
            (settings.marker3Prefix, settings.marker3Enabled && !settings.marker3Prefix.isEmpty, settings.nsMarker3Color),
            (settings.marker4Prefix, settings.marker4Enabled && !settings.marker4Prefix.isEmpty, settings.nsMarker4Color),
            (settings.marker5Prefix, settings.marker5Enabled && !settings.marker5Prefix.isEmpty, settings.nsMarker5Color),
        ]
        let hasAnyEnabled = markers.contains { $0.enabled }
        guard hasAnyEnabled else {
            // Restore default typing color.
            var attrs = textView.typingAttributes
            attrs[.foregroundColor] = AppSettings.shared.nsTextColor
            textView.typingAttributes = attrs
            return
        }
        let sel = textView.selectedRange()
        // Determine if caret line starts with any prefix (longest wins).
        let ns = textView.string as NSString
        guard sel.location != NSNotFound, ns.length >= 0 else { return }
        let clamped = min(sel.location, ns.length)
        let lineRange = ns.lineRange(for: NSRange(location: clamped, length: 0))
        var bestColor: NSColor?
        var bestLen = -1
        for m in markers where m.enabled {
            guard lineRange.length >= m.prefix.utf16.count else { continue }
            let r = NSRange(location: lineRange.location, length: m.prefix.utf16.count)
            if ns.substring(with: r) == m.prefix {
                let len = m.prefix.utf16.count
                if len > bestLen {
                    bestLen = len
                    bestColor = m.color
                }
            }
        }
        var attrs = textView.typingAttributes
        attrs[.foregroundColor] = bestColor ?? AppSettings.shared.nsTextColor
        textView.typingAttributes = attrs
    }

    // MARK: - Helpers

    private static func nsRangeToTextRange(_ nsRange: NSRange, in tcm: NSTextContentManager, docRange: NSTextRange) -> NSTextRange? {
        guard let start = tcm.location(docRange.location, offsetBy: nsRange.location),
              let end = tcm.location(start, offsetBy: nsRange.length) else { return nil }
        return NSTextRange(location: start, end: end)
    }

    private static func fallbackStorageApply(
        to textView: NSTextView,
        ranges1: [NSRange],
        ranges2: [NSRange],
        ranges3: [NSRange],
        ranges4: [NSRange],
        ranges5: [NSRange]
    ) {
        guard let storage = textView.textStorage else { return }
        let fullLen = (textView.string as NSString).length
        // Re-apply uniform base color then markers.
        let baseColor = AppSettings.shared.nsTextColor
        if fullLen > 0 {
            storage.addAttribute(.foregroundColor, value: baseColor, range: NSRange(location: 0, length: fullLen))
        }
        let settings = AppSettings.shared
        if settings.marker1Enabled && !settings.marker1Prefix.isEmpty {
            for r in ranges1 {
                storage.addAttribute(.foregroundColor, value: settings.nsMarker1Color, range: r)
            }
        }
        if settings.marker2Enabled && !settings.marker2Prefix.isEmpty {
            for r in ranges2 {
                storage.addAttribute(.foregroundColor, value: settings.nsMarker2Color, range: r)
            }
        }
        if settings.marker3Enabled && !settings.marker3Prefix.isEmpty {
            for r in ranges3 {
                storage.addAttribute(.foregroundColor, value: settings.nsMarker3Color, range: r)
            }
        }
        if settings.marker4Enabled && !settings.marker4Prefix.isEmpty {
            for r in ranges4 {
                storage.addAttribute(.foregroundColor, value: settings.nsMarker4Color, range: r)
            }
        }
        if settings.marker5Enabled && !settings.marker5Prefix.isEmpty {
            for r in ranges5 {
                storage.addAttribute(.foregroundColor, value: settings.nsMarker5Color, range: r)
            }
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
