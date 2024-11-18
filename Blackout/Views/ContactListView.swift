import SwiftUI
import Contacts

struct ContactListView: View {
    @EnvironmentObject private var contactManager: ContactManager
    @EnvironmentObject private var groupManager: GroupManager
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var showingPermissionAlert = false
    @State private var selectedContact: Contact?
    @State private var showingActionSheet = false
    
    var filteredContacts: [String: [Contact]] {
        let filtered = searchText.isEmpty ? contactManager.contacts :
            contactManager.contacts.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.phoneNumber.contains(searchText)
            }
        return Dictionary(grouping: filtered) { String($0.name.prefix(1).uppercased()) }
    }
    
    var sortedSections: [String] {
        filteredContacts.keys.sorted()
    }
    
    var body: some View {
        List {
            if contactManager.contacts.isEmpty {
                ContentUnavailableView(
                    "No Contacts",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text("Grant access to your contacts or add some in the Contacts app")
                )
            } else {
                ForEach(sortedSections, id: \.self) { section in
                    Section(header: Text(section)) {
                        ForEach(filteredContacts[section] ?? []) { contact in
                            Button {
                                selectedContact = contact
                                showingActionSheet = true
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(contact.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(contact.phoneNumber)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search contacts")
        .navigationTitle("Contacts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await refreshContacts()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .task {
            await loadContacts()
        }
        .alert("Contact Access Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please grant access to your contacts in Settings.")
        }
        .confirmationDialog("Hide Contact?", isPresented: $showingActionSheet) {
            if let contact = selectedContact {
                Button("Hide Contact", role: .destructive) {
                    Task {
                        try? await contactManager.toggleHideContact(contact)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let contact = selectedContact {
                Text(contact.name)
            }
        }
    }
    
    private func loadContacts() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await Task.detached(priority: .userInitiated) {
                try await contactManager.fetchContacts()
            }.value
        } catch {
            print("Error loading contacts: \(error)")
            showingPermissionAlert = true
        }
    }
    
    private func refreshContacts() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await contactManager.refreshContacts()
            print("Contacts refreshed successfully")
        } catch {
            print("Error refreshing contacts: \(error)")
        }
    }
}

#Preview {
    ContactListView()
        .environmentObject(ContactManager())
} 