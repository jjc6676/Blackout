import SwiftUI

enum SortOption: String, CaseIterable, Identifiable {
    case name = "Name"
    case dateHidden = "Date Hidden"
    case phoneNumber = "Phone Number"
    
    var id: String { self.rawValue }
}

enum SearchFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case name = "Name"
    case phone = "Phone"
    
    var id: String { self.rawValue }
}

struct HiddenContactsToolbar: ToolbarContent {
    @Binding var sortOption: SortOption
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                ForEach(SortOption.allCases) { option in
                    Button(option.rawValue) {
                        sortOption = option
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
        }
    }
}

struct HiddenContactsView: View {
    @EnvironmentObject private var contactManager: ContactManager
    @EnvironmentObject private var groupManager: GroupManager
    @State private var searchText = ""
    @State private var contactToUnhide: Contact?
    @State private var showingUnhideConfirmation = false
    @State private var showingBatchUnhideConfirmation = false
    
    var sortedContacts: [String: [Contact]] {
        Dictionary(grouping: contactManager.hiddenContacts) { contact in
            String(contact.name.prefix(1).uppercased())
        }.mapValues { contacts in
            contacts.sorted { $0.name.lowercased() < $1.name.lowercased() }
        }
    }
    
    var sortedSections: [String] {
        sortedContacts.keys.sorted()
    }
    
    var body: some View {
        List {
            if !contactManager.hiddenContacts.isEmpty {
                Section {
                    Button {
                        showingBatchUnhideConfirmation = true
                    } label: {
                        HStack {
                            Label("Unhide All Contacts", systemImage: "eye")
                            Spacer()
                            Text("\(contactManager.hiddenContacts.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Batch Actions")
                }
            }
            
            if contactManager.hiddenContacts.isEmpty {
                ContentUnavailableView(
                    "No Hidden Contacts",
                    systemImage: "eye.slash",
                    description: Text("Contacts you hide will appear here")
                )
            } else {
                ForEach(sortedSections, id: \.self) { section in
                    Section(header: Text(section)) {
                        ForEach(sortedContacts[section] ?? []) { contact in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(contact.name)
                                        .font(.headline)
                                    Spacer()
                                    Text(contact.dateHidden?.formatted() ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text(contact.phoneNumber)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if !contactGroups(for: contact).isEmpty {
                                    Text("In \(contactGroups(for: contact).count) groups")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                contactToUnhide = contact
                                showingUnhideConfirmation = true
                            }
                            .contextMenu {
                                if !contactGroups(for: contact).isEmpty {
                                    Button {
                                        Task {
                                            await unhideFromAllGroups(contact)
                                        }
                                    } label: {
                                        Label("Unhide from All Groups", systemImage: "eye")
                                    }
                                }
                                
                                Button {
                                    contactToUnhide = contact
                                    showingUnhideConfirmation = true
                                } label: {
                                    Label("Unhide Contact", systemImage: "eye")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Hidden Contacts")
        .alert("Unhide Contact?", isPresented: $showingUnhideConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Unhide") {
                if let contact = contactToUnhide {
                    Task {
                        do {
                            try await contactManager.toggleHideContact(contact)
                            print("Successfully unhid contact: \(contact.name)")
                        } catch {
                            print("Error unhiding contact: \(error)")
                        }
                    }
                }
            }
        } message: {
            Text("This contact will be restored to your Contacts app.")
        }
        .alert("Unhide All Contacts?", isPresented: $showingBatchUnhideConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Unhide All") {
                Task {
                    await unhideAllContacts()
                }
            }
        } message: {
            Text("This will restore all hidden contacts to your Contacts app.")
        }
    }
    
    private func contactGroups(for contact: Contact) -> [Group] {
        groupManager.groups.filter { $0.contacts.contains(contact.id) }
    }
    
    private func unhideFromAllGroups(_ contact: Contact) async {
        print("Starting unhideFromAllGroups for contact: \(contact.id)")
        
        do {
            try await contactManager.toggleHideContact(contact)
            print("Contact \(contact.name) unhidden successfully")
        } catch {
            print("Error unhiding contact \(contact.name): \(error.localizedDescription)")
        }
    }
    
    private func unhideAllContacts() async {
        print("Starting batch unhide for all contacts")
        for contact in contactManager.hiddenContacts {
            do {
                try await contactManager.toggleHideContact(contact)
                print("Unhidden contact: \(contact.name)")
            } catch {
                print("Error unhiding contact \(contact.name): \(error)")
            }
        }
        print("Completed batch unhide")
    }
}

struct EmptyStateView: View {
    let searchText: String
    let totalHidden: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: searchText.isEmpty ? "eye.slash.circle.fill" : "magnifyingglass.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            if searchText.isEmpty {
                if totalHidden == 0 {
                    Text("No Hidden Contacts")
                        .font(.headline)
                    Text("Contacts you hide will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("No Hidden Contacts")
                        .font(.headline)
                }
            } else {
                Text("No Results")
                    .font(.headline)
                Text("No hidden contacts match '\(searchText)'")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowBackground(Color.clear)
        .padding()
    }
}

struct HiddenContactRow: View {
    let contact: Contact
    @EnvironmentObject private var contactManager: ContactManager
    @EnvironmentObject private var groupManager: GroupManager
    @State private var showingActionSheet = false
    
    var contactGroups: [Group] {
        groupManager.groups.filter { $0.contacts.contains(contact.id) }
    }
    
    var hiddenSource: String {
        if contactGroups.isEmpty {
            return "Hidden individually"
        }
        let names = contactGroups.map { $0.name }
        let joinedNames = names.joined(separator: ", ")
        return "Hidden via group: \(joinedNames)"
    }
    
    var body: some View {
        Button {
            showingActionSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(contact.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(contact.phoneNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let dateHidden = contact.dateHidden {
                    Text("Hidden on \(dateHidden.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text(hiddenSource)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .confirmationDialog("Unhide Contact", isPresented: $showingActionSheet) {
            Button("Unhide Contact", role: .destructive) {
                Task {
                    try? await contactManager.toggleHideContact(contact)
                }
            }
            
            if !contactGroups.isEmpty {
                Button("Unhide and Remove from Groups", role: .destructive) {
                    Task {
                        await unhideFromAllGroups()
                        // Only remove from groups if explicitly chosen
                        for group in contactGroups {
                            var updatedGroup = group
                            updatedGroup.contacts.removeAll { $0 == contact.id }
                            groupManager.updateGroup(updatedGroup)
                            print("Removed contact from group: \(group.name)")
                        }
                    }
                }
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(contact.name)
        }
    }
    
    private func unhideFromAllGroups() async {
        print("Starting unhideFromAllGroups for contact: \(contact.id)")
        
        // Just unhide the contact - don't modify groups
        do {
            try await contactManager.toggleHideContact(contact)
            print("Contact unhidden successfully")
        } catch {
            print("Error unhiding contact: \(error.localizedDescription)")
        }
    }
}

struct StatisticsView: View {
    let hiddenContacts: [Contact]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                StatCard(title: "Total Hidden", value: "\(hiddenContacts.count)")
                if let lastHidden = hiddenContacts.first(where: { $0.dateHidden != nil })?.dateHidden {
                    StatCard(title: "Last Hidden", value: lastHidden.formatted(date: .abbreviated, time: .shortened))
                }
            }
        }
        .padding()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

#Preview {
    NavigationStack {
        HiddenContactsView()
            .environmentObject(ContactManager())
            .environmentObject(GroupManager())
    }
} 