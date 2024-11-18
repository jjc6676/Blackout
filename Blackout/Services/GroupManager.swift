import Foundation
import SwiftUI

@MainActor
class GroupManager: ObservableObject {
    @Published private(set) var groups: [Group] = []
    private let groupsKey = "com.blackout.groups"
    
    init() {
        loadGroups()
        
        // Listen for contact ID changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContactIdChange(_:)),
            name: .contactIdChanged,
            object: nil
        )
    }
    
    @objc private func handleContactIdChange(_ notification: Notification) {
        guard let oldId = notification.userInfo?["oldId"] as? String,
              let newId = notification.userInfo?["newId"] as? String else {
            return
        }
        
        print("Updating groups for contact ID change: \(oldId) -> \(newId)")
        
        // Update all groups that contain this contact
        for index in groups.indices {
            if groups[index].contacts.contains(oldId) {
                groups[index].contacts.removeAll { $0 == oldId }
                groups[index].contacts.append(newId)
                print("Updated contact ID in group: \(groups[index].name)")
            }
        }
        
        saveGroups()
    }
    
    // MARK: - Group Management
    func addGroup(name: String) {
        let newGroup = Group(name: name)
        groups.append(newGroup)
        saveGroups()
        print("Added new group: \(name)")
    }
    
    func updateGroup(_ group: Group) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
            saveGroups()
            print("Updated group: \(group.name)")
        }
    }
    
    func updateGroups(_ newGroups: [Group]) {
        groups = newGroups
        saveGroups()
        print("Updated all groups. New count: \(newGroups.count)")
    }
    
    func renameGroup(_ group: Group, to newName: String) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            var updatedGroup = group
            updatedGroup.name = newName
            groups[index] = updatedGroup
            saveGroups()
            print("Renamed group from \(group.name) to \(newName)")
        }
    }
    
    func deleteGroup(_ group: Group) {
        groups.removeAll { $0.id == group.id }
        saveGroups()
        print("Deleted group: \(group.name)")
    }
    
    // MARK: - Contact Management
    func addContactToGroup(contactId: String, groupId: UUID) {
        if let index = groups.firstIndex(where: { $0.id == groupId }) {
            var group = groups[index]
            if !group.contacts.contains(contactId) {
                group.contacts.append(contactId)
                groups[index] = group
                saveGroups()
                print("Added contact \(contactId) to group \(group.name)")
            }
        }
    }
    
    func removeContactFromGroup(contactId: String, groupId: UUID) {
        if let index = groups.firstIndex(where: { $0.id == groupId }) {
            var group = groups[index]
            group.contacts.removeAll { $0 == contactId }
            groups[index] = group
            saveGroups()
            print("Removed contact \(contactId) from group \(group.name)")
        }
    }
    
    // MARK: - Batch Operations
    func hideAllContactsInGroup(_ group: Group, using contactManager: ContactManager) async {
        print("Starting batch hide for group: \(group.name)")
        for contactId in group.contacts {
            if let contact = contactManager.contacts.first(where: { $0.id == contactId }) {
                do {
                    try await contactManager.toggleHideContact(contact)
                    print("Hidden contact: \(contact.name)")
                } catch {
                    print("Error hiding contact \(contact.name): \(error)")
                }
            }
        }
        print("Completed batch hide for group: \(group.name)")
    }
    
    func unhideAllContactsInGroup(_ group: Group, using contactManager: ContactManager) async {
        print("Starting batch unhide for group: \(group.name)")
        for contactId in group.contacts {
            if let contact = contactManager.hiddenContacts.first(where: { $0.id == contactId }) {
                do {
                    try await contactManager.toggleHideContact(contact)
                    print("Unhidden contact: \(contact.name)")
                } catch {
                    print("Error unhiding contact \(contact.name): \(error)")
                }
            }
        }
        print("Completed batch unhide for group: \(group.name)")
    }
    
    // MARK: - Storage
    private func loadGroups() {
        print("Loading groups...")
        if let data = UserDefaults.standard.data(forKey: groupsKey),
           let loadedGroups = try? JSONDecoder().decode([Group].self, from: data) {
            self.groups = loadedGroups
            print("Groups loaded with details:")
            for group in groups {
                print("Group '\(group.name)' has \(group.contacts.count) contacts:")
                for contactId in group.contacts {
                    print("  - Contact ID: \(contactId)")
                }
            }
        }
    }
    
    private func saveGroups() {
        if let encoded = try? JSONEncoder().encode(groups) {
            UserDefaults.standard.set(encoded, forKey: groupsKey)
            UserDefaults.standard.synchronize()
            print("Groups saved with details:")
            for group in groups {
                print("Group '\(group.name)' has \(group.contacts.count) contacts:")
                for contactId in group.contacts {
                    print("  - Contact ID: \(contactId)")
                }
            }
        }
    }
} 
