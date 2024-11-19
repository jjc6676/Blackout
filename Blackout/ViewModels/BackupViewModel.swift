import Foundation
import SwiftUI

@MainActor
class BackupViewModel: ObservableObject {
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showingBackupDetail = false
    @Published var showingSchedulePicker = false
    @Published var showingRestoreOptions = false
    @Published var selectedBackup: Backup?
    @Published var backups: [Backup] = []
    @Published var isProcessingBackup = false
    @Published var progress: Double = 0
    @Published var currentOperation: String = ""
    
    // Schedule-related properties
    @Published var backupScheduleType: BackupScheduleType = .none
    @Published var customBackupTime = Date()
    @Published var weeklyBackupDay = 1  // Sunday = 1, Saturday = 7
    @Published var scheduleSettings = ScheduleSettings()
    
    private let backupManager: BackupManager
    private let notificationManager: NotificationManager
    private let dataManager: DataManager
    @ObservedObject var contactManager: ContactManager
    @ObservedObject var groupManager: GroupManager
    
    init(contactManager: ContactManager, groupManager: GroupManager) {
        self.backupManager = BackupManager.shared
        self.notificationManager = NotificationManager.shared
        self.dataManager = DataManager.shared
        self.contactManager = contactManager
        self.groupManager = groupManager
        Task {
            await loadBackups()
        }
    }
    
    func performQuickBackup() async {
        isProcessingBackup = true
        do {
            let backup = try await backupManager.createBackup(type: .quick)
            dataManager.saveBackup(backup)
            await loadBackups()
            showAlert = true
            alertMessage = "Quick backup created successfully"
        } catch {
            showAlert = true
            alertMessage = "Backup failed: \(error.localizedDescription)"
        }
        isProcessingBackup = false
    }
    
    func performFullBackup() async {
        isProcessingBackup = true
        progress = 0
        currentOperation = "Creating backup..."
        
        do {
            let backup = try await backupManager.createBackup(type: .full)
            dataManager.saveBackup(backup)
            await loadBackups()
            showAlert = true
            alertMessage = "Full backup created successfully"
        } catch {
            showAlert = true
            alertMessage = "Backup failed: \(error.localizedDescription)"
        }
        
        isProcessingBackup = false
    }
    
    func deleteBackups(at indexSet: IndexSet) async {
        for index in indexSet {
            let backup = backups[index]
            dataManager.deleteBackup(withId: backup.id.uuidString)
        }
        await loadBackups()
    }
    
    func restoreSelectively(_ backup: Backup, options: RestoreOptions) async {
        do {
            try await backupManager.restore(backup, options: options)
            await notificationManager.sendRestoreSuccessNotification()
            showAlert = true
            alertMessage = "Backup restored successfully"
        } catch {
            await notificationManager.sendRestoreFailureNotification(error: error)
            showAlert = true
            alertMessage = "Failed to restore backup: \(error.localizedDescription)"
        }
    }
    
    private func loadBackups() async {
        backups = dataManager.getAllBackups()
    }
    
    func updateSchedule() {
        Task {
            switch backupScheduleType {
            case .daily:
                await notificationManager.scheduleBackupReminder(at: customBackupTime)
            case .weekly:
                await notificationManager.scheduleWeeklyBackup(day: weeklyBackupDay, time: customBackupTime)
            case .custom:
                await notificationManager.scheduleCustomBackup(settings: scheduleSettings, time: customBackupTime)
            case .none:
                notificationManager.cancelAllBackupReminders()
            }
        }
    }
} 