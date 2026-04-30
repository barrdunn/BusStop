import Foundation
import UserNotifications
import BackgroundTasks

final class NotificationManager: NSObject {

    static let shared = NotificationManager()

    static let categoryID = "MEMORY_ITEM"
    static let itemIDKey = "memoryItemID"
    static let maxPending = 62
    static let bgTaskID = "com.busstop.refresh"

    var onItemTapped: ((String) -> Void)?

    private let center = UNUserNotificationCenter.current()
    private let settings = SettingsManager.shared

    private var items: [MemoryItem] {
        FolderStore.shared.allItems
    }

    private override init() {
        super.init()
        center.delegate = self
        registerCategory()
    }

    // MARK: - Permissions

    func requestPermission(completion: (() -> Void)? = nil) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error { print("[BusStop] Notification auth error: \(error)") }
            print("[BusStop] Notifications authorized: \(granted)")
            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    // MARK: - Background Refresh

    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.bgTaskID)
        // Ask to be woken when roughly half our notifications have fired
        let halfwaySeconds = estimateHalfwayInterval()
        request.earliestBeginDate = Date(timeIntervalSinceNow: halfwaySeconds)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("[BusStop] BG refresh scheduled in ~\(Int(halfwaySeconds))s")
        } catch {
            print("[BusStop] BG refresh schedule failed: \(error)")
        }
    }

    /// Estimate when roughly half the scheduled notifications will have fired
    private func estimateHalfwayInterval() -> TimeInterval {
        let activeHours = Double(max(settings.activeEndHour - settings.activeStartHour, 1))
        let perDay: Double

        switch settings.notificationInterval {
        case .hour:
            perDay = Double(settings.notificationCount) * activeHours
        case .day:
            perDay = Double(settings.notificationCount)
        case .week:
            perDay = Double(settings.notificationCount) / 7.0
        }

        guard perDay > 0 else { return 3600 }

        // How many days do 62 notifications cover?
        let daysCovered = Double(Self.maxPending) / perDay
        // Ask to refresh at the halfway point
        let halfwayDays = daysCovered / 2.0
        let seconds = halfwayDays * 86400

        // Clamp between 15 min and 12 hours
        return min(max(seconds, 900), 43200)
    }

    // MARK: - Debug

    func debugStatus(completion: @escaping (String) -> Void) {
        center.getNotificationSettings { notifSettings in
            self.center.getPendingNotificationRequests { requests in
                let authStatus: String
                switch notifSettings.authorizationStatus {
                case .authorized: authStatus = "Authorized"
                case .denied: authStatus = "DENIED"
                case .provisional: authStatus = "Provisional"
                case .ephemeral: authStatus = "Ephemeral"
                case .notDetermined: authStatus = "Not Determined"
                @unknown default: authStatus = "Unknown"
                }

                let nextFire: String
                if let next = requests.compactMap({ $0.trigger as? UNTimeIntervalNotificationTrigger })
                    .sorted(by: { $0.timeInterval < $1.timeInterval }).first {
                    nextFire = "\(Int(next.timeInterval))s from now"
                } else {
                    nextFire = "None"
                }

                let lastFire: String
                if let last = requests.compactMap({ $0.trigger as? UNTimeIntervalNotificationTrigger })
                    .sorted(by: { $0.timeInterval < $1.timeInterval }).last {
                    let hours = last.timeInterval / 3600
                    lastFire = String(format: "%.1fh from now", hours)
                } else {
                    lastFire = "None"
                }

                let status = """
                Auth: \(authStatus)
                Alert: \(notifSettings.alertSetting == .enabled ? "ON" : "OFF")
                Sound: \(notifSettings.soundSetting == .enabled ? "ON" : "OFF")
                Pending: \(requests.count)
                Next: \(nextFire)
                Last: \(lastFire)
                Items pool: \(self.items.count)
                """

                DispatchQueue.main.async {
                    completion(status)
                }
            }
        }
    }

    // MARK: - Schedule Notifications

    func reschedule() {
        center.getNotificationSettings { [weak self] notifSettings in
            guard let self else { return }

            guard notifSettings.authorizationStatus == .authorized ||
                  notifSettings.authorizationStatus == .provisional else {
                print("[BusStop] Not authorized, skipping schedule")
                return
            }

            DispatchQueue.main.async {
                self.doReschedule()
            }
        }
    }

    private func doReschedule() {
        center.removeAllPendingNotificationRequests()

        guard settings.notificationsEnabled else {
            print("[BusStop] Notifications disabled in settings")
            return
        }

        let startHour = settings.activeStartHour
        let endHour = settings.activeEndHour

        guard endHour > startHour, !items.isEmpty else {
            print("[BusStop] Invalid hours or no items")
            return
        }

        let calendar = Calendar.current
        let daysToSchedule = 14

        var allTimes: [(date: Date, item: MemoryItem)] = []

        for dayOffset in 0..<daysToSchedule {
            guard let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }

            let countForDay = notificationsForDay(dayOffset: dayOffset)
            guard countForDay > 0 else { continue }

            let times = generateRandomTimes(count: countForDay, startHour: startHour, endHour: endHour,
                                            baseDate: baseDate, calendar: calendar)

            for fireDate in times {
                guard fireDate > Date() else { continue }
                let item = items.randomElement()!
                allTimes.append((date: fireDate, item: item))
            }
        }

        allTimes.sort { $0.date < $1.date }
        let toSchedule = allTimes.prefix(Self.maxPending)

        for (index, entry) in toSchedule.enumerated() {
            scheduleNotification(item: entry.item, fireDate: entry.date, identifier: "bs-\(index)")
        }

        print("[BusStop] Scheduled \(toSchedule.count) notifications")
        if let first = toSchedule.first {
            print("[BusStop] Next in \(Int(first.date.timeIntervalSinceNow))s")
        }
        if let last = toSchedule.last {
            print("[BusStop] Last in \(Int(last.date.timeIntervalSinceNow / 3600))h")
        }
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
        guard let item = items.randomElement() else { return }
        scheduleNotification(item: item, fireDate: Date().addingTimeInterval(1),
                             identifier: "bs-dev-now-\(UUID().uuidString)")
        print("[BusStop] Dev: sending \(item.title) in 1s")
    }

    func devSendAfter(seconds: TimeInterval) {
        guard let item = items.randomElement() else { return }
        let fireDate = Date().addingTimeInterval(seconds)
        scheduleNotification(item: item, fireDate: fireDate, identifier: "bs-dev-\(UUID().uuidString)")
        print("[BusStop] Dev: scheduled \(item.title) in \(seconds)s")
    }

    func devSendBatch(count: Int, withinSeconds totalSeconds: TimeInterval) {
        for i in 0..<count {
            let delay = TimeInterval.random(in: 1...totalSeconds)
            guard let item = items.randomElement() else { return }
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
