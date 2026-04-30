import Foundation

struct Folder: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var items: [MemoryItem]

    init(id: String = "folder-\(UUID().uuidString)",
         name: String,
         items: [MemoryItem] = []) {
        self.id = id
        self.name = name
        self.items = items
    }
}
