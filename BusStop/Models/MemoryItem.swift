//
//  MemoryItem.swift
//  BusStop
//
//  Created by Barry Dunn on 5/1/26.
//

import Foundation

nonisolated struct MemoryItem: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var callout: String
    var reference: String
    var body: String
    var isEmergency: Bool

    init(id: String = "item-\(UUID().uuidString)",
         title: String,
         callout: String,
         reference: String = "",
         body: String,
         isEmergency: Bool = false) {
        self.id = id
        self.title = title
        self.callout = callout
        self.reference = reference
        self.body = body
        self.isEmergency = isEmergency
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, callout, reference, body, isEmergency
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.title = try c.decode(String.self, forKey: .title)
        self.callout = try c.decode(String.self, forKey: .callout)
        self.reference = try c.decode(String.self, forKey: .reference)
        self.body = try c.decode(String.self, forKey: .body)
        self.isEmergency = (try? c.decode(Bool.self, forKey: .isEmergency)) ?? false
    }
}
