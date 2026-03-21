import Foundation

struct MemoryItem: Identifiable {
    let id: String
    let title: String
    let callout: String
    let reference: String
    let body: String
    let subItems: [MemoryItem]?

    init(id: String, title: String, callout: String, reference: String = "", body: String, subItems: [MemoryItem]? = nil) {
        self.id = id
        self.title = title
        self.callout = callout
        self.reference = reference
        self.body = body
        self.subItems = subItems
    }
}
