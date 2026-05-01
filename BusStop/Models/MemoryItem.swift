//
//  MemoryItem.swift
//  BusStop
//
//  Created by Barry Dunn on 5/1/26.
//

import Foundation

struct MemoryItem: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var callout: String
    var reference: String
    var body: String

    init(id: String = "item-\(UUID().uuidString)",
         title: String,
         callout: String,
         reference: String = "",
         body: String) {
        self.id = id
        self.title = title
        self.callout = callout
        self.reference = reference
        self.body = body
    }
}
