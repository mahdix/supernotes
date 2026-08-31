import Foundation

extension Date {
    /// Locale-aware date display: "18:30 Feb 25, 2026" (en) or "2026年2月25日 18:30" (zh).
    var homeDisplayFormat: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: L10n.shared.resolvedLocaleIdentifier)
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Condensed ISO 8601 display: "2026-08-30 20:44".
    /// Used for the timestamps below the note header (modified / created).
    /// Locale-independent (en_US_POSIX) and rendered in the current time zone.
    var iso8601DisplayFormat: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: self)
    }
}
