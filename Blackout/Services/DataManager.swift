import Foundation
import SwiftUI

// First, let's define BackupData structure
struct BackupData: Codable {
    let contacts: [Contact]
    let groups: [Group]
}

@MainActor
class DataManager {
    static let shared = DataManager()
    private init() {}
    
    func createBackup(type: BackupType, groups: [Group], contactManager: ContactManager) async {
        let contacts = contactManager.contacts
        
        // Create BackupData with both contacts and groups
        let backupData = BackupData(contacts: contacts, groups: groups)
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
            throw BackupError.backupNotFound
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

enum BackupError: Error {
    case invalidBackup
    case encodingError
    case decodingError
    case backupNotFound
} 
