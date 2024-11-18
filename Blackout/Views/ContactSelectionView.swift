import SwiftUI

struct ContactSelectionView: View {
    let group: Group
    @EnvironmentObject private var contactManager: ContactManager
    @EnvironmentObject private var groupManager: GroupManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredContacts: [Contact] {
        let contacts = contactManager.contacts.filter { !group.contacts.contains($0.id) }
        let sortedContacts = contacts.sorted { $0.name.lowercased() < $1.name.lowercased() }
        
        if searchText.isEmpty {
            return sortedContacts
        }
        return sortedContacts.filter { contact in
            contact.name.lowercased().contains(searchText.lowercased()) ||
            contact.phoneNumber.contains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            List(filteredContacts) { contact in
                ContactRowView(contact: contact) {
                    groupManager.addContactToGroup(contactId: contact.id, groupId: group.id)
                    dismiss()
                }
            }
            .searchable(text: $searchText, prompt: "Search contacts")
            .navigationTitle("Add Contact")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
} 