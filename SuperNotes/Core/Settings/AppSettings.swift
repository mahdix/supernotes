import AppKit
import Foundation
import OSLog
import ServiceManagement
import SwiftUI

@Observable
final class AppSettings {
    static let shared = AppSettings()

    // MARK: - Sort

    enum SortBy: String, CaseIterable {
        case name = "Name"
        case dateModified = "Date Modified"
        case dateCreated = "Date Created"
    }

    var sortBy: SortBy = .dateModified {
        didSet { UserDefaults.standard.set(sortBy.rawValue, forKey: "sortBy") }
    }

    var sortAscending: Bool = false {
        didSet { UserDefaults.standard.set(sortAscending, forKey: "sortAscending") }
    }

    // MARK: - Panel color

    /// Hex string ("#RRGGBB") for the panel background tint. nil = no tint (system material only).
    var panelColorHex: String? {
        didSet {
            if let hex = panelColorHex {
                UserDefaults.standard.set(hex, forKey: "panelColorHex")
            } else {
                UserDefaults.standard.removeObject(forKey: "panelColorHex")
            }
        }
    }

    /// AppKit color resolved from `panelColorHex`.
    var panelColor: NSColor? {
        guard let hex = panelColorHex else { return nil }
        return NSColor(hex: hex)
    }

    /// SwiftUI Color resolved from `panelColorHex`.
    var panelSwiftUIColor: Color? {
        guard let hex = panelColorHex else { return nil }
        return Color(hex: hex)
    }

    /// PostScript font name (e.g. "HelveticaNeue", "SFMono-Regular"). nil = system font.
    var editorFontName: String? {
        didSet {
            if let name = editorFontName {
                UserDefaults.standard.set(name, forKey: "editorFontName")
            } else {
                UserDefaults.standard.removeObject(forKey: "editorFontName")
            }
            NotificationCenter.default.post(name: .editorFontChanged, object: nil)
        }
    }

    /// Editor body font size in pixels. Headings scale relative to this via em units.
    var editorFontSize: Double = 16 {
        didSet {
            UserDefaults.standard.set(editorFontSize, forKey: "editorFontSize")
            NotificationCenter.default.post(name: .editorFontChanged, object: nil)
        }
    }



    // MARK: - Appearance, updates, launch

    enum AppearanceMode: String {
        case system
        case light
        case dark
    }

    /// Appearance mode: system, light, or dark.
    var appearanceMode: AppearanceMode = .system {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
            applyAppearance()
        }
    }

    /// Whether to automatically check for updates on launch (24h throttle).
    var autoCheckUpdates: Bool = true {
        didSet { UserDefaults.standard.set(autoCheckUpdates, forKey: "autoCheckUpdates") }
    }

    /// Whether the app launches at login.
    var launchAtLogin: Bool = false {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLoginItem()
        }
    }

    func applyAppearance() {
        switch appearanceMode {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    private func updateLoginItem() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            let msg = error.localizedDescription
            Log.app.error("Failed to update login item: \(msg)")
        }
    }



    // MARK: - Spell checking

    /// Mirrors `SpellCheckingPolicy.continuousSpellChecking`.
    /// Default on — matches Notes / TextEdit behavior.
    var spellCheckingEnabled: Bool = true {
        didSet { UserDefaults.standard.set(spellCheckingEnabled, forKey: "spellCheckingEnabled") }
    }

    /// Mirrors `SpellCheckingPolicy.grammarChecking`.
    /// Default off — opt-in for writing-focused workflows.
    var grammarCheckingEnabled: Bool = false {
        didSet { UserDefaults.standard.set(grammarCheckingEnabled, forKey: "grammarCheckingEnabled") }
    }

    /// Mirrors `SpellCheckingPolicy.automaticSpellingCorrection`.
    /// Default off — autocorrect is disruptive in code-heavy notes.
    var automaticSpellingCorrectionEnabled: Bool = false {
        didSet { UserDefaults.standard.set(automaticSpellingCorrectionEnabled, forKey: "automaticSpellingCorrectionEnabled") }
    }

    // MARK: - Text color

    /// Hex string ("#RRGGBB") for the editor/reader text color. Default white as requested.
    /// Backed by UserDefaults key "textColorHex".
    var textColorHex: String = "#FFFFFF" {
        didSet { UserDefaults.standard.set(textColorHex, forKey: "textColorHex") }
    }

    /// SwiftUI Color resolved from `textColorHex`.
    var textColor: Color {
        Color(hex: textColorHex) ?? .white
    }

    /// AppKit color resolved from `textColorHex`.
    var nsTextColor: NSColor {
        NSColor(hex: textColorHex) ?? .white
    }

    // MARK: - Marker 1

    /// Whether the Marker 1 line highlighting is enabled. Disabled by default.
    var marker1Enabled: Bool = false {
        didSet {
            UserDefaults.standard.set(marker1Enabled, forKey: "marker1Enabled")
            NotificationCenter.default.post(name: .markerSettingsChanged, object: nil)
        }
    }

    /// The prefix that identifies a Marker 1 line. Default "!". Empty means no line matches.
    var marker1Prefix: String = "!" {
        didSet {
            UserDefaults.standard.set(marker1Prefix, forKey: "marker1Prefix")
            NotificationCenter.default.post(name: .markerSettingsChanged, object: nil)
        }
    }

    /// Hex string ("#RRGGBB") for the Marker 1 text color.
    var marker1ColorHex: String = "#FF3B30" {
        didSet {
            UserDefaults.standard.set(marker1ColorHex, forKey: "marker1ColorHex")
            NotificationCenter.default.post(name: .markerSettingsChanged, object: nil)
        }
    }

    /// SwiftUI Color resolved from `marker1ColorHex`.
    var marker1Color: Color {
        Color(hex: marker1ColorHex) ?? .red
    }

    /// AppKit color resolved from `marker1ColorHex`.
    var nsMarker1Color: NSColor {
        NSColor(hex: marker1ColorHex) ?? .systemRed
    }

    // MARK: - Marker 2

    /// Whether the Marker 2 line highlighting is enabled. Disabled by default.
    var marker2Enabled: Bool = false {
        didSet {
            UserDefaults.standard.set(marker2Enabled, forKey: "marker2Enabled")
            NotificationCenter.default.post(name: .markerSettingsChanged, object: nil)
        }
    }

    /// The prefix that identifies a Marker 2 line. Default "?". Empty means no line matches.
    var marker2Prefix: String = "?" {
        didSet {
            UserDefaults.standard.set(marker2Prefix, forKey: "marker2Prefix")
            NotificationCenter.default.post(name: .markerSettingsChanged, object: nil)
        }
    }

    /// Hex string ("#RRGGBB") for the Marker 2 text color.
    var marker2ColorHex: String = "#FFCC00" {
        didSet {
            UserDefaults.standard.set(marker2ColorHex, forKey: "marker2ColorHex")
            NotificationCenter.default.post(name: .markerSettingsChanged, object: nil)
        }
    }

    /// SwiftUI Color resolved from `marker2ColorHex`.
    var marker2Color: Color {
        Color(hex: marker2ColorHex) ?? .yellow
    }

    /// AppKit color resolved from `marker2ColorHex`.
    var nsMarker2Color: NSColor {
        NSColor(hex: marker2ColorHex) ?? .systemYellow
    }

    // MARK: - Marker 3

    /// Whether the Marker 3 line highlighting is enabled. Disabled by default.
    var marker3Enabled: Bool = false {
        didSet {
            UserDefaults.standard.set(marker3Enabled, forKey: "marker3Enabled")
            NotificationCenter.default.post(name: .markerSettingsChanged, object: nil)
        }
    }

    /// The prefix that identifies a Marker 3 line. Default "~". Empty means no line matches.
    var marker3Prefix: String = "~" {
        didSet {
            UserDefaults.standard.set(marker3Prefix, forKey: "marker3Prefix")
            NotificationCenter.default.post(name: .markerSettingsChanged, object: nil)
        }
    }

    /// Hex string ("#RRGGBB") for the Marker 3 text color.
    var marker3ColorHex: String = "#007AFF" {
        didSet {
            UserDefaults.standard.set(marker3ColorHex, forKey: "marker3ColorHex")
            NotificationCenter.default.post(name: .markerSettingsChanged, object: nil)
        }
    }

    /// SwiftUI Color resolved from `marker3ColorHex`.
    var marker3Color: Color {
        Color(hex: marker3ColorHex) ?? .blue
    }

    /// AppKit color resolved from `marker3ColorHex`.
    var nsMarker3Color: NSColor {
        NSColor(hex: marker3ColorHex) ?? .systemBlue
    }

    // MARK: - Marker 4

    /// Whether the Marker 4 line highlighting is enabled. Disabled by default.
    var marker4Enabled: Bool = false {
        didSet {
            UserDefaults.standard.set(marker4Enabled, forKey: "marker4Enabled")
            NotificationCenter.default.post(name: .markerSettingsChanged, object: nil)
        }
    }

    /// The prefix that identifies a Marker 4 line. Default "+". Empty means no line matches.
    var marker4Prefix: String = "+" {
        didSet {
            UserDefaults.standard.set(marker4Prefix, forKey: "marker4Prefix")
            NotificationCenter.default.post(name: .markerSettingsChanged, object: nil)
        }
    }

    /// Hex string ("#RRGGBB") for the Marker 4 text color.
    var marker4ColorHex: String = "#34C759" {
        didSet {
            UserDefaults.standard.set(marker4ColorHex, forKey: "marker4ColorHex")
            NotificationCenter.default.post(name: .markerSettingsChanged, object: nil)
        }
    }

    /// SwiftUI Color resolved from `marker4ColorHex`.
    var marker4Color: Color {
        Color(hex: marker4ColorHex) ?? .green
    }

    /// AppKit color resolved from `marker4ColorHex`.
    var nsMarker4Color: NSColor {
        NSColor(hex: marker4ColorHex) ?? .systemGreen
    }

    // MARK: - Marker 5

    /// Whether the Marker 5 line highlighting is enabled. Disabled by default.
    var marker5Enabled: Bool = false {
        didSet {
            UserDefaults.standard.set(marker5Enabled, forKey: "marker5Enabled")
            NotificationCenter.default.post(name: .markerSettingsChanged, object: nil)
        }
    }

    /// The prefix that identifies a Marker 5 line. Default "%". Empty means no line matches.
    var marker5Prefix: String = "%" {
        didSet {
            UserDefaults.standard.set(marker5Prefix, forKey: "marker5Prefix")
            NotificationCenter.default.post(name: .markerSettingsChanged, object: nil)
        }
    }

    /// Hex string ("#RRGGBB") for the Marker 5 text color.
    var marker5ColorHex: String = "#AF52DE" {
        didSet {
            UserDefaults.standard.set(marker5ColorHex, forKey: "marker5ColorHex")
            NotificationCenter.default.post(name: .markerSettingsChanged, object: nil)
        }
    }

    /// SwiftUI Color resolved from `marker5ColorHex`.
    var marker5Color: Color {
        Color(hex: marker5ColorHex) ?? .purple
    }

    /// AppKit color resolved from `marker5ColorHex`.
    var nsMarker5Color: NSColor {
        NSColor(hex: marker5ColorHex) ?? .systemPurple
    }

    // MARK: - Hover-to-peek

    /// Discrete dwell options for hover-to-preview. Space-to-preview is
    /// always instant (no delay) regardless of this setting.
    enum HoverPeekDelay: String, CaseIterable {
        case fast
        case normal
        case slow
        case verySlow

        var seconds: TimeInterval {
            switch self {
            case .fast: 0.15
            case .normal: 0.35
            case .slow: 0.7
            case .verySlow: 1.2
            }
        }
    }

    /// Whether hovering over a note/folder row shows a floating read-only
    /// preview on the opposite side of the panel. Default on — opt-out via
    /// the General settings tab.
    var hoverPeekEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(hoverPeekEnabled, forKey: "hoverPeekEnabled")
            NotificationCenter.default.post(name: .previewSettingsChanged, object: nil)
        }
    }

    /// Whether pressing Space on a single selected row shows the preview
    /// instantly (Quick Look behavior). Independent from hover-to-peek.
    /// Default on.
    var spaceToPreviewEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(spaceToPreviewEnabled, forKey: "spaceToPreviewEnabled")
            NotificationCenter.default.post(name: .previewSettingsChanged, object: nil)
        }
    }

    /// Hover dwell tier before the preview appears. Does not affect
    /// Space-to-preview, which is always instant.
    var hoverPeekDelay: HoverPeekDelay = .normal {
        didSet {
            UserDefaults.standard.set(hoverPeekDelay.rawValue, forKey: "hoverPeekDelay")
        }
    }

    /// Custom labels for color tags. Missing entries fall back to `TagColor.defaultLabel`.
    /// Persisted as a single UserDefaults dictionary keyed by raw color name.
    var tagLabels: [TagColor: String] = [:] {
        didSet {
            let raw = tagLabels.reduce(into: [String: String]()) { $0[$1.key.rawValue] = $1.value }
            UserDefaults.standard.set(raw, forKey: "tagLabels")
        }
    }

    /// Display label for a tag — user override if set, otherwise the default name.
    func label(for tag: TagColor) -> String {
        if let custom = tagLabels[tag], !custom.isEmpty {
            return custom
        }
        return tag.defaultLabel
    }

    /// Resolved NSFont for the editor — falls back to system font when no custom name is set.
    var editorFont: NSFont {
        let size = CGFloat(editorFontSize)
        if let name = editorFontName, let f = NSFont(name: name, size: size) {
            return f
        }
        return .systemFont(ofSize: size)
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: "sortBy"),
           let value = SortBy(rawValue: raw)
        {
            sortBy = value
        }
        sortAscending = UserDefaults.standard.bool(forKey: "sortAscending")
        if let raw = UserDefaults.standard.string(forKey: "panelColorHex"), !raw.isEmpty {
            panelColorHex = raw
        }
        // If the saved font is no longer installed (e.g. user uninstalled it),
        // drop it silently so the editor falls back to the system font.
        if let saved = UserDefaults.standard.string(forKey: "editorFontName"),
           NSFont(name: saved, size: 13) != nil
        {
            editorFontName = saved
        } else {
            UserDefaults.standard.removeObject(forKey: "editorFontName")
        }
        let savedSize = UserDefaults.standard.object(forKey: "editorFontSize") as? Double
        editorFontSize = savedSize ?? 16
        // Appearance, updates, launch (moved from ShortcutSettings)
        if let raw = UserDefaults.standard.string(forKey: "appearanceMode"),
           let mode = AppearanceMode(rawValue: raw)
        {
            appearanceMode = mode
        }
        autoCheckUpdates = UserDefaults.standard.object(forKey: "autoCheckUpdates") as? Bool ?? true
        launchAtLogin = UserDefaults.standard.object(forKey: "launchAtLogin") as? Bool ?? false
        if let raw = UserDefaults.standard.object(forKey: "spellCheckingEnabled") as? Bool {
            spellCheckingEnabled = raw
        }
        if let raw = UserDefaults.standard.object(forKey: "grammarCheckingEnabled") as? Bool {
            grammarCheckingEnabled = raw
        }
        if let raw = UserDefaults.standard.object(forKey: "automaticSpellingCorrectionEnabled") as? Bool {
            automaticSpellingCorrectionEnabled = raw
        }
        if let raw = UserDefaults.standard.string(forKey: "textColorHex"), !raw.isEmpty {
            textColorHex = raw
        }
        if let raw = UserDefaults.standard.object(forKey: "marker1Enabled") as? Bool {
            marker1Enabled = raw
        }
        if let raw = UserDefaults.standard.string(forKey: "marker1Prefix") {
            // Empty string is valid (means disabled matching); only fall back when key missing.
            marker1Prefix = raw
        }
        if let raw = UserDefaults.standard.string(forKey: "marker1ColorHex"), !raw.isEmpty {
            marker1ColorHex = raw
        }
        if let raw = UserDefaults.standard.object(forKey: "marker2Enabled") as? Bool {
            marker2Enabled = raw
        }
        if let raw = UserDefaults.standard.string(forKey: "marker2Prefix") {
            marker2Prefix = raw
        }
        if let raw = UserDefaults.standard.string(forKey: "marker2ColorHex"), !raw.isEmpty {
            marker2ColorHex = raw
        }
        if let raw = UserDefaults.standard.object(forKey: "marker3Enabled") as? Bool {
            marker3Enabled = raw
        }
        if let raw = UserDefaults.standard.string(forKey: "marker3Prefix") {
            marker3Prefix = raw
        }
        if let raw = UserDefaults.standard.string(forKey: "marker3ColorHex"), !raw.isEmpty {
            marker3ColorHex = raw
        }
        if let raw = UserDefaults.standard.object(forKey: "marker4Enabled") as? Bool {
            marker4Enabled = raw
        }
        if let raw = UserDefaults.standard.string(forKey: "marker4Prefix") {
            marker4Prefix = raw
        }
        if let raw = UserDefaults.standard.string(forKey: "marker4ColorHex"), !raw.isEmpty {
            marker4ColorHex = raw
        }
        if let raw = UserDefaults.standard.object(forKey: "marker5Enabled") as? Bool {
            marker5Enabled = raw
        }
        if let raw = UserDefaults.standard.string(forKey: "marker5Prefix") {
            marker5Prefix = raw
        }
        if let raw = UserDefaults.standard.string(forKey: "marker5ColorHex"), !raw.isEmpty {
            marker5ColorHex = raw
        }
        if let raw = UserDefaults.standard.object(forKey: "hoverPeekEnabled") as? Bool {
            hoverPeekEnabled = raw
        }
        if let raw = UserDefaults.standard.object(forKey: "spaceToPreviewEnabled") as? Bool {
            spaceToPreviewEnabled = raw
        }
        if let raw = UserDefaults.standard.string(forKey: "hoverPeekDelay"),
           let value = HoverPeekDelay(rawValue: raw)
        {
            hoverPeekDelay = value
        }
        if let raw = UserDefaults.standard.dictionary(forKey: "tagLabels") as? [String: String] {
            tagLabels = raw.reduce(into: [TagColor: String]()) { result, kv in
                if let color = TagColor(rawValue: kv.key) {
                    result[color] = kv.value
                }
            }
        }
    }

    /// Folder date to display based on the current sort setting.
    func folderDate(for folder: Folder) -> Date? {
        switch sortBy {
        case .name: folder.latestModifiedAt
        case .dateModified: folder.latestModifiedAt
        case .dateCreated: folder.earliestCreatedAt
        }
    }
}

extension AppSettings.SortBy {
    func displayName(_ l10n: L10n) -> String {
        switch self {
        case .name: l10n["sort.name"]
        case .dateModified: l10n["sort.dateModified"]
        case .dateCreated: l10n["sort.dateCreated"]
        }
    }
}

extension Notification.Name {
    static let editorFontChanged = Notification.Name("editorFontChanged")
    static let previewSettingsChanged = Notification.Name("previewSettingsChanged")
    static let markerSettingsChanged = Notification.Name("markerSettingsChanged")
}

extension AppSettings.HoverPeekDelay {
    func displayName(_ l10n: L10n) -> String {
        switch self {
        case .fast: l10n["settings.hoverDelay.fast"]
        case .normal: l10n["settings.hoverDelay.normal"]
        case .slow: l10n["settings.hoverDelay.slow"]
        case .verySlow: l10n["settings.hoverDelay.verySlow"]
        }
    }
}



// MARK: - Hex color helpers

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >> 8) & 0xFF) / 255.0
        let b = Double(v & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }

    var hexString: String {
        guard let comps = NSColor(self).usingColorSpace(.deviceRGB) else { return "#FFFFFF" }
        let r = Int(round(comps.redComponent * 255))
        let g = Int(round(comps.greenComponent * 255))
        let b = Int(round(comps.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

extension NSColor {
    convenience init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        let r = CGFloat((v >> 16) & 0xFF) / 255.0
        let g = CGFloat((v >> 8) & 0xFF) / 255.0
        let b = CGFloat(v & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
