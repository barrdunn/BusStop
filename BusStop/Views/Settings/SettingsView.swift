import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var settings: SettingsManager

    @State private var devDelaySeconds: Double = 5
    @State private var devBatchCount: Double = 3
    @State private var devBatchMinutes: Double = 1

    private let notifications = NotificationManager.shared

    var body: some View {
        NavigationStack {
            Form {
                studySection
                notificationSection
                scheduleSection
                developerSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Study

    private var studySection: some View {
        Section {
            Toggle("Break Down Items", isOn: $settings.breakDownItems)
            Toggle("Stabilized Approach Criteria", isOn: $settings.includeStabilized)
        } header: {
            Text("Items")
        } footer: {
            Text("Break Down splits TCAS (2) and Windshear (3) into separate items. Stabilized Approach adds approach criteria to the item pool.")
        }
    }

    // MARK: - Notification Settings

    private var notificationSection: some View {
        Section("Notifications") {
            Toggle("Enabled", isOn: $settings.notificationsEnabled)
                .onChange(of: settings.notificationsEnabled) { _, _ in
                    notifications.reschedule()
                }

            Stepper("Per day: \(settings.notificationsPerDay)",
                    value: $settings.notificationsPerDay, in: 1...30)
                .onChange(of: settings.notificationsPerDay) { _, _ in
                    notifications.reschedule()
                }
        }
    }

    private var scheduleSection: some View {
        Section("Active Hours") {
            HStack {
                Text("Start")
                Spacer()
                Picker("", selection: $settings.activeStartHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(formatHour(hour)).tag(hour)
                    }
                }
                .labelsHidden()
            }

            HStack {
                Text("End")
                Spacer()
                Picker("", selection: $settings.activeEndHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(formatHour(hour)).tag(hour)
                    }
                }
                .labelsHidden()
            }

            Button("Reschedule Now") {
                notifications.reschedule()
            }
        }
        .onChange(of: settings.activeStartHour) { _, _ in notifications.reschedule() }
        .onChange(of: settings.activeEndHour) { _, _ in notifications.reschedule() }
    }

    // MARK: - Developer Mode

    private var developerSection: some View {
        Section {
            Toggle("Developer Mode", isOn: $settings.developerModeEnabled)

            if settings.developerModeEnabled {

                Button("Send Now") {
                    notifications.devSendNow()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Send")
                        .font(.subheadline.bold())

                    HStack {
                        Text("Delay: \(Int(devDelaySeconds))s")
                        Slider(value: $devDelaySeconds, in: 1...60, step: 1)
                    }

                    Button("Send One") {
                        notifications.devSendAfter(seconds: devDelaySeconds)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Batch Send")
                        .font(.subheadline.bold())

                    HStack {
                        Text("Count: \(Int(devBatchCount))")
                        Slider(value: $devBatchCount, in: 1...10, step: 1)
                    }

                    HStack {
                        Text("Within: \(Int(devBatchMinutes))m")
                        Slider(value: $devBatchMinutes, in: 1...30, step: 1)
                    }

                    Button("Send Batch") {
                        notifications.devSendBatch(
                            count: Int(devBatchCount),
                            withinSeconds: devBatchMinutes * 60
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
                .padding(.vertical, 4)

                Button("Clear All Pending", role: .destructive) {
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                }
            }
        } header: {
            Text("Developer")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Memory Items")
                Spacer()
                Text("\(MemoryItemsData.resolved(breakDown: settings.breakDownItems, includeStabilized: settings.includeStabilized).count)")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Source")
                Spacer()
                Text("Frontier A320 – Rev 10 Aug 25")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }
}
