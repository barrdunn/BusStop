import Foundation
import UserNotifications

final class NotificationManager: NSObject {

    static let shared = NotificationManager()

    static let categoryID = "MEMORY_ITEM"
    static let itemIDKey = "memoryItemID"

    var onItemTapped: ((String) -> Void)?

    private let center = UNUserNotificationCenter.current()
    private let settings = SettingsManager.shared

    private var items: [MemoryItem] {
        MemoryItemsData.resolved(breakDown: settings.breakDownItems, includeStabilized: settings.includeStabilized, custom: CustomItemsStore.shared.items)
    }

    private override init() {
        super.init()
        center.delegate = self
        registerCategory()
    }

    // MARK: - Permissions

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error { print("[BusStop] Notification auth error: \(error)") }
            if granted { print("[BusStop] Notifications authorized") }
        }
    }

    // MARK: - Schedule Notifications

    func reschedule() {
        center.removeAllPendingNotificationRequests()

        guard settings.notificationsEnabled else { return }

        let startHour = settings.activeStartHour
        let endHour = settings.activeEndHour

        guard endHour > startHour, !items.isEmpty else { return }

        let calendar = Calendar.current
        let daysToSchedule: Int

        switch settings.notificationInterval {
        case .hour, .day:
            daysToSchedule = 2
        case .week:
            daysToSchedule = 7
        }

        for dayOffset in 0..<daysToSchedule {
            guard let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }

            let countForDay = notificationsForDay(dayOffset: dayOffset)
            guard countForDay > 0 else { continue }

            let times = generateRandomTimes(count: countForDay, startHour: startHour, endHour: endHour,
                                            baseDate: baseDate, calendar: calendar)

            for (index, fireDate) in times.enumerated() {
                guard fireDate > Date() else { continue }

                let item = items.randomElement()!
                scheduleNotification(item: item, fireDate: fireDate,
                                     identifier: "bs-day\(dayOffset)-\(index)")
            }
        }

        print("[BusStop] Scheduled notifications for \(daysToSchedule) days")
    }

    private func notificationsForDay(dayOffset: Int) -> Int {
        let activeHours = max(settings.activeEndHour - settings.activeStartHour, 1)

        switch settings.notificationInterval {
        case .hour:
            return settings.notificationCount * activeHours
        case .day:
            return settings.notificationCount
        case .week:
            let base = settings.notificationCount / 7
            let remainder = settings.notificationCount % 7
            return base + (dayOffset < remainder ? 1 : 0)
        }
    }

    // MARK: - Developer Mode

    func devSendNow() {
        let item = items.randomElement()!
        scheduleNotification(item: item, fireDate: Date().addingTimeInterval(1),
                             identifier: "bs-dev-now-\(UUID().uuidString)")
        print("[BusStop] Dev: sending \(item.title) in 1s")
    }

    func devSendAfter(seconds: TimeInterval) {
        let item = items.randomElement()!
        let fireDate = Date().addingTimeInterval(seconds)
        scheduleNotification(item: item, fireDate: fireDate, identifier: "bs-dev-\(UUID().uuidString)")
        print("[BusStop] Dev: scheduled \(item.title) in \(seconds)s")
    }

    func devSendBatch(count: Int, withinSeconds totalSeconds: TimeInterval) {
        for i in 0..<count {
            let delay = TimeInterval.random(in: 1...totalSeconds)
            let item = items.randomElement()!
            let fireDate = Date().addingTimeInterval(delay)
            scheduleNotification(item: item, fireDate: fireDate, identifier: "bs-dev-batch-\(i)-\(UUID().uuidString)")
            print("[BusStop] Dev batch: \(item.title) in \(Int(delay))s")
        }
    }

    // MARK: - Private

    private func registerCategory() {
        let category = UNNotificationCategory(
            identifier: Self.categoryID,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    private func generateRandomTimes(count: Int, startHour: Int, endHour: Int,
                                     baseDate: Date, calendar: Calendar) -> [Date] {
        var times: [Date] = []
        let windowMinutes = (endHour - startHour) * 60

        for _ in 0..<count {
            let randomMinute = Int.random(in: 0..<windowMinutes)
            let hour = startHour + (randomMinute / 60)
            let minute = randomMinute % 60

            var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
            components.hour = hour
            components.minute = minute
            components.second = Int.random(in: 0..<60)

            if let date = calendar.date(from: components) {
                times.append(date)
            }
        }

        return times.sorted()
    }

    private func scheduleNotification(item: MemoryItem, fireDate: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "🚏 Bus Stop"
        content.body = item.title
        content.sound = .default
        content.categoryIdentifier = Self.categoryID
        content.userInfo = [Self.itemIDKey: item.id]

        let interval = fireDate.timeIntervalSinceNow
        guard interval > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { error in
            if let error { print("[BusStop] Schedule error: \(error)") }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let itemID = userInfo[Self.itemIDKey] as? String {
            DispatchQueue.main.async { [weak self] in
                self?.onItemTapped?(itemID)
            }
        }
        completionHandler()
    }
}
