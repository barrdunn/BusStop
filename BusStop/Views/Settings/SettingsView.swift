//
//  SettingsView.swift
//  BusStop
//
//  Created by Barry Dunn on 5/1/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {

    @EnvironmentObject var settings: SettingsManager
    @ObservedObject private var folderStore = FolderStore.shared

    @State private var devDelaySeconds: Double = 5
    @State private var devBatchCount: Double = 3
    @State private var devBatchMinutes: Double = 1

    @State private var exportURL: URL? = nil
    @State private var showingImporter = false
    @State private var pendingImportText: String? = nil
    @State private var showingReplaceConfirm = false
    @State private var showingClearConfirm = false
    @State private var importError: String? = nil
    @State private var showingNotificationFolderPicker = false

    private let notifications = NotificationManager.shared

    var body: some View {
        NavigationStack {
            Form {
                notificationSection
                scheduleSection
                dataSection
                developerSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { refreshExportFile() }
            .onChange(of: folderStore.folders) { _, _ in refreshExportFile() }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleImportSelection(result)
        }
        .confirmationDialog(
            "Replace all folders and items with the contents of this CSV? This cannot be undone.",
            isPresented: $showingReplaceConfirm,
            titleVisibility: .visible
        ) {
            Button("Replace All", role: .destructive) {
                performReplaceImport()
            }
            Button("Cancel", role: .cancel) {
                pendingImportText = nil
            }
        }
        .confirmationDialog(
            "Remove every item from every folder? Folders themselves are kept.",
            isPresented: $showingClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear All Items", role: .destructive) {
                folderStore.clearAllItems()
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Import Failed", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section {
            if let url = exportURL {
                ShareLink(item: url) {
                    Label("Export All as CSV", systemImage: "square.and.arrow.up")
                }
            } else {
                Label("Export All as CSV", systemImage: "square.and.arrow.up")
                    .foregroundStyle(.secondary)
            }

            Button {
                showingImporter = true
            } label: {
                Label("Replace All from CSV…", systemImage: "square.and.arrow.down")
            }

            Button(role: .destructive) {
                showingClearConfirm = true
            } label: {
                Label("Clear All Items", systemImage: "trash")
            }
        } header: {
            Text("Data")
        } footer: {
            Text("CSV columns: folder, title, callout, reference, body. Per-folder import is available from each folder.")
        }
    }

    // MARK: - Notification Settings

    private var notificationSection: some View {
        Section {
            Toggle("Enabled", isOn: $settings.notificationsEnabled)
                .onChange(of: settings.notificationsEnabled) { _, _ in
                    notifications.reschedule()
                }

            Stepper("\(settings.notificationCount) \(settings.notificationInterval.label)",
                    value: $settings.notificationCount, in: 1...50)
                .onChange(of: settings.notificationCount) { _, _ in
                    notifications.reschedule()
                }

            Picker("Frequency", selection: $settings.notificationInterval) {
                Text("Per Hour").tag(SettingsManager.NotificationInterval.hour)
                Text("Per Day").tag(SettingsManager.NotificationInterval.day)
                Text("Per Week").tag(SettingsManager.NotificationInterval.week)
            }
            .pickerStyle(.segmented)
            .onChange(of: settings.notificationInterval) { _, _ in
                notifications.reschedule()
            }

            Button {
                showingNotificationFolderPicker = true
            } label: {
                HStack {
                    Label("Folders", systemImage: "folder")
                    Spacer()
                    Text(notificationFolderSummary)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
        } header: {
            Text("Notifications")
        } footer: {
            Text("~\(settings.effectivePerDay) notifications per day between active hours.")
        }
        .sheet(isPresented: $showingNotificationFolderPicker, onDismiss: {
            notifications.reschedule()
        }) {
            FolderSelectionView(
                title: "Notification Folders",
                footer: "Notifications are drawn from items in the selected folders.",
                disabledFolderIDs: $settings.disabledNotificationFolderIDs
            )
        }
    }

    private var notificationFolderSummary: String {
        let total = folderStore.folders.count
        let disabled = settings.disabledNotificationFolderIDs.intersection(Set(folderStore.folders.map { $0.id })).count
        let enabled = total - disabled
        if disabled == 0 { return "All" }
        if enabled == 0 { return "None" }
        return "\(enabled) of \(total)"
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

    // MARK: - Helpers

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    private func refreshExportFile() {
        let csv = CSVService.exportCSV(folders: folderStore.folders)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        let name = "busstop-\(formatter.string(from: Date())).csv"
        exportURL = try? CSVService.writeTempCSV(csv, fileName: name)
    }

    private func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                pendingImportText = try String(contentsOf: url, encoding: .utf8)
                showingReplaceConfirm = true
            } catch {
                importError = error.localizedDescription
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }

    private func performReplaceImport() {
        guard let text = pendingImportText else { return }
        defer { pendingImportText = nil }
        do {
            try CSVService.importReplacingAll(csv: text, into: folderStore)
            refreshExportFile()
        } catch {
            importError = error.localizedDescription
        }
    }
}
