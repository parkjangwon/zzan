import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
            }

            Section("Shortcut") {
                KeyRecorderField(combo: $settings.hotKey)
            }

            Section("Source language") {
                Picker("Translate from", selection: $settings.sourceLanguageCode) {
                    ForEach(SourceLanguageOption.all) { option in
                        Text(option.name).tag(option.code)
                    }
                }
                Text("Translation target is always English. Auto-detect works well for most languages.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Records a global shortcut by capturing the next key press while focused.
struct KeyRecorderField: View {
    @Binding var combo: KeyCombo

    @State private var isRecording = false
    @State private var errorMessage: String?

    var body: some View {
        HStack {
            Text("Shortcut")
            Spacer()
            if isRecording {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                    Text("Press keys…")
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 130, minHeight: 24)
                // Transparent capture view sits on top and owns the keyboard.
                .overlay(ShortcutRecorderView(onCapture: handle, onCancel: { isRecording = false }))
            } else {
                Button {
                    errorMessage = nil
                    isRecording = true
                } label: {
                    Text(combo.displayString)
                        .frame(minWidth: 110)
                        .monospaced()
                }
                .buttonStyle(.bordered)
            }
        }
        if let errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private func handle(_ candidate: KeyCombo) {
        errorMessage = nil // clear any stale message from a previous attempt
        if let reason = ShortcutValidator.reject(candidate) {
            errorMessage = reason
            return // keep recording so the user can try another combo
        }
        combo = candidate
        isRecording = false
    }
}

/// A focusable, otherwise-invisible NSView that captures the next key press
/// (including ⌘-based combos via `performKeyEquivalent`).
private struct ShortcutRecorderView: NSViewRepresentable {
    var onCapture: (KeyCombo) -> Void
    var onCancel: () -> Void

    func makeNSView(context: Context) -> RecorderNSView {
        let view = RecorderNSView()
        view.onCapture = onCapture
        view.onCancel = onCancel
        // The Settings window of a menu-bar (accessory) app may not be active;
        // force activation and grab first responder so key events arrive.
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            if let window = view.window {
                window.makeKeyAndOrderFront(nil)
                window.makeFirstResponder(view)
            }
        }
        return view
    }

    func updateNSView(_ view: RecorderNSView, context: Context) {
        view.onCapture = onCapture
        view.onCancel = onCancel
    }
}

private final class RecorderNSView: NSView {
    var onCapture: ((KeyCombo) -> Void)?
    var onCancel: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        capture(event)
    }

    // ⌘-based combinations are delivered as key equivalents, not keyDown.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        capture(event)
        return true
    }

    private func capture(_ event: NSEvent) {
        if Int(event.keyCode) == 53 { // Escape cancels recording
            onCancel?()
            return
        }
        let modifiers = event.modifierFlags
            .intersection(.deviceIndependentFlagsMask)
            .intersection([.command, .option, .control, .shift])
        onCapture?(KeyCombo(keyCode: UInt32(event.keyCode), modifiers: modifiers.rawValue))
    }
}
