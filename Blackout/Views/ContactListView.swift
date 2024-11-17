import SwiftUI

struct ContactListView: View {
    @EnvironmentObject private var contactManager: ContactManager
    @State private var showingPermissionAlert = false
    @State private var selectedContact: Contact?
    
    var visibleContacts: [Contact] {
        contactManager.filteredContacts.filter { !$0.isHidden }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(visibleContacts) { contact in
                    ContactRow(contact: contact) {
                        selectedContact = contact
                    }
                }
            }
            .searchable(text: $contactManager.searchText, prompt: "Search contacts")
            .navigationTitle("Contacts")
            .task {
                do {
                    let authorized = try await contactManager.requestAccess()
                    if authorized {
                        try await contactManager.fetchContacts()
                    } else {
                        showingPermissionAlert = true
                    }
                } catch {
                    print("Error: \(error)")
                }
            }
            .alert("Contacts Permission Required", isPresented: $showingPermissionAlert) {
                Button("OK", role: .cancel) { }
            }
            .sheet(item: $selectedContact) { contact in
                BlackOutActionSheet(contact: contact)
            }
        }
    }
}

struct BlackOutActionSheet: View {
    let contact: Contact
    @EnvironmentObject private var contactManager: ContactManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Name: \(contact.displayName)")
                    Text("Phone: \(contact.displayPhoneNumber)")
                }
                
                Section {
                    Button(contact.isHidden ? "UnBlackOut Contact" : "BlackOut Contact") {
                        showingConfirmation = true
                    }
                    .foregroundColor(contact.isHidden ? .green : .red)
                }
            }
            .navigationTitle("Contact Actions")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .alert(contact.isHidden ? "Restore Contact?" : "Hide Contact?", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button(contact.isHidden ? "Restore" : "Hide") {
                    Task {
                        do {
                            try await contactManager.toggleBlackOut(for: contact)
                            dismiss()
                        } catch {
                            print("Error toggling blackout: \(error)")
                        }
                    }
                }
            } message: {
                if contact.isHidden {
                    Text("This contact will be restored to your Contacts app.")
                } else {
                    Text("This contact will be hidden from your Contacts app.")
                }
            }
        }
    }
}

struct ContactRow: View {
    let contact: Contact
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(contact.displayName)
                        .font(.headline)
                    Text(contact.displayPhoneNumber)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: contact.isHidden ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(contact.isHidden ? .red : .primary)
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    ContactListView()
        .environmentObject(ContactManager())
} 