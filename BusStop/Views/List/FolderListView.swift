import SwiftUI

struct FolderListView: View {

    @EnvironmentObject var router: Router
    @ObservedObject var store = FolderStore.shared

    @State private var path: [ItemsRoute] = []
    @State private var showingAddFolder = false
    @State private var newFolderName = ""
    @State private var renameTarget: Folder? = nil
    @State private var renameDraft = ""

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(store.folders) { folder in
                    NavigationLink(value: ItemsRoute.folder(folder.id)) {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(folder.name)
                                    .font(.headline)
                                Text("\(folder.items.count) item\(folder.items.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                        .contextMenu {
                            Button {
                                renameDraft = folder.name
                                renameTarget = folder
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                store.deleteFolder(id: folder.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    store.deleteFolders(at: offsets)
                }
                .onMove { source, destination in
                    store.moveFolders(from: source, to: destination)
                }
            }
            .navigationTitle("Items")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newFolderName = ""
                        showingAddFolder = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
            .navigationDestination(for: ItemsRoute.self) { route in
                switch route {
                case .folder(let folderID):
                    if let folder = store.folder(id: folderID) {
                        ItemListView(folder: folder, path: $path)
                    } else {
                        Text("Folder not found")
                    }
                case .item(let folderID, let itemID):
                    if let folder = store.folder(id: folderID),
                       let item = folder.items.first(where: { $0.id == itemID }) {
                        ItemDetailView(item: item, folderID: folderID)
                    } else {
                        Text("Item not found")
                    }
                }
            }
            .alert("New Folder", isPresented: $showingAddFolder) {
                TextField("Folder name", text: $newFolderName)
                Button("Create") {
                    let trimmed = newFolderName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    store.addFolder(name: trimmed)
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert("Rename Folder", isPresented: Binding(
                get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } }
            )) {
                TextField("Folder name", text: $renameDraft)
                Button("Save") {
                    if let target = renameTarget {
                        let trimmed = renameDraft.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty {
                            store.renameFolder(id: target.id, name: trimmed)
                        }
                    }
                    renameTarget = nil
                }
                Button("Cancel", role: .cancel) {
                    renameTarget = nil
                }
            }
        }
        .onChange(of: router.pendingItemID) { _, itemID in
            guard let itemID, let folder = store.folder(for: itemID) else { return }
            path = [.folder(folder.id), .item(folderID: folder.id, itemID: itemID)]
            router.pendingItemID = nil
        }
    }
}
