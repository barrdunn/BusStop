import SwiftUI

struct ItemListView: View {

    @EnvironmentObject var router: Router
    @EnvironmentObject var settings: SettingsManager
    @ObservedObject var customStore = CustomItemsStore.shared
    @State private var path: [String] = []
    @State private var showingAddSheet: Bool = false

    private var items: [MemoryItem] {
        MemoryItemsData.resolved(breakDown: settings.breakDownItems, includeStabilized: settings.includeStabilized, custom: customStore.items)
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(items) { item in
                    NavigationLink(value: item.id) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.title)
                                    .font(.headline)
                                if item.id.hasPrefix("custom-") {
                                    Spacer()
                                    Text("Custom")
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(.blue))
                                }
                            }
                            Text("\"\(item.callout)\"")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { offsets in
                    // Only allow deleting custom items
                    let builtInCount = items.count - customStore.items.count
                    let customOffsets = IndexSet(offsets.compactMap { index in
                        let adjustedIndex = index - builtInCount
                        return adjustedIndex >= 0 ? adjustedIndex : nil
                    })
                    if !customOffsets.isEmpty {
                        customStore.remove(at: customOffsets)
                    }
                }
            }
            .id("\(settings.breakDownItems)-\(settings.includeStabilized)-\(customStore.items.count)")
            .listStyle(.plain)
            .navigationTitle("Memory Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddItemView()
            }
            .navigationDestination(for: String.self) { itemID in
                if let item = items.first(where: { $0.id == itemID }) {
                    ItemDetailView(item: item)
                }
            }
        }
        .onChange(of: router.pendingItemID) { _, itemID in
            guard let itemID else { return }
            path = [itemID]
            router.pendingItemID = nil
        }
    }
}
