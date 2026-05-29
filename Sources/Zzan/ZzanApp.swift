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

    /// Activates the app and brings the SwiftUI Settings window to the front.
    ///
    /// The window itself is created by the SwiftUI `openSettings` environment
    /// action (called from the menu). For an accessory (menu-bar) app that
    /// window is created hidden, so we activate the app and order it front,
    /// retrying for a few frames in case it isn't instantiated yet.
    func revealSettingsWindow(attempt: Int = 0) {
        NSApp.activate(ignoringOtherApps: true)
        if let window = settingsWindow() {
            window.center()
            window.makeKeyAndOrderFront(nil)
            return
        }
        // Fallback: if SwiftUI's openSettings() didn't create the window (it
        // doesn't always propagate into a MenuBarExtra menu), trigger the
        // responder-chain action once.
        if attempt == 3 {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
        guard attempt < 12 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.revealSettingsWindow(attempt: attempt + 1)
        }
    }

    /// The Settings scene's window: neither the status-bar window nor our panel.
    private func settingsWindow() -> NSWindow? {
        NSApp.windows.first { window in
            String(describing: type(of: window)) != "NSStatusBarWindow" && !(window is KeyPanel)
        }
    }
}
