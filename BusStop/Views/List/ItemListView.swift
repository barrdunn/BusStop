//
//  ItemListView.swift
//  BusStop
//
//  Created by Barry Dunn on 5/1/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ItemListView: View {

    let folder: Folder
    @Binding var path: [ItemsRoute]

    @ObservedObject var store = FolderStore.shared

    @State private var showingAddSheet = false
    @State private var showingImporter = false
    @State private var importError: String? = nil

    private var liveFolder: Folder {
        store.folder(id: folder.id) ?? folder
    }

    var body: some View {
        List {
            if liveFolder.items.isEmpty {
                Text("No items yet. Tap + to add one, or import a CSV from the menu.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(liveFolder.items) { item in
                    NavigationLink(value: ItemsRoute.item(folderID: liveFolder.id, itemID: item.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)
                            if !item.callout.isEmpty {
                                Text("\"\(item.callout)\"")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { offsets in
                    store.deleteItems(folderID: liveFolder.id, at: offsets)
                }
                .onMove { source, destination in
                    store.moveItems(folderID: liveFolder.id, from: source, to: destination)
                }
            }
        }
        .navigationTitle(liveFolder.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                    Button {
                        showingImporter = true
                    } label: {
                        Label("Import CSV…", systemImage: "square.and.arrow.down")
                    }
                    EditButton()
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddItemView(folderID: liveFolder.id)
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert("Import Failed", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let text = try String(contentsOf: url, encoding: .utf8)
                try CSVService.importAppending(csv: text, folderID: liveFolder.id, into: store)
            } catch {
                importError = error.localizedDescription
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }
}
