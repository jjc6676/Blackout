import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {}
    
    func scheduleBackupReminder(at date: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Scheduled Backup"
        content.body = "Starting backup"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "dailyBackup",
            content: content,
            trigger: trigger
        )
        
        try? await notificationCenter.add(request)
    }
    
    func scheduleWeeklyBackup(day: Int, time: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Scheduled Backup"
        content.body = "Starting weekly backup"
        
        var components = Calendar.current.dateComponents([.hour, .minute], from: time)
        components.weekday = day
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weeklyBackup",
            content: content,
            trigger: trigger
        )
        
        try? await notificationCenter.add(request)
    }
    
    func scheduleCustomBackup(settings: ScheduleSettings, time: Date) async {
        // Remove existing notifications
        notificationCenter.removeAllPendingNotificationRequests()
        
        // Schedule new notifications for each selected day
        let days = settings.selectedDays
        for day in days {
            let content = UNMutableNotificationContent()
            content.title = "Scheduled Backup"
            content.body = "Starting custom backup"
            
            var components = Calendar.current.dateComponents([.hour, .minute], from: time)
            components.weekday = day
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "customBackup_\(day)",
                content: content,
                trigger: trigger
            )
            
            try? await notificationCenter.add(request)
        }
    }
    
    func cancelAllBackupReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func sendBackupSuccessNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Backup Complete"
        content.body = "Your data has been successfully backed up"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        try? await notificationCenter.add(request)
    }
    
    func sendRestoreSuccessNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Restore Complete"
        content.body = "Your data has been successfully restored"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        try? await notificationCenter.add(request)
    }
    
    func sendRestoreFailureNotification(error: Error) async {
        let content = UNMutableNotificationContent()
        content.title = "Restore Failed"
        content.body = "Failed to restore backup: \(error.localizedDescription)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        try? await notificationCenter.add(request)
    }
} 