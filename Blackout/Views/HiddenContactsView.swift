import SwiftUI

struct HiddenContactsView: View {
    @EnvironmentObject private var contactManager: ContactManager
    @EnvironmentObject private var groupManager: GroupManager
    @State private var selectedContact: Contact?
    
    var hiddenContacts: [(Contact, [String])] {
        contactManager.filteredContacts
            .filter { $0.isHidden }
            .map { contact in
                // Find groups that contain this contact
                let groupNames = groupManager.groups
                    .filter { $0.contacts.contains(contact.id) }
                    .map { $0.name }
                return (contact, groupNames)
            }
            .sorted { $0.0.name.lowercased() < $1.0.name.lowercased() }
    }
    
    var body: some View {
        NavigationView {
            List {
                if hiddenContacts.isEmpty {
                    Text("No hidden contacts")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(hiddenContacts, id: \.0.id) { contact, groupNames in
                        VStack(alignment: .leading, spacing: 4) {
                            HiddenContactRow(contact: contact)
                            if !groupNames.isEmpty {
                                Text("Groups: \(groupNames.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Individual contact")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedContact = contact
                        }
                    }
                }
            }
            .searchable(text: $contactManager.searchText, prompt: "Search hidden contacts")
            .navigationTitle("Hidden Contacts")
            .sheet(item: $selectedContact) { contact in
                BlackOutActionSheet(contact: contact)
            }
        }
    }
}

struct HiddenContactRow: View {
    let contact: Contact
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(contact.displayName)
                .font(.headline)
            Text(contact.displayPhoneNumber)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    HiddenContactsView()
        .environmentObject(ContactManager())
} 