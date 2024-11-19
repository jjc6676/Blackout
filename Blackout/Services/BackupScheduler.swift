import Foundation
import BackgroundTasks

enum BackupFrequency {
    case daily(hour: Int, minute: Int)
    case weekly(weekday: Int, hour: Int, minute: Int)
    case monthly(day: Int, hour: Int, minute: Int)
    
    func nextBackupDate() -> Date {
        // Implementation for calculating next backup date
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .daily(let hour, let minute):
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = hour
            components.minute = minute
            guard let date = calendar.date(from: components) else { return now }
            return date > now ? date : calendar.date(byAdding: .day, value: 1, to: date)!
            
        case .weekly(let weekday, let hour, let minute):
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            components.weekday = weekday
            components.hour = hour
            components.minute = minute
            guard let date = calendar.date(from: components) else { return now }
            return date > now ? date : calendar.date(byAdding: .weekOfYear, value: 1, to: date)!
            
        case .monthly(let day, let hour, let minute):
            var components = calendar.dateComponents([.year, .month], from: now)
            components.day = day
            components.hour = hour
            components.minute = minute
            guard let date = calendar.date(from: components) else { return now }
            return date > now ? date : calendar.date(byAdding: .month, value: 1, to: date)!
        }
    }
}

struct BackupConditions {
    let requiresWifi: Bool
    let requiresPower: Bool
}

class BackupScheduler {
    static let shared = BackupScheduler()
    
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.app.backup",
            using: nil
        ) { task in
            self.handleBackgroundTask(task as! BGProcessingTask)
        }
    }
    
    private func handleBackgroundTask(_ task: BGProcessingTask) {
        task.expirationHandler = {
            // Clean up if task expires
        }
        
        // Perform backup
        Task {
            do {
                _ = try await BackupManager.shared.createBackup()
                task.setTaskCompleted(success: true)
            } catch {
                print("Backup failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    func scheduleBackup(frequency: BackupFrequency, conditions: BackupConditions) async throws {
        let request = BGProcessingTaskRequest(identifier: "com.app.backup")
        request.requiresNetworkConnectivity = conditions.requiresWifi
        request.requiresExternalPower = conditions.requiresPower
        request.earliestBeginDate = frequency.nextBackupDate()
        
        try BGTaskScheduler.shared.submit(request)
    }
} 