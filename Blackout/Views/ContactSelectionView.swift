import SwiftUI

struct ContactSelectionView: View {
    @EnvironmentObject private var contactManager: ContactManager
    @Environment(\.dismiss) private var dismiss
    let group: Group
    let onContactsSelected: ([String]) -> Void
    
    @State private var selectedContacts = Set<String>()
    @State private var searchText = ""
    
    var filteredContacts: [Contact] {
        let contacts = contactManager.contacts
            .filter { !$0.isHidden }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
        
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { contact in
            contact.name.lowercased().contains(searchText.lowercased()) ||
            contact.phoneNumber.contains(searchText)
        }
    }
    
    var groupedContacts: [(String, [Contact])] {
        Dictionary(grouping: filteredContacts) { contact in
            String(contact.name.prefix(1).uppercased())
        }
        .sorted { $0.key < $1.key }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(groupedContacts, id: \.0) { section in
                    Section(header: Text(section.0)) {
                        ForEach(section.1) { contact in
                            ContactSelectionRow(
                                contact: contact,
                                isSelected: selectedContacts.contains(contact.id)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedContacts.contains(contact.id) {
                                    selectedContacts.remove(contact.id)
                                } else {
                                    selectedContacts.insert(contact.id)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search contacts")
            .navigationTitle("Add Contacts")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Add (\(selectedContacts.count))") {
                    onContactsSelected(Array(selectedContacts))
                    dismiss()
                }
                .disabled(selectedContacts.isEmpty)
            )
        }
    }
}

struct ContactSelectionRow: View {
    let contact: Contact
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(contact.name)
                    .font(.headline)
                Text(contact.phoneNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.title3)
        }
        .padding(.vertical, 4)
    }
} 