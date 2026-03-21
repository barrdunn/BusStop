import SwiftUI

struct ItemDetailView: View {

    let item: MemoryItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Callout banner
                HStack {
                    Spacer()
                    Text("\"\(item.callout)\"")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.red)

                // Body
                Text(item.body)
                    .font(.system(.body, design: .monospaced))
                    .padding(16)
            }
            .padding(.bottom, 32)
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.large)
    }
}
