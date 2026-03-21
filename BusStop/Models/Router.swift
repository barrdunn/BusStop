import SwiftUI
import Combine

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
