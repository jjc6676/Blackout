import SwiftUI

struct GroupsView: View {
    @EnvironmentObject private var groupManager: GroupManager
    @EnvironmentObject private var contactManager: ContactManager
    @State private var showingAddGroup = false
    @State private var showingRenameGroup = false
    @State private var selectedGroup: Group?
    @State private var newGroupName = ""
    
    var sortedGroups: [Group] {
        groupManager.groups.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    var body: some View {
        List {
            ForEach(sortedGroups) { group in
                NavigationLink {
                    GroupDetailView(group: group)
                } label: {
                    Label(group.name, systemImage: "folder")
                }
                .contextMenu {
                    Button {
                        selectedGroup = group
                        newGroupName = group.name
                        showingRenameGroup = true
                    } label: {
                        Label("Rename Group", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        groupManager.deleteGroup(group)
                    } label: {
                        Label("Delete Group", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Groups")
        .toolbar {
            Button(action: { showingAddGroup = true }) {
                Label("Add Group", systemImage: "folder.badge.plus")
            }
        }
        .alert("New Group", isPresented: $showingAddGroup) {
            TextField("Group Name", text: $newGroupName)
            Button("Cancel", role: .cancel) {
                newGroupName = ""
            }
            Button("Create") {
                if !newGroupName.isEmpty {
                    groupManager.addGroup(name: newGroupName)
                    newGroupName = ""
                }
            }
        }
        .alert("Rename Group", isPresented: $showingRenameGroup) {
            TextField("Group Name", text: $newGroupName)
            Button("Cancel", role: .cancel) {
                newGroupName = ""
                selectedGroup = nil
            }
            Button("Rename") {
                if let group = selectedGroup, !newGroupName.isEmpty {
                    groupManager.renameGroup(group, to: newGroupName)
                    newGroupName = ""
                    selectedGroup = nil
                }
            }
        }
    }
}

struct GroupDetailView: View {
    @EnvironmentObject private var contactManager: ContactManager
    @EnvironmentObject private var groupManager: GroupManager
    @State private var showingContactSelection = false
    @State private var contactToToggle: Contact?
    @State private var showingHideConfirmation = false
    
    let group: Group
    
    var currentGroup: Group {
        groupManager.groups.first(where: { $0.id == group.id }) ?? group
    }
    
    var groupedContacts: [Contact] {
        currentGroup.contacts.compactMap { contactId in
            contactManager.contacts.first(where: { $0.id == contactId }) ??
            contactManager.hiddenContacts.first(where: { $0.id == contactId })
        }.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    var body: some View {
        List {
            if !groupedContacts.isEmpty {
                Section {
                    Button {
                        Task {
                            await groupManager.hideAllContactsInGroup(currentGroup, using: contactManager)
                        }
                    } label: {
                        HStack {
                            Label("Hide All Contacts", systemImage: "eye.slash")
                            Spacer()
                            Text("\(groupedContacts.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.red)
                    
                    Button {
                        Task {
                            await groupManager.unhideAllContactsInGroup(currentGroup, using: contactManager)
                        }
                    } label: {
                        Label("Unhide All Contacts", systemImage: "eye")
                    }
                } header: {
                    Text("Batch Actions")
                }
            }
            
            Section {
                if groupedContacts.isEmpty {
                    ContentUnavailableView(
                        "No Contacts",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text("Tap the + button to add contacts to this group")
                    )
                } else {
                    ForEach(groupedContacts) { contact in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(contact.name)
                                    .foregroundColor(contact.isHidden ? .secondary : .primary)
                                Text(contact.phoneNumber)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Menu {
                                Button {
                                    contactToToggle = contact
                                    showingHideConfirmation = true
                                } label: {
                                    Label(contact.isHidden ? "Unhide Contact" : "Hide Contact", 
                                          systemImage: contact.isHidden ? "eye" : "eye.slash")
                                }
                                
                                Button(role: .destructive) {
                                    groupManager.removeContactFromGroup(contactId: contact.id, groupId: currentGroup.id)
                                } label: {
                                    Label("Remove from Group", systemImage: "person.crop.circle.badge.minus")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundColor(.accentColor)
                            }
                            
                            Circle()
                                .fill(contact.isHidden ? Color.red : Color.green)
                                .frame(width: 12, height: 12)
                        }
                    }
                }
            } header: {
                Text("Contacts")
            }
        }
        .navigationTitle(currentGroup.name)
        .toolbar {
            Button(action: { showingContactSelection = true }) {
                Label("Add Contact", systemImage: "person.crop.circle.badge.plus")
            }
        }
        .sheet(isPresented: $showingContactSelection) {
            ContactSelectionView(group: currentGroup)
        }
        .alert(contactToToggle?.isHidden == true ? "Unhide Contact?" : "Hide Contact?", 
               isPresented: $showingHideConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button(contactToToggle?.isHidden == true ? "Unhide" : "Hide", 
                   role: contactToToggle?.isHidden == true ? .none : .destructive) {
                if let contact = contactToToggle {
                    Task {
                        try? await contactManager.toggleHideContact(contact)
                    }
                }
            }
        } message: {
            if let contact = contactToToggle {
                Text(contact.isHidden ? 
                     "This contact will be restored to your Contacts app." :
                     "This contact will be hidden from your Contacts app.")
            }
        }
    }
}
 