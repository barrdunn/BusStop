//
//  AddItemView.swift
//  BusStop
//
//  Created by Barry Dunn on 5/1/26.
//

import SwiftUI

struct AddItemView: View {

    let folderID: String
    let editingItem: MemoryItem?

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = FolderStore.shared

    @State private var title: String
    @State private var callout: String
    @State private var reference: String
    @State private var procedure: String
    @State private var isAbnormal: Bool

    init(folderID: String, editingItem: MemoryItem? = nil) {
        self.folderID = folderID
        self.editingItem = editingItem
        _title = State(initialValue: editingItem?.title ?? "")
        _callout = State(initialValue: editingItem?.callout ?? "")
        _reference = State(initialValue: editingItem?.reference ?? "")
        _procedure = State(initialValue: editingItem?.body ?? "")
        _isAbnormal = State(initialValue: editingItem?.isAbnormal ?? false)
    }

    private var isEditing: Bool { editingItem != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("e.g. Engine Failure", text: $title)
                }

                Section("Callout") {
                    TextField("e.g. ENGINE FAILURE", text: $callout)
                }

                Section("Reference") {
                    TextField("e.g. Refer to Vol II - ABN - ...", text: $reference)
                }

                Section {
                    Toggle(isOn: $isAbnormal) {
                        Label("Abnormal Procedure", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(isAbnormal ? Color.red : Color.primary)
                    }
                } footer: {
                    Text("Abnormal items are marked with a red dot in the list and a red reference.")
                }

                Section("Procedure") {
                    TextEditor(text: $procedure)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.isEmpty)
                }
            }
        }
    }

    private func save() {
        if let editing = editingItem {
            store.updateItem(folderID: folderID,
                             itemID: editing.id,
                             title: title,
                             callout: callout,
                             reference: reference,
                             body: procedure,
                             isAbnormal: isAbnormal)
        } else {
            store.addItem(folderID: folderID,
                          title: title,
                          callout: callout,
                          reference: reference,
                          body: procedure,
                          isAbnormal: isAbnormal)
        }
        dismiss()
    }
}
