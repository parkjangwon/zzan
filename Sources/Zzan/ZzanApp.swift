import SwiftUI

@main
struct ZzanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The only persistent UI is the menu bar item.
        MenuBarExtra("Zzan", systemImage: "character.bubble") {
            MenuContent()
                .environmentObject(HistoryStore.shared)
                .environmentObject(AppSettings.shared)
        }

        // Standard Settings scene, reachable via SettingsLink in the menu.
        Settings {
            SettingsView()
                .environmentObject(AppSettings.shared)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) weak var shared: AppDelegate?

    private var panelController: InputPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // Agent app: no Dock icon, lives in the menu bar only.
        NSApp.setActivationPolicy(.accessory)

        let controller = InputPanelController()
        panelController = controller

        HotKeyManager.shared.onHotKey = { [weak controller] in
            // The Carbon handler runs on the main thread; hop into MainActor isolation.
            MainActor.assumeIsolated {
                controller?.toggle()
            }
        }
        HotKeyManager.shared.apply(AppSettings.shared.hotKey)
    }

    /// Called from the menu bar's "New Translation" item.
    func showPanel() {
        panelController?.show()
    }

    /// Opens the SwiftUI Settings scene.
    ///
    /// For an accessory (menu-bar) app, the standard mechanism creates the
    /// Settings window but leaves it hidden, so we activate the app and then
    /// explicitly bring the freshly-created window to the front.
    func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        DispatchQueue.main.async { [weak self] in
            self?.bringSettingsWindowToFront()
        }
    }

    private func bringSettingsWindowToFront() {
        // The Settings scene is hosted in a SwiftUI window that is neither the
        // status-bar window nor our input panel.
        for window in NSApp.windows {
            if String(describing: type(of: window)) == "NSStatusBarWindow" { continue }
            if window is KeyPanel { continue }
            window.center()
            window.makeKeyAndOrderFront(nil)
            return
        }
    }
}
