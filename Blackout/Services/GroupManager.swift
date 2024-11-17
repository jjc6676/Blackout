import Foundation

class GroupManager: ObservableObject {
    @Published private(set) var groups: [Group] = []
    private let groupsKey = "com.blackout.groups"
    
    var sortedGroups: [Group] {
        groups.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    init() {
        loadGroups()
    }
    
    func addGroup(_ group: Group) {
        groups.append(group)
        saveGroups()
    }
    
    func updateGroup(_ group: Group) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
            saveGroups()
        }
    }
    
    func deleteGroup(at offsets: IndexSet) {
        groups.remove(atOffsets: offsets)
        saveGroups()
    }
    
    func addContactToGroup(contactId: String, groupId: UUID) {
        if let index = groups.firstIndex(where: { $0.id == groupId }) {
            var group = groups[index]
            if !group.contacts.contains(contactId) {
                group.contacts.append(contactId)
                groups[index] = group
                saveGroups()
            }
        }
    }
    
    func removeContactFromGroup(contactId: String, groupId: UUID) {
        if let index = groups.firstIndex(where: { $0.id == groupId }) {
            var group = groups[index]
            group.contacts.removeAll(where: { $0 == contactId })
            groups[index] = group
            saveGroups()
        }
    }
    
    private func saveGroups() {
        if let encoded = try? JSONEncoder().encode(groups) {
            UserDefaults.standard.set(encoded, forKey: groupsKey)
        }
    }
    
    private func loadGroups() {
        if let data = UserDefaults.standard.data(forKey: groupsKey),
           let decoded = try? JSONDecoder().decode([Group].self, from: data) {
            groups = decoded
        }
    }
} 