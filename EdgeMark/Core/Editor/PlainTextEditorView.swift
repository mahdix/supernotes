import AppKit
import SwiftUI

// MARK: - Notification names for the editor find bus

extension Notification.Name {
    static let editorFindScrollToRange = Notification.Name("io.github.ender-wang.EdgeMark.editor.findScrollToRange")
    static let editorFindClearHighlights = Notification.Name("io.github.ender-wang.EdgeMark.editor.findClearHighlights")
}

// MARK: - PlainTextEditorView

/// The app's note editor. Shows note text verbatim with no markdown
/// preprocessing, no header stripping, and uniform styling. Handles the
/// save-debounce, find-bar, and navigation behaviour so the surrounding
/// screen can swap implementations without changing its own logic.
struct PlainTextEditorView: View {
    let noteID: UUID
    let initialContent: String
    let onContentChanged: (UUID, String) -> Void
    @Binding var pendingReload: String?
    var showFindBar: Binding<Bool> = .constant(false)
    var onNavigateNext: (() -> Void)?
    var onNavigatePrevious: (() -> Void)?

    @State private var text: String
    @State private var saveDebouncer = Debouncer(delay: 1.0)
    @State private var noteNavMonitor: Any?
    @State private var stableNoteID: UUID

    init(
        noteID: UUID,
        noteTitle: String,
        noteFolder: String,
        initialContent: String,
        onContentChanged: @escaping (UUID, String) -> Void,
        pendingReload: Binding<String?> = .constant(nil),
        showFindBar: Binding<Bool> = .constant(false),
        onNavigateNext: (() -> Void)? = nil,
        onNavigatePrevious: (() -> Void)? = nil,
    ) {
        self.noteID = noteID
        self.initialContent = initialContent
        self.onContentChanged = onContentChanged
        _pendingReload = pendingReload
        self.showFindBar = showFindBar
        self.onNavigateNext = onNavigateNext
        self.onNavigatePrevious = onNavigatePrevious
        // Plaintext: show the full content verbatim, including any heading line.
        _text = State(initialValue: initialContent)
        _stableNoteID = State(initialValue: noteID)
    }

    var body: some View {
        let appSettings = AppSettings.shared
        let fontName = Self.resolvedFontFamily(from: appSettings.editorFontName) ?? "SF Pro"
        let fontSize = CGFloat(appSettings.editorFontSize)
        let textColor = appSettings.nsTextColor

        ZStack(alignment: .bottom) {
            PlainTextViewWrapper(
                text: $text,
                fontName: fontName,
                fontSize: fontSize,
                isEditable: true,
                textColor: textColor,
                spellCheckingEnabled: appSettings.spellCheckingEnabled,
                grammarCheckingEnabled: appSettings.grammarCheckingEnabled,
                automaticSpellingCorrectionEnabled: appSettings.automaticSpellingCorrectionEnabled,
            )
            .id(appSettings.textColorHex)
            .onChange(of: text) { _, newText in
                let snapshot = stableNoteID
                saveDebouncer.call { [onContentChanged] in
                    onContentChanged(snapshot, newText)
                }
            }
            .onChange(of: pendingReload) { _, newContent in
                guard let newContent else { return }
                saveDebouncer.cancel()
                text = newContent
                pendingReload = nil
            }

            if showFindBar.wrappedValue {
                FindBarView(isPresented: showFindBar, editorText: $text)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: showFindBar.wrappedValue)
        .onAppear {
            noteNavMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
                let s = ShortcutSettings.shared
                if s.previousNoteShortcut?.matches(event) == true {
                    onNavigatePrevious?(); return nil
                }
                if s.nextNoteShortcut?.matches(event) == true {
                    onNavigateNext?(); return nil
                }
                return event
            }
        }
        .onDisappear {
            let capturedID = stableNoteID
            saveDebouncer.cancel()
            onContentChanged(capturedID, text)
            if let m = noteNavMonitor {
                NSEvent.removeMonitor(m); noteNavMonitor = nil
            }
        }
    }

    private static func resolvedFontFamily(from postscriptName: String?) -> String? {
        guard let name = postscriptName, let font = NSFont(name: name, size: 16) else { return nil }
        return font.familyName
    }
}

// MARK: - PlainTextViewWrapper (NSTextView)

struct PlainTextViewWrapper: NSViewRepresentable {
    @Binding var text: String
    var fontName: String
    var fontSize: CGFloat
    var isEditable: Bool = true
    var textColor: NSColor = .white
    var spellCheckingEnabled: Bool = true
    var grammarCheckingEnabled: Bool = false
    var automaticSpellingCorrectionEnabled: Bool = false

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainerInset = NSSize(width: 10, height: 12)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.delegate = context.coordinator
        textView.font = NSFont(name: fontName, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        textView.textColor = textColor
        textView.insertionPointColor = textColor
        textView.typingAttributes[.foregroundColor] = textColor
        textView.isContinuousSpellCheckingEnabled = spellCheckingEnabled
        textView.isGrammarCheckingEnabled = grammarCheckingEnabled
        textView.isAutomaticSpellingCorrectionEnabled = automaticSpellingCorrectionEnabled
        textView.string = text
        // Apply color to the newly set string (plain NSTextView respects textColor, but ensure storage has attribute)
        if (text as NSString).length > 0, let storage = textView.textStorage {
            storage.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: (text as NSString).length))
            if let font = textView.font {
                storage.addAttribute(.font, value: font, range: NSRange(location: 0, length: (text as NSString).length))
            }
        }
        // Enable find bar support (⌘F handled at EditorScreen level, but allow standard find panel)
        textView.isAutomaticTextCompletionEnabled = false

        scrollView.documentView = textView

        // Observe find-bus notifications for highlight/scroll
        context.coordinator.textView = textView
        context.coordinator.setupFindObservers()
        context.coordinator.setupMarkerObserver()
        // Apply the marker overlay immediately (fallback to storage if layout
        // not ready) and again after layout so TextKit 2 rendering attributes
        // are guaranteed to land. Both are incremental/cheap.
        MarkerHighlighter.apply(to: textView)
        DispatchQueue.main.async {
            MarkerHighlighter.apply(to: textView)
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }

        // Sync text without moving cursor if user is editing
        var didSyncText = false
        if textView.string != text {
            let selected = textView.selectedRange()
            textView.string = text
            // Clamp selection if text shrunk
            let maxLoc = (text as NSString).length
            let clampedLoc = min(selected.location, maxLoc)
            let clampedLen = min(selected.length, maxLoc - clampedLoc)
            textView.setSelectedRange(NSRange(location: clampedLoc, length: clampedLen))
            didSyncText = true
        }

        let desiredFont = NSFont(name: fontName, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        if textView.font != desiredFont {
            textView.font = desiredFont
        }

        if textView.isEditable != isEditable {
            textView.isEditable = isEditable
        }
        if textView.isContinuousSpellCheckingEnabled != spellCheckingEnabled {
            textView.isContinuousSpellCheckingEnabled = spellCheckingEnabled
        }
        if textView.isGrammarCheckingEnabled != grammarCheckingEnabled {
            textView.isGrammarCheckingEnabled = grammarCheckingEnabled
        }
        if textView.isAutomaticSpellingCorrectionEnabled != automaticSpellingCorrectionEnabled {
            textView.isAutomaticSpellingCorrectionEnabled = automaticSpellingCorrectionEnabled
        }
        let needsColorUpdate = didSyncText || textView.textColor != textColor
        if needsColorUpdate {
            textView.textColor = textColor
            textView.insertionPointColor = textColor
            textView.typingAttributes[.foregroundColor] = textColor
            if (textView.string as NSString).length > 0, let storage = textView.textStorage {
                storage.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: (textView.string as NSString).length))
                if let font = textView.font {
                    storage.addAttribute(.font, value: font, range: NSRange(location: 0, length: (textView.string as NSString).length))
                }
            }
        }
        // Re-apply marker overlay whenever the view updates (covers settings changes and text sync).
        // Apply sync for the fast-path (typingAttributes) and async after layout for rendering attributes.
        MarkerHighlighter.apply(to: textView)
        DispatchQueue.main.async {
            MarkerHighlighter.apply(to: textView)
        }

        context.coordinator.text = $text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        weak var textView: NSTextView?
        private var findObservers: [Any] = []
        private var markerObserver: Any?

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            // Avoid feedback loop: only update binding if different
            if text.wrappedValue != tv.string {
                text.wrappedValue = tv.string
            }
            // Apply synchronously so the marker color lands in the same display
            // frame as the typed text. apply() is incremental — cheap.
            MarkerHighlighter.apply(to: tv)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            // Update typing color when caret moves between marker / non-marker lines.
            // Synchronous: the fast path in apply() makes this near-free.
            MarkerHighlighter.apply(to: tv)
        }

        func setupFindObservers() {
            // Clear previous if any
            for obs in findObservers {
                NotificationCenter.default.removeObserver(obs)
            }
            findObservers.removeAll()

            let center = NotificationCenter.default
            let scrollObs = center.addObserver(
                forName: .editorFindScrollToRange,
                object: nil,
                queue: .main,
            ) { [weak self] note in
                guard let self, let tv = self.textView,
                      let range = note.userInfo?["range"] as? NSRange
                else { return }
                tv.scrollRangeToVisible(range)
                tv.setSelectedRange(range)
                tv.showFindIndicator(for: range)
                // Highlight all ranges with temporary background
                if let allRanges = note.userInfo?["allRanges"] as? [NSRange] {
                    // Clear previous temp attributes
                    tv.layoutManager?.removeTemporaryAttribute(.backgroundColor, forCharacterRange: NSRange(location: 0, length: (tv.string as NSString).length))
                    for r in allRanges {
                        tv.layoutManager?.addTemporaryAttribute(.backgroundColor, value: NSColor.findHighlightColor, forCharacterRange: r)
                    }
                    // Current match gets a stronger color
                    tv.layoutManager?.addTemporaryAttribute(.backgroundColor, value: NSColor.selectedTextBackgroundColor, forCharacterRange: range)
                }
            }
            let clearObs = center.addObserver(
                forName: .editorFindClearHighlights,
                object: nil,
                queue: .main,
            ) { [weak self] _ in
                guard let self, let tv = self.textView else { return }
                tv.layoutManager?.removeTemporaryAttribute(.backgroundColor, forCharacterRange: NSRange(location: 0, length: (tv.string as NSString).length))
            }
            findObservers = [scrollObs, clearObs]
        }

        func setupMarkerObserver() {
            if markerObserver != nil { return }
            markerObserver = NotificationCenter.default.addObserver(forName: .markerSettingsChanged, object: nil, queue: .main) { [weak self] _ in
                guard let tv = self?.textView else { return }
                // apply() diffs against the last-applied overlay, so enable/prefix/color
                // changes repaint only the affected lines — no storage rewrite, no remount.
                MarkerHighlighter.apply(to: tv)
            }
        }

        deinit {
            for obs in findObservers {
                NotificationCenter.default.removeObserver(obs)
            }
            if let o = markerObserver {
                NotificationCenter.default.removeObserver(o)
            }
        }
    }
}

// MARK: - PlainTextReadOnlyView
/// Read-only plain-text viewer. Used for trashed-note previews and peek windows.
struct PlainTextReadOnlyView: View {
    let content: String

    var body: some View {
        let appSettings = AppSettings.shared
        let fontName = appSettings.resolvedFontFamily ?? "SF Pro"
        let fontSize = CGFloat(appSettings.editorFontSize)
        PlainTextViewWrapper(
            text: .constant(content),
            fontName: fontName,
            fontSize: fontSize,
            isEditable: false,
            textColor: appSettings.nsTextColor,
        )
        .id(appSettings.textColorHex)
    }
}
