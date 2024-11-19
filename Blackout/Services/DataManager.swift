import Foundation
import SwiftUI
import Contacts

// Define AppError enum directly in this file
enum AppError: Error {
    // Backup related errors
    case invalidBackup
    case encodingError
    case decodingError
    case backupNotFound
    
    // Contact related errors
    case restorationFailed
    case deletionFailed
    case accessDenied
}

@MainActor
class DataManager {
    static let shared = DataManager()
    private init() {}
    
    func createBackup(type: BackupType, groups: [Group], contactManager: ContactManager) async {
        let contacts = contactManager.contacts
        
        // Get current settings
        let settings = UserDefaults.standard.dictionaryRepresentation()
            .filter { $0.key.hasPrefix("backup") }
            .mapValues { "\($0)" }
        
        // Create BackupData with all required parameters
        let backupData = BackupData(
            contacts: contacts,
            groups: groups,
            settings: settings,
            type: type
        )
        
        guard let encodedData = try? JSONEncoder().encode(backupData) else { return }
        
        let backup = Backup(
            type: type,
            contactCount: contacts.count,
            groupCount: groups.count,
            data: encodedData
        )
        
        if let encoded = try? JSONEncoder().encode(backup) {
            UserDefaults.standard.set(encoded, forKey: backup.id.uuidString)
        }
    }
    
    func saveBackup(_ backup: Backup) {
        if let encoded = try? JSONEncoder().encode(backup) {
            UserDefaults.standard.set(encoded, forKey: backup.id.uuidString)
        }
    }
    
    func getAllBackups() -> [Backup] {
        let defaults = UserDefaults.standard
        return defaults.dictionaryRepresentation()
            .keys
            .compactMap { key -> Backup? in
                guard let data = defaults.data(forKey: key),
                      let backup = try? JSONDecoder().decode(Backup.self, from: data) else {
                    return nil
                }
                return backup
            }
            .filter { $0.date > Date().addingTimeInterval(-30 * 24 * 60 * 60) } // Keep last 30 days
            .sorted { $0.date > $1.date }
    }
    
    func deleteBackup(withId id: String) {
        UserDefaults.standard.removeObject(forKey: id)
    }
    
    func restoreBackup(key: String, groupManager: GroupManager, contactManager: ContactManager) async throws {
        // Get all backups and find the one we want
        let allBackups = getAllBackups()
        guard let backup = allBackups.first(where: { $0.id.uuidString == key }) else {
            throw AppError.backupNotFound
        }
        
        let decoder = JSONDecoder()
        let backupData = try decoder.decode(BackupData.self, from: backup.data)
        
        // First restore contacts
        for contact in backupData.contacts {
            if contact.isHidden {
                do {
                    try await contactManager.toggleHideContact(contact)
                } catch {
                    print("Error restoring contact \(contact.name): \(error)")
                }
            }
        }
        
        // Then update groups
        groupManager.updateGroups(backupData.groups)
        print("Backup restored: \(backupData.contacts.count) contacts, \(backupData.groups.count) groups")
    }
}
