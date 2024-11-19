import SwiftUI
import Contacts

struct ContactListView: View {
    @EnvironmentObject private var contactManager: ContactManager
    @EnvironmentObject private var groupManager: GroupManager
    @State private var showingPermissionAlert = false
    @State private var selectedContact: Contact?
    @State private var showingActionSheet = false
    
    var body: some View {
        List {
            ForEach(contactManager.filteredContacts) { contact in
                ContactRow(contact: contact)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedContact = contact
                        showingActionSheet = true
                    }
            }
        }
        .searchable(text: $contactManager.searchText)
        .navigationTitle("Contacts")
        .refreshable {
            Task {
                try? await contactManager.refreshContacts()
            }
        }
        .alert("Contact Access Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings", role: .none) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please grant access to your contacts in Settings to use this feature.")
        }
        .confirmationDialog("Contact Actions", isPresented: $showingActionSheet, presenting: selectedContact) { contact in
            Button("Hide Contact") {
                Task {
                    do {
                        try await contactManager.toggleHideContact(contact)
                    } catch {
                        print("Error hiding contact: \(error)")
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .overlay {
            if contactManager.isLoading {
                ProgressView()
            }
        }
        .onAppear {
            Task {
                try? await contactManager.refreshContacts()
            }
        }
    }
}

struct ContactRow: View {
    let contact: Contact
    @EnvironmentObject private var groupManager: GroupManager
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(contact.name)
                .font(.headline)
            if !contact.phoneNumber.isEmpty {
                Text(contact.phoneNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if !contactGroups.isEmpty {
                GroupTagsView(groups: contactGroups)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var contactGroups: [Group] {
        groupManager.groups.filter { $0.contacts.contains(contact.id) }
    }
}

struct GroupTagsView: View {
    let groups: [Group]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(groups) { group in
                    Text(group.name)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
    }
}

#Preview {
    ContactListView()
        .environmentObject(ContactManager())
} 