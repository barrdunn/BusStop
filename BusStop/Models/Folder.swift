//
//  Folder.swift
//  BusStop
//
//  Created by Barry Dunn on 5/1/26.
//

import Foundation

nonisolated struct Folder: Identifiable, Codable, Hashable {
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
