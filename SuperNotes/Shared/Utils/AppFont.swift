import SwiftUI
import AppKit

extension AppSettings {
    /// Resolved family name for the chosen PostScript font, or nil when using the system font.
    /// Strips the leading dot that AppKit uses for private system fonts (e.g. ".SF NS").
    var resolvedFontFamily: String? {
        guard let name = editorFontName, let f = NSFont(name: name, size: 13) else { return nil }
        let family = f.familyName ?? f.fontName
        if family.hasPrefix(".") { return nil }
        return family
    }

    /// SwiftUI Font that uses the custom family when set, otherwise the system font for that style.
    /// Uses `relativeTo` so Dynamic Type scaling still works.
    func font(for style: Font.TextStyle) -> Font {
        guard let family = resolvedFontFamily else { return Font.system(style) }
        let size = pointSize(for: style)
        let base = Font.custom(family, size: size, relativeTo: style)
        // Headline in SF is semibold — preserve that weight when using a custom family.
        if style == .headline {
            return base.weight(.semibold)
        }
        return base
    }

    /// Custom-family font at an explicit point size. Falls back to system when no custom family.
    func font(size: CGFloat, weight: Font.Weight = .regular, relativeTo: Font.TextStyle = .body) -> Font {
        guard let family = resolvedFontFamily else {
            return Font.system(size: size, weight: weight, design: .default)
        }
        return Font.custom(family, size: size, relativeTo: relativeTo).weight(weight)
    }

    /// Monospaced variant — when a custom font is set, use it (so the user's choice is truly global);
    /// otherwise return the system monospaced font.
    func monospacedFont(for style: Font.TextStyle) -> Font {
        guard let family = resolvedFontFamily else {
            return Font.system(style, design: .monospaced)
        }
        return Font.custom(family, size: pointSize(for: style), relativeTo: style)
    }

    func monospacedFont(size: CGFloat, weight: Font.Weight = .regular, relativeTo: Font.TextStyle = .body) -> Font {
        guard let family = resolvedFontFamily else {
            return Font.system(size: size, weight: weight, design: .monospaced)
        }
        return Font.custom(family, size: size, relativeTo: relativeTo).weight(weight)
    }

    private func pointSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .subheadline: return 15
        case .body: return 17
        case .callout: return 16
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        @unknown default: return 13
        }
    }
}
