import SwiftUI

@main
struct SuperNotesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(L10n.shared)
                .environment(AppSettings.shared)
        }
    }
}
