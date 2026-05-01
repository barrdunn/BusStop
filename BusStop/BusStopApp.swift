//
//  BusStopApp.swift
//  BusStop
//
//  Created by Barry Dunn on 5/1/26.
//

import SwiftUI
import BackgroundTasks

@main
struct BusStopApp: App {

    @StateObject private var router = Router()
    @StateObject private var settings = SettingsManager.shared
    @Environment(\.scenePhase) private var scenePhase

    private let notifications = NotificationManager.shared

    init() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.busstop.refresh",
            using: nil
        ) { task in
            NotificationManager.shared.reschedule()
            task.setTaskCompleted(success: true)
            NotificationManager.shared.scheduleBackgroundRefresh()
        }
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
                    notifications.requestPermission {
                        notifications.reschedule()
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        notifications.reschedule()
                    }
                    if phase == .background {
                        notifications.scheduleBackgroundRefresh()
                    }
                }
        }
    }
}
