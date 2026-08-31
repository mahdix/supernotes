import SwiftUI

/// Reusable empty state placeholder with icon, title, and subtitle.
struct EmptyStateView: View {
    let icon: String
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: icon)
                .font(AppSettings.shared.font(size: 36))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(AppSettings.shared.font(for: .headline))
                .foregroundStyle(.secondary)
            if let subtitle {
                Text(subtitle)
                    .font(AppSettings.shared.font(for: .caption))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
