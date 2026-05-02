//
//  ItemDetailView.swift
//  BusStop
//
//  Created by Barry Dunn on 5/1/26.
//

import SwiftUI

struct ItemDetailView: View {

    let item: MemoryItem
    let folderID: String

    @ObservedObject private var store = FolderStore.shared
    @State private var showingEdit = false

    private var liveItem: MemoryItem {
        store.folder(id: folderID)?.items.first(where: { $0.id == item.id }) ?? item
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !liveItem.callout.isEmpty {
                    HStack {
                        Spacer()
                        Text("\"\(liveItem.callout)\"")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(Color.red)
                }

                if !liveItem.reference.isEmpty {
                    Text(liveItem.reference)
                        .font(.footnote.bold())
                        .foregroundStyle(liveItem.isAbnormal ? Color.red : Color.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                if !liveItem.body.isEmpty {
                    Text(liveItem.body)
                        .font(.system(.body, design: .monospaced))
                        .padding(16)
                }
            }
            .padding(.bottom, 32)
        }
        .navigationTitle(liveItem.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddItemView(folderID: folderID, editingItem: liveItem)
        }
    }
}
