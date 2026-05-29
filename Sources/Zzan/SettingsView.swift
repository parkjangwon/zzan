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
    @State private var monitor: Any?
    @State private var errorMessage: String?

    var body: some View {
        HStack {
            Text("Shortcut")
            Spacer()
            Button(action: toggle) {
                Text(isRecording ? "Press keys…" : combo.displayString)
                    .frame(minWidth: 110)
                    .monospaced()
            }
            .buttonStyle(.bordered)
        }
        if let errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private func toggle() {
        isRecording ? stop() : start()
    }

    private func start() {
        isRecording = true
        errorMessage = nil
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event)
            return nil // consume the event so it doesn't trigger anything else
        }
    }

    private func handle(_ event: NSEvent) {
        if Int(event.keyCode) == 53 { // Escape cancels recording
            stop()
            return
        }

        let modifiers = event.modifierFlags
            .intersection(.deviceIndependentFlagsMask)
            .intersection([.command, .option, .control, .shift])

        let candidate = KeyCombo(keyCode: UInt32(event.keyCode), modifiers: modifiers.rawValue)

        if let reason = ShortcutValidator.reject(candidate) {
            errorMessage = reason
            return // keep recording so the user can try another combo
        }

        combo = candidate
        stop()
    }

    private func stop() {
        isRecording = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
