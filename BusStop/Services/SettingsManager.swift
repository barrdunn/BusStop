import Foundation
import Combine

final class SettingsManager: ObservableObject {

    static let shared = SettingsManager()

    // MARK: Notification Schedule

    @Published var notificationsPerDay: Int {
        didSet { defaults.set(notificationsPerDay, forKey: Keys.notificationsPerDay) }
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

    // MARK: - Init

    private let defaults = UserDefaults.standard

    private init() {
        let registered: [String: Any] = [
            Keys.notificationsPerDay: 5,
            Keys.activeStartHour: 8,
            Keys.activeEndHour: 22,
            Keys.notificationsEnabled: true,
            Keys.breakDownItems: false,
            Keys.includeStabilized: false,
            Keys.developerModeEnabled: false,
        ]
        defaults.register(defaults: registered)

        self.notificationsPerDay = defaults.integer(forKey: Keys.notificationsPerDay)
        self.activeStartHour = defaults.integer(forKey: Keys.activeStartHour)
        self.activeEndHour = defaults.integer(forKey: Keys.activeEndHour)
        self.notificationsEnabled = defaults.bool(forKey: Keys.notificationsEnabled)
        self.breakDownItems = defaults.bool(forKey: Keys.breakDownItems)
        self.includeStabilized = defaults.bool(forKey: Keys.includeStabilized)
        self.developerModeEnabled = defaults.bool(forKey: Keys.developerModeEnabled)
    }

    // MARK: - Keys

    private enum Keys {
        static let notificationsPerDay = "bs_notificationsPerDay"
        static let activeStartHour = "bs_activeStartHour"
        static let activeEndHour = "bs_activeEndHour"
        static let notificationsEnabled = "bs_notificationsEnabled"
        static let breakDownItems = "bs_breakDownItems"
        static let includeStabilized = "bs_includeStabilized"
        static let developerModeEnabled = "bs_developerModeEnabled"
    }
}
