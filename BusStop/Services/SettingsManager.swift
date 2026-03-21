import Foundation
import Combine

final class SettingsManager: ObservableObject {

    static let shared = SettingsManager()

    enum NotificationInterval: Int {
        case hour = 0
        case day = 1
        case week = 2

        var label: String {
            switch self {
            case .hour: return "per hour"
            case .day: return "per day"
            case .week: return "per week"
            }
        }
    }

    // MARK: Notification Schedule

    @Published var notificationCount: Int {
        didSet { defaults.set(notificationCount, forKey: Keys.notificationCount) }
    }

    @Published var notificationInterval: NotificationInterval {
        didSet { defaults.set(notificationInterval.rawValue, forKey: Keys.notificationInterval) }
    }

    @Published var activeStartHour: Int {
        didSet { defaults.set(activeStartHour, forKey: Keys.activeStartHour) }
    }

    @Published var activeEndHour: Int {
        didSet { defaults.set(activeEndHour, forKey: Keys.activeEndHour) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    // MARK: Study Options

    @Published var breakDownItems: Bool {
        didSet { defaults.set(breakDownItems, forKey: Keys.breakDownItems) }
    }

    @Published var includeStabilized: Bool {
        didSet { defaults.set(includeStabilized, forKey: Keys.includeStabilized) }
    }

    // MARK: Developer Mode

    @Published var developerModeEnabled: Bool {
        didSet { defaults.set(developerModeEnabled, forKey: Keys.developerModeEnabled) }
    }

    // MARK: Computed

    /// Total notifications per day based on interval and active hours
    var effectivePerDay: Int {
        let activeHours = max(activeEndHour - activeStartHour, 1)
        switch notificationInterval {
        case .hour:
            return notificationCount * activeHours
        case .day:
            return notificationCount
        case .week:
            return max(notificationCount / 7, 1)
        }
    }

    // MARK: - Init

    private let defaults = UserDefaults.standard

    private init() {
        let registered: [String: Any] = [
            Keys.notificationCount: 5,
            Keys.notificationInterval: NotificationInterval.day.rawValue,
            Keys.activeStartHour: 8,
            Keys.activeEndHour: 22,
            Keys.notificationsEnabled: true,
            Keys.breakDownItems: false,
            Keys.includeStabilized: false,
            Keys.developerModeEnabled: false,
        ]
        defaults.register(defaults: registered)

        self.notificationCount = defaults.integer(forKey: Keys.notificationCount)
        self.notificationInterval = NotificationInterval(rawValue: defaults.integer(forKey: Keys.notificationInterval)) ?? .day
        self.activeStartHour = defaults.integer(forKey: Keys.activeStartHour)
        self.activeEndHour = defaults.integer(forKey: Keys.activeEndHour)
        self.notificationsEnabled = defaults.bool(forKey: Keys.notificationsEnabled)
        self.breakDownItems = defaults.bool(forKey: Keys.breakDownItems)
        self.includeStabilized = defaults.bool(forKey: Keys.includeStabilized)
        self.developerModeEnabled = defaults.bool(forKey: Keys.developerModeEnabled)
    }

    // MARK: - Keys

    private enum Keys {
        static let notificationCount = "bs_notificationCount"
        static let notificationInterval = "bs_notificationInterval"
        static let activeStartHour = "bs_activeStartHour"
        static let activeEndHour = "bs_activeEndHour"
        static let notificationsEnabled = "bs_notificationsEnabled"
        static let breakDownItems = "bs_breakDownItems"
        static let includeStabilized = "bs_includeStabilized"
        static let developerModeEnabled = "bs_developerModeEnabled"
    }
}
