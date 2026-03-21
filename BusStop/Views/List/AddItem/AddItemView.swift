import SwiftUI

struct AddItemView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store = CustomItemsStore.shared

    @State private var title: String = ""
    @State private var callout: String = ""
    @State private var reference: String = ""
    @State private var body: String = ""

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
                    TextEditor(text: $body)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.add(title: title, callout: callout, reference: reference, body: body)
                        dismiss()
                    }
                    .disabled(title.isEmpty || body.isEmpty)
                }
            }
        }
    }
}
