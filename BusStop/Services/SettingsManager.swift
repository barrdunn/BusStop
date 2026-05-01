//
//  SettingsManager.swift
//  BusStop
//
//  Created by Barry Dunn on 5/1/26.
//

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

    // MARK: Folder Selection

    /// Folder IDs explicitly excluded from the study deck. Empty = all folders.
    @Published var disabledStudyFolderIDs: Set<String> {
        didSet { Self.saveSet(disabledStudyFolderIDs, key: Keys.disabledStudyFolderIDs, defaults: defaults) }
    }

    /// Folder IDs explicitly excluded from notifications. Empty = all folders.
    @Published var disabledNotificationFolderIDs: Set<String> {
        didSet { Self.saveSet(disabledNotificationFolderIDs, key: Keys.disabledNotificationFolderIDs, defaults: defaults) }
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
            Keys.developerModeEnabled: false,
        ]
        defaults.register(defaults: registered)

        self.notificationCount = defaults.integer(forKey: Keys.notificationCount)
        self.notificationInterval = NotificationInterval(rawValue: defaults.integer(forKey: Keys.notificationInterval)) ?? .day
        self.activeStartHour = defaults.integer(forKey: Keys.activeStartHour)
        self.activeEndHour = defaults.integer(forKey: Keys.activeEndHour)
        self.notificationsEnabled = defaults.bool(forKey: Keys.notificationsEnabled)
        self.developerModeEnabled = defaults.bool(forKey: Keys.developerModeEnabled)
        self.disabledStudyFolderIDs = Self.loadSet(key: Keys.disabledStudyFolderIDs, defaults: defaults)
        self.disabledNotificationFolderIDs = Self.loadSet(key: Keys.disabledNotificationFolderIDs, defaults: defaults)
    }

    private static func saveSet(_ set: Set<String>, key: String, defaults: UserDefaults) {
        if let data = try? JSONEncoder().encode(Array(set)) {
            defaults.set(data, forKey: key)
        }
    }

    private static func loadSet(key: String, defaults: UserDefaults) -> Set<String> {
        guard let data = defaults.data(forKey: key),
              let arr = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return Set(arr)
    }

    // MARK: - Keys

    private enum Keys {
        static let notificationCount = "bs_notificationCount"
        static let notificationInterval = "bs_notificationInterval"
        static let activeStartHour = "bs_activeStartHour"
        static let activeEndHour = "bs_activeEndHour"
        static let notificationsEnabled = "bs_notificationsEnabled"
        static let developerModeEnabled = "bs_developerModeEnabled"
        static let disabledStudyFolderIDs = "bs_disabledStudyFolderIDs"
        static let disabledNotificationFolderIDs = "bs_disabledNotificationFolderIDs"
    }
}
