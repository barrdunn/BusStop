import SwiftUI

struct ItemListView: View {

    @EnvironmentObject var router: Router
    @EnvironmentObject var settings: SettingsManager
    @State private var path: [String] = []

    private var items: [MemoryItem] {
        MemoryItemsData.resolved(breakDown: settings.breakDownItems, includeStabilized: settings.includeStabilized)
    }

    var body: some View {
        NavigationStack(path: $path) {
            List(items) { item in
                NavigationLink(value: item.id) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                        Text("\"\(item.callout)\"")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .id("\(settings.breakDownItems)-\(settings.includeStabilized)")
            .navigationTitle("Memory Items")
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
