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

    init(folderID: String, editingItem: MemoryItem? = nil) {
        self.folderID = folderID
        self.editingItem = editingItem
        _title = State(initialValue: editingItem?.title ?? "")
        _callout = State(initialValue: editingItem?.callout ?? "")
        _reference = State(initialValue: editingItem?.reference ?? "")
        _procedure = State(initialValue: editingItem?.body ?? "")
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
                        .disabled(title.isEmpty || procedure.isEmpty)
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
                             body: procedure)
        } else {
            store.addItem(folderID: folderID,
                          title: title,
                          callout: callout,
                          reference: reference,
                          body: procedure)
        }
        dismiss()
    }
}
