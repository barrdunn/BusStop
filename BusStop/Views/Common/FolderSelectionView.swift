//
//  FolderSelectionView.swift
//  BusStop
//
//  Created by Barry Dunn on 5/1/26.
//

import SwiftUI

struct FolderSelectionView: View {

    let title: String
    let footer: String?
    @Binding var disabledFolderIDs: Set<String>

    @ObservedObject private var store = FolderStore.shared
    @Environment(\.dismiss) private var dismiss

    init(title: String, footer: String? = nil, disabledFolderIDs: Binding<Set<String>>) {
        self.title = title
        self.footer = footer
        self._disabledFolderIDs = disabledFolderIDs
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if store.folders.isEmpty {
                        Text("No folders to choose from.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.folders) { folder in
                            Button {
                                toggle(folder.id)
                            } label: {
                                HStack {
                                    Image(systemName: isEnabled(folder.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isEnabled(folder.id) ? .blue : .secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(folder.name)
                                            .foregroundStyle(.primary)
                                        Text("\(folder.items.count) item\(folder.items.count == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                } footer: {
                    if let footer { Text(footer) }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("All") {
                        disabledFolderIDs.removeAll()
                    }
                    .disabled(disabledFolderIDs.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func isEnabled(_ id: String) -> Bool {
        !disabledFolderIDs.contains(id)
    }

    private func toggle(_ id: String) {
        if disabledFolderIDs.contains(id) {
            disabledFolderIDs.remove(id)
        } else {
            disabledFolderIDs.insert(id)
        }
    }
}
