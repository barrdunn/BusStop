import SwiftUI
import Combine

enum ItemsRoute: Hashable {
    case folder(String)
    case item(folderID: String, itemID: String)
}

final class Router: ObservableObject {

    enum Tab: Int {
        case list
        case study
        case settings
    }

    @Published var selectedTab: Tab = .list
    @Published var pendingItemID: String? = nil

    func navigateToItem(id: String) {
        selectedTab = .list
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.pendingItemID = id
        }
    }
}
