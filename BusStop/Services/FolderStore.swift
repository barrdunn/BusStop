//
//  FolderStore.swift
//  BusStop
//
//  Created by Barry Dunn on 5/1/26.
//

import Foundation
import Combine
import SwiftUI

final class FolderStore: ObservableObject {

    static let shared = FolderStore()

    @Published private(set) var folders: [Folder] = []

    private let defaults = UserDefaults.standard
    private let storageKey = "bs_folders"
    private let legacyCustomItemsKey = "bs_customItems"

    private init() {
        load()
    }

    // MARK: - Aggregates

    var allItems: [MemoryItem] {
        folders.flatMap { $0.items }
    }

    func folder(for itemID: String) -> Folder? {
        folders.first { $0.items.contains(where: { $0.id == itemID }) }
    }

    func folder(id: String) -> Folder? {
        folders.first { $0.id == id }
    }

    // MARK: - Folder CRUD

    @discardableResult
    func addFolder(name: String) -> Folder {
        let folder = Folder(name: name)
        folders.append(folder)
        save()
        return folder
    }

    func renameFolder(id: String, name: String) {
        guard let idx = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[idx].name = name
        save()
    }

    func deleteFolder(id: String) {
        folders.removeAll { $0.id == id }
        save()
    }

    func deleteFolders(at offsets: IndexSet) {
        folders.remove(atOffsets: offsets)
        save()
    }

    func moveFolders(from source: IndexSet, to destination: Int) {
        folders.move(fromOffsets: source, toOffset: destination)
        save()
    }

    // MARK: - Item CRUD

    @discardableResult
    func addItem(folderID: String,
                 title: String,
                 callout: String,
                 reference: String,
                 body: String) -> MemoryItem? {
        guard let idx = folders.firstIndex(where: { $0.id == folderID }) else { return nil }
        let item = MemoryItem(title: title, callout: callout, reference: reference, body: body)
        folders[idx].items.append(item)
        save()
        return item
    }

    func updateItem(folderID: String,
                    itemID: String,
                    title: String,
                    callout: String,
                    reference: String,
                    body: String) {
        guard let fIdx = folders.firstIndex(where: { $0.id == folderID }),
              let iIdx = folders[fIdx].items.firstIndex(where: { $0.id == itemID }) else { return }
        folders[fIdx].items[iIdx].title = title
        folders[fIdx].items[iIdx].callout = callout
        folders[fIdx].items[iIdx].reference = reference
        folders[fIdx].items[iIdx].body = body
        save()
    }

    func deleteItem(folderID: String, itemID: String) {
        guard let fIdx = folders.firstIndex(where: { $0.id == folderID }) else { return }
        folders[fIdx].items.removeAll { $0.id == itemID }
        save()
    }

    func deleteItems(folderID: String, at offsets: IndexSet) {
        guard let fIdx = folders.firstIndex(where: { $0.id == folderID }) else { return }
        folders[fIdx].items.remove(atOffsets: offsets)
        save()
    }

    func moveItems(folderID: String, from source: IndexSet, to destination: Int) {
        guard let fIdx = folders.firstIndex(where: { $0.id == folderID }) else { return }
        folders[fIdx].items.move(fromOffsets: source, toOffset: destination)
        save()
    }

    // MARK: - Bulk

    func appendItems(folderID: String, items: [MemoryItem]) {
        guard let fIdx = folders.firstIndex(where: { $0.id == folderID }) else { return }
        folders[fIdx].items.append(contentsOf: items)
        save()
    }

    /// Replace all folders/items with the supplied set. Used by full-CSV import.
    func replaceAll(_ folders: [Folder]) {
        self.folders = folders
        save()
    }

    /// Remove every item from every folder, preserving folder structure.
    func clearAllItems() {
        for idx in folders.indices {
            folders[idx].items.removeAll()
        }
        save()
    }

    // MARK: - Persistence

    private func save() {
        if let encoded = try? JSONEncoder().encode(folders) {
            defaults.set(encoded, forKey: storageKey)
        }
    }

    private func load() {
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Folder].self, from: data) {
            folders = decoded
            return
        }
        seedDefaults()
    }

    private func seedDefaults() {
        var seedItems = MemoryItemsData.memoryItemsSeed

        // Carry over any items from the previous "custom items" store so users
        // who upgrade don't lose what they've added.
        if let legacy = defaults.data(forKey: legacyCustomItemsKey),
           let legacyItems = try? JSONDecoder().decode([LegacyStoredItem].self, from: legacy) {
            seedItems.append(contentsOf: legacyItems.map {
                MemoryItem(id: $0.id, title: $0.title, callout: $0.callout, reference: $0.reference, body: $0.body)
            })
            defaults.removeObject(forKey: legacyCustomItemsKey)
        }

        let memoryFolder = Folder(id: "folder-memory-items", name: "Memory Items", items: seedItems)
        folders = [memoryFolder]
        save()
    }

    private struct LegacyStoredItem: Codable {
        let id: String
        let title: String
        let callout: String
        let reference: String
        let body: String
    }
}
