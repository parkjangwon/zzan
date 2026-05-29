import SwiftUI

/// The menu shown when clicking the menu bar item.
struct MenuContent: View {
    @EnvironmentObject private var history: HistoryStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("New Translation  \(settings.hotKey.displayString)") {
            AppDelegate.shared?.showPanel()
        }

        if !history.items.isEmpty {
            Divider()
            Section("Recent") {
                ForEach(history.items) { item in
                    Button(item.menuTitle) {
                        history.recopy(item)
                    }
                }
            }
            Button("Clear History") {
                history.clear()
            }
        }

        Divider()

        Button("Settings…") {
            openSettings()
            AppDelegate.shared?.revealSettingsWindow()
        }

        Button("Quit zzan") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")

        Divider()

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build   = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        Text("zzan v\(version) (\(build))")
            .foregroundStyle(.secondary)
    }
}
