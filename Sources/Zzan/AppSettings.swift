import SwiftUI
import ServiceManagement

/// User-facing settings, persisted to UserDefaults. All UI strings are English.
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Key {
        static let hotKey = "hotKey"
        static let sourceLanguage = "sourceLanguageCode"
    }

    /// Global shortcut that opens the input panel. Re-registers on change.
    @Published var hotKey: KeyCombo {
        didSet {
            persistHotKey()
            HotKeyManager.shared.apply(hotKey)
        }
    }

    /// BCP-47 language code to translate *from*. Empty string = auto-detect.
    @Published var sourceLanguageCode: String {
        didSet {
            UserDefaults.standard.set(sourceLanguageCode, forKey: Key.sourceLanguage)
        }
    }

    /// Whether the app launches automatically at login.
    @Published var launchAtLogin: Bool {
        didSet { updateLoginItem() }
    }

    private init() {
        // Property observers don't fire during init, so no re-registration loops here.
        if let data = UserDefaults.standard.data(forKey: Key.hotKey),
           let decoded = try? JSONDecoder().decode(KeyCombo.self, from: data) {
            hotKey = decoded
        } else {
            hotKey = .defaultCombo
        }
        sourceLanguageCode = UserDefaults.standard.string(forKey: Key.sourceLanguage) ?? ""
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
    }

    private func persistHotKey() {
        if let data = try? JSONEncoder().encode(hotKey) {
            UserDefaults.standard.set(data, forKey: Key.hotKey)
        }
    }

    private func updateLoginItem() {
        do {
            let service = SMAppService.mainApp
            if launchAtLogin {
                if service.status != .enabled { try service.register() }
            } else {
                if service.status == .enabled { try service.unregister() }
            }
        } catch {
            NSLog("Zzan: failed to update login item: \(error.localizedDescription)")
        }
    }
}

/// The languages offered in the source-language picker.
struct SourceLanguageOption: Identifiable, Hashable {
    let code: String   // "" means auto-detect
    let name: String
    var id: String { code }

    static let all: [SourceLanguageOption] = [
        .init(code: "", name: "Auto-detect"),
        .init(code: "ko", name: "Korean"),
        .init(code: "ja", name: "Japanese"),
        .init(code: "zh", name: "Chinese"),
        .init(code: "es", name: "Spanish"),
        .init(code: "fr", name: "French"),
        .init(code: "de", name: "German"),
        .init(code: "it", name: "Italian"),
        .init(code: "pt", name: "Portuguese"),
        .init(code: "ru", name: "Russian"),
        .init(code: "ar", name: "Arabic"),
        .init(code: "hi", name: "Hindi"),
        .init(code: "vi", name: "Vietnamese"),
        .init(code: "th", name: "Thai"),
    ]
}
