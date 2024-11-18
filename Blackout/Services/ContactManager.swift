import Contacts
import SwiftUI

@MainActor
class ContactManager: ObservableObject {
    @Published private(set) var contacts: [Contact] = []
    @Published private(set) var hiddenContacts: [Contact] = []
    @Published var searchText = ""
    
    private let contactStore = CNContactStore()
    private let hiddenContactsKey = "com.blackout.hiddenContacts"
    private var hasLoadedHidden = false
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { contact in
            contact.name.lowercased().contains(searchText.lowercased()) ||
            contact.phoneNumber.contains(searchText)
        }
    }
    
    init() {
        Task {
            await loadInitialContacts()
        }
    }
    
    private func loadInitialContacts() async {
        do {
            try await loadHiddenContacts()
            try await fetchContacts()
        } catch {
            print("Error loading initial contacts: \(error)")
        }
    }
    
    func fetchContacts() async throws {
        let keys = [
            CNContactGivenNameKey,
            CNContactPhoneNumbersKey,
            CNContactIdentifierKey
        ] as [CNKeyDescriptor]
        
        let request = CNContactFetchRequest(keysToFetch: keys)
        var newContacts: [Contact] = []
        
        // Store existing hidden contacts IDs
        let hiddenContactIds = Set(hiddenContacts.map { $0.id })
        
        try await Task.detached(priority: .userInitiated) { [contactStore] in
            try contactStore.enumerateContacts(with: request) { contact, _ in
                if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
                    let contactId = contact.identifier
                    let isHidden = hiddenContactIds.contains(contactId)
                    
                    let newContact = Contact(
                        id: contactId,
                        name: contact.givenName,
                        phoneNumber: phoneNumber,
                        isHidden: isHidden,
                        dateHidden: isHidden ? Date() : nil
                    )
                    newContacts.append(newContact)
                }
            }
            
            await MainActor.run {
                // Filter out hidden contacts
                self.contacts = newContacts.filter { !hiddenContactIds.contains($0.id) }
                    .sorted { $0.name.lowercased() < $1.name.lowercased() }
                print("Contacts loaded: \(newContacts.count)")
            }
        }.value
    }
    
    private func loadHiddenContacts() {
        print("Loading hidden contacts...")
        if let data = UserDefaults.standard.data(forKey: hiddenContactsKey),
           let loadedContacts = try? JSONDecoder().decode([Contact].self, from: data) {
            self.hiddenContacts = loadedContacts
            print("Loaded \(loadedContacts.count) hidden contacts:")
            for contact in loadedContacts {
                print("  - \(contact.name) (ID: \(contact.id))")
            }
        }
        print("Finished loading hidden contacts")
    }
    
    private func removeFromContactsApp(contact: Contact) async throws {
        print("Removing contact from Contacts app: \(contact.name)")
        let predicate = CNContact.predicateForContacts(withIdentifiers: [contact.id])
        let keysToFetch = [CNContactIdentifierKey] as [CNKeyDescriptor]
        let contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
        
        guard let cnContact = contacts.first else {
            print("Contact not found in Contacts app")
            return
        }
        
        let request = CNSaveRequest()
        request.delete(cnContact.mutableCopy() as! CNMutableContact)
        try contactStore.execute(request)
        print("Successfully removed contact from Contacts app")
    }
    
    func refreshContacts() async throws {
        print("Starting contacts refresh...")
        
        let keys = [
            CNContactGivenNameKey,
            CNContactPhoneNumbersKey,
            CNContactIdentifierKey
        ] as [CNKeyDescriptor]
        
        let request = CNContactFetchRequest(keysToFetch: keys)
        var newContacts: [Contact] = []
        
        // Store existing contacts' hidden status
        let hiddenContactIds = Set(hiddenContacts.map { $0.id })
        
        try await Task.detached(priority: .userInitiated) { [contactStore] in
            try contactStore.enumerateContacts(with: request) { contact, _ in
                if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
                    let contactId = contact.identifier
                    
                    // Preserve hidden status
                    let isHidden = hiddenContactIds.contains(contactId)
                    
                    // Create contact with preserved status
                    let newContact = Contact(
                        id: contactId,
                        name: contact.givenName,
                        phoneNumber: phoneNumber,
                        isHidden: isHidden,
                        dateHidden: isHidden ? Date() : nil
                    )
                    newContacts.append(newContact)
                }
            }
        }.value
        
        await MainActor.run {
            // Important: Only update visible contacts, don't touch hidden ones
            contacts = newContacts.filter { !hiddenContactIds.contains($0.id) }
                .sorted { $0.name.lowercased() < $1.name.lowercased() }
            
            print("Refresh completed - Found \(newContacts.count) contacts")
            print("Visible contacts: \(contacts.count)")
            print("Hidden contacts: \(hiddenContacts.count)")
        }
    }
    
    func toggleHideContact(_ contact: Contact) async throws {
        print("Starting toggleHideContact for \(contact.name) (ID: \(contact.id))")
        
        if contact.isHidden {
            // Unhiding contact - restore to Contacts app
            print("Unhiding contact: \(contact.name) (ID: \(contact.id))")
            let newContactId = try await restoreToContactsApp(contact: contact)
            
            var updatedContact = contact
            updatedContact.isHidden = false
            updatedContact.dateHidden = nil
            updatedContact.id = newContactId
            
            // Update our internal lists
            contacts.append(updatedContact)
            hiddenContacts.removeAll { $0.id == contact.id }
            
            // Update all groups that contained this contact
            NotificationCenter.default.post(
                name: .contactIdChanged,
                object: nil,
                userInfo: [
                    "oldId": contact.id,
                    "newId": newContactId
                ]
            )
            
            print("Contact \(contact.name) restored with new ID: \(newContactId)")
        } else {
            // Hiding contact - remove from Contacts app
            print("Hiding contact: \(contact.name) (ID: \(contact.id))")
            try await removeFromContactsApp(contact: contact)
            
            var updatedContact = contact
            updatedContact.isHidden = true
            updatedContact.dateHidden = Date()
            
            // Update our internal lists
            hiddenContacts.append(updatedContact)
            contacts.removeAll { $0.id == contact.id }
            
            print("Contact \(contact.name) (ID: \(contact.id)) removed from Contacts app and moved to hidden")
        }
        
        try saveHiddenContacts()
        
        await MainActor.run {
            contacts.sort { $0.name.lowercased() < $1.name.lowercased() }
            hiddenContacts.sort { $0.name.lowercased() < $1.name.lowercased() }
        }
    }
    
    private func saveHiddenContacts() throws {
        print("Saving hidden contacts...")
        if let encoded = try? JSONEncoder().encode(hiddenContacts) {
            UserDefaults.standard.set(encoded, forKey: hiddenContactsKey)
            print("Saved \(hiddenContacts.count) hidden contacts:")
            for contact in hiddenContacts {
                print("  - \(contact.name) (ID: \(contact.id))")
            }
        }
        print("Finished saving hidden contacts")
    }
    
    private func restoreToContactsApp(contact: Contact) async throws -> String {
        print("Restoring contact to Contacts app: \(contact.name) (ID: \(contact.id))")
        
        let newContact = CNMutableContact()
        newContact.givenName = contact.name
        let phoneNumber = CNPhoneNumber(stringValue: contact.phoneNumber)
        newContact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: phoneNumber)]
        
        let request = CNSaveRequest()
        request.add(newContact, toContainerWithIdentifier: nil)
        
        try contactStore.execute(request)
        print("New contact created with system ID: \(newContact.identifier)")
        return newContact.identifier
    }
    
    func handleAppBecameActive() {
        Task {
            do {
                try await refreshContacts()
            } catch {
                print("Error refreshing contacts: \(error)")
            }
        }
    }
    
    enum ContactError: Error {
        case deletionFailed
        case restorationFailed
    }
} 