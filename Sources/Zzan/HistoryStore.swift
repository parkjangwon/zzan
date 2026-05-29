import AppKit
import SwiftUI

/// Keeps the most recent translations and persists them to UserDefaults.
@MainActor
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()

    struct Item: Identifiable, Codable, Equatable {
        let id: UUID
        let source: String
        let translated: String

        /// Short label for the menu bar list.
        var menuTitle: String {
            let collapsed = translated.replacingOccurrences(of: "\n", with: " ")
            return collapsed.count > 44 ? String(collapsed.prefix(44)) + "…" : collapsed
        }
    }

    private static let maxItems = 10
    private static let storageKey = "history"

    @Published private(set) var items: [Item] = []

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([Item].self, from: data) {
            items = decoded
        }
    }

    func add(source: String, translated: String) {
        let item = Item(id: UUID(), source: source, translated: translated)
        items.insert(item, at: 0)
        if items.count > Self.maxItems {
            items = Array(items.prefix(Self.maxItems))
        }
        persist()
    }

    /// Re-copies a previous translation to the clipboard.
    func recopy(_ item: Item) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.translated, forType: .string)
    }

    func clear() {
        items = []
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
