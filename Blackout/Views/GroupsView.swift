import SwiftUI

struct Group: Identifiable, Codable {
    let id: UUID
    var name: String
    var contacts: [String] // Contact IDs
    
    init(id: UUID = UUID(), name: String, contacts: [String] = []) {
        self.id = id
        self.name = name
        self.contacts = contacts
    }
}

struct GroupContactRow: View {
    let contact: Contact
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(contact.name)
                    .font(.headline)
                Text(contact.phoneNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct NewGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var groupName: String
    let onCreate: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Group Name", text: $groupName)
                    .focused($isTextFieldFocused)
            }
            .navigationTitle("New Group")
            .navigationBarItems(
                leading: Button("Cancel") {
                    groupName = ""
                    dismiss()
                },
                trailing: Button("Create") {
                    onCreate()
                }
                .disabled(groupName.isEmpty)
            )
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
}

struct GroupsView: View {
    @EnvironmentObject private var groupManager: GroupManager
    @State private var isAddingGroup = false
    @State private var newGroupName = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        List {
            if isAddingGroup {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        TextField("Group Name", text: $newGroupName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isTextFieldFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                if !newGroupName.isEmpty {
                                    createGroup()
                                }
                            }
                    }
                    
                    HStack(spacing: 15) {
                        Button(action: {
                            isAddingGroup = false
                            newGroupName = ""
                        }) {
                            Text("Cancel")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .tint(.gray)
                        
                        Button(action: createGroup) {
                            Text("Create Group")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newGroupName.isEmpty)
                    }
                }
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color(uiColor: .systemBackground))
            }
            
            if groupManager.groups.isEmpty && !isAddingGroup {
                Text("No groups created")
                    .foregroundColor(.secondary)
            } else {
                ForEach(groupManager.sortedGroups) { group in
                    NavigationLink(destination: GroupDetailView(group: group)) {
                        HStack(spacing: 12) {
                            Image(systemName: "folder.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(group.name)
                                    .font(.headline)
                                Text("\(group.contacts.count) contacts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: groupManager.deleteGroup)
            }
        }
        .navigationTitle("Groups")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        isAddingGroup = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isTextFieldFocused = true
                        }
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .disabled(isAddingGroup)
            }
        }
    }
    
    private func createGroup() {
        withAnimation {
            let newGroup = Group(name: newGroupName.trimmingCharacters(in: .whitespaces))
            groupManager.addGroup(newGroup)
            newGroupName = ""
            isAddingGroup = false
        }
    }
}

struct GroupDetailView: View {
    @EnvironmentObject private var contactManager: ContactManager
    @EnvironmentObject private var groupManager: GroupManager
    @State private var showingContactSelection = false
    @State private var showingBatchActionSheet = false
    let group: Group
    
    var groupContacts: [Contact] {
        contactManager.contacts.filter { group.contacts.contains($0.id) }
    }
    
    var allContactsHidden: Bool {
        !groupContacts.isEmpty && groupContacts.allSatisfy { $0.isHidden }
    }
    
    var body: some View {
        List {
            if groupContacts.isEmpty {
                Text("No contacts in group")
                    .foregroundColor(.secondary)
            } else {
                Section {
                    Button(action: { showingBatchActionSheet = true }) {
                        HStack {
                            Image(systemName: allContactsHidden ? "eye.fill" : "eye.slash.fill")
                            Text(allContactsHidden ? "Unhide All Contacts" : "Hide All Contacts")
                            Spacer()
                            Text("\(groupContacts.count) contacts")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(allContactsHidden ? .green : .red)
                }
                
                Section {
                    ForEach(groupContacts) { contact in
                        GroupContactRow(contact: contact)
                    }
                    .onDelete(perform: removeContacts)
                }
            }
        }
        .navigationTitle(group.name)
        .toolbar {
            Button("Add Contacts") {
                showingContactSelection = true
            }
        }
        .sheet(isPresented: $showingContactSelection) {
            ContactSelectionView(group: group) { selectedContactIds in
                for contactId in selectedContactIds {
                    groupManager.addContactToGroup(contactId: contactId, groupId: group.id)
                }
            }
        }
        .confirmationDialog(
            allContactsHidden ? "Unhide All Contacts?" : "Hide All Contacts?",
            isPresented: $showingBatchActionSheet,
            titleVisibility: .visible
        ) {
            Button(allContactsHidden ? "Unhide All" : "Hide All", role: allContactsHidden ? .none : .destructive) {
                Task {
                    await toggleGroupContacts()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(allContactsHidden ? 
                "All contacts in this group will be restored to your Contacts app." :
                "All contacts in this group will be hidden from your Contacts app."
            )
        }
    }
    
    private func removeContacts(at offsets: IndexSet) {
        offsets.forEach { index in
            let contact = groupContacts[index]
            groupManager.removeContactFromGroup(contactId: contact.id, groupId: group.id)
        }
    }
    
    private func toggleGroupContacts() async {
        for contact in groupContacts {
            if contact.isHidden != allContactsHidden {
                continue // Skip contacts that are already in the desired state
            }
            do {
                try await contactManager.toggleBlackOut(for: contact)
            } catch {
                print("Error toggling contact \(contact.name): \(error)")
            }
        }
    }
} 