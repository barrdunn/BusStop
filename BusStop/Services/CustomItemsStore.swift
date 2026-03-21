import Foundation
import Combine
import SwiftUI

final class CustomItemsStore: ObservableObject {

    static let shared = CustomItemsStore()

    @Published private(set) var items: [MemoryItem] = []

    private let defaults = UserDefaults.standard
    private let key = "bs_customItems"

    private init() {
        load()
    }

    func add(title: String, callout: String, reference: String, body: String) {
        let item = MemoryItem(
            id: "custom-\(UUID().uuidString)",
            title: title,
            callout: callout,
            reference: reference,
            body: body
        )
        items.append(item)
        save()
    }

    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func remove(id: String) {
        items.removeAll { $0.id == id }
        save()
    }

    // MARK: - Persistence

    private func save() {
        let data = items.map { StoredItem(id: $0.id, title: $0.title, callout: $0.callout, reference: $0.reference, body: $0.body) }
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: key)
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let stored = try? JSONDecoder().decode([StoredItem].self, from: data) else { return }
        items = stored.map { MemoryItem(id: $0.id, title: $0.title, callout: $0.callout, reference: $0.reference, body: $0.body) }
    }

    private struct StoredItem: Codable {
        let id: String
        let title: String
        let callout: String
        let reference: String
        let body: String
    }
}
