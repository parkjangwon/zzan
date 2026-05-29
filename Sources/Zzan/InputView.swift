import SwiftUI
import Translation

/// The contents of the floating panel: a multi-line field plus translation logic.
struct InputView: View {
    @ObservedObject var model: PanelModel
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var history: HistoryStore
    var onClose: () -> Void

    private enum Phase {
        case editing, translating, copied, failed
    }

    @State private var configuration: TranslationSession.Configuration?
    @State private var phase: Phase = .editing

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            KeyCaptureTextView(
                text: $model.text,
                focusNonce: model.focusNonce,
                onSubmit: submit,
                onCancel: onClose
            )
            .frame(minHeight: 64, maxHeight: .infinity)

            HStack(spacing: 8) {
                statusLabel
                Spacer()
                Text("⏎ translate   ⇧⏎ newline   ⎋ close")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.08))
        )
        .onChange(of: model.focusNonce) { _, _ in
            // Each time the panel reopens, start fresh.
            phase = .editing
        }
        .translationTask(configuration) { session in
            await runTranslation(using: session)
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch phase {
        case .editing:
            let name = SourceLanguageOption.all.first { $0.code == settings.sourceLanguageCode }?.name ?? "Auto-detect"
            Label("\(name) → English", systemImage: "globe")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .translating:
            Label("Translating…", systemImage: "ellipsis")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .copied:
            Label("Copied to clipboard", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .failed:
            Label("Translation failed", systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }

    private func submit() {
        guard phase != .translating else { return }
        let trimmed = model.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onClose()
            return
        }

        phase = .translating

        let target = Locale.Language(identifier: "en")
        let source: Locale.Language? = settings.sourceLanguageCode.isEmpty
            ? nil
            : Locale.Language(identifier: settings.sourceLanguageCode)

        // Reuse the task trigger, but refresh the language pair every submit so
        // Settings changes take effect without restarting the app.
        var nextConfiguration = configuration ?? TranslationSession.Configuration()
        nextConfiguration.source = source
        nextConfiguration.target = target
        nextConfiguration.invalidate()
        configuration = nextConfiguration
    }

    private func runTranslation(using session: TranslationSession) async {
        let input = model.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }

        do {
            let response = try await session.translate(input)
            let output = response.targetText

            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(output, forType: .string)

            history.add(source: input, translated: output)

            phase = .copied
            try? await Task.sleep(nanoseconds: 650_000_000)
            onClose()
        } catch {
            NSLog("Zzan: translation failed: \(error.localizedDescription)")
            phase = .failed
        }
    }
}
