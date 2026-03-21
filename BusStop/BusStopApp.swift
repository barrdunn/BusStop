import SwiftUI

@main
struct BusStopApp: App {

    @StateObject private var router = Router()
    @StateObject private var settings = SettingsManager.shared

    private let notifications = NotificationManager.shared

    init() {
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .environmentObject(settings)
                .onAppear {
                    notifications.onItemTapped = { [weak router] itemID in
                        router?.navigateToItem(id: itemID)
                    }
                    notifications.reschedule()
                }
        }
    }
}
