import AppKit
import SwiftUI

/// Borderless panel that can still become key so the text view receives input.
final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Shared state between the panel controller and the SwiftUI input view.
final class PanelModel: ObservableObject {
    @Published var text = ""
    /// Bumped each time the panel opens, to re-focus the text view.
    @Published var focusNonce = 0

    func reset() {
        text = ""
        focusNonce += 1
    }
}

/// Owns the floating input panel and shows/hides it.
@MainActor
final class InputPanelController {
    private let panel: KeyPanel
    private let model = PanelModel()
    private var isVisible = false

    init() {
        panel = KeyPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 168),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .moveToActiveSpace]

        let root = InputView(model: model, onClose: { [weak self] in self?.hide() })
            .environmentObject(AppSettings.shared)
            .environmentObject(HistoryStore.shared)

        let hosting = NSHostingView(rootView: root)
        hosting.frame = panel.contentLayoutRect
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting
    }

    func toggle() {
        isVisible ? hide() : show()
    }

    func show() {
        model.reset()
        positionOnActiveScreen()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        isVisible = true
    }

    func hide() {
        panel.orderOut(nil)
        isVisible = false
        // Return focus to whatever app the user was in, so they can paste.
        NSApp.hide(nil)
    }

    private func positionOnActiveScreen() {
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) }
            ?? NSScreen.main
        guard let frame = screen?.visibleFrame else { return }
        let size = panel.frame.size
        let origin = NSPoint(
            x: frame.midX - size.width / 2,
            y: frame.midY - size.height / 2 + 80  // sit slightly above center
        )
        panel.setFrameOrigin(origin)
    }
}
