import Contacts
import LocalAuthentication
import Combine

class ContactManager: ObservableObject {
    @Published private(set) var contacts: [Contact] = []
    @Published var searchText: String = ""
    
    private let contactStore = CNContactStore()
    private let keychainManager = KeychainManager.shared
    private let hiddenContactsKey = "com.blackout.hiddenContacts"
    
    var filteredContacts: [Contact] {
        let sortedContacts = contacts.sorted { $0.name.lowercased() < $1.name.lowercased() }
        if searchText.isEmpty {
            return sortedContacts
        }
        return sortedContacts.filter { contact in
            contact.name.lowercased().contains(searchText.lowercased()) ||
            contact.phoneNumber.contains(searchText)
        }
    }
    
    func requestAccess() async throws -> Bool {
        try await contactStore.requestAccess(for: .contacts)
    }
    
    func fetchContacts() async throws {
        let keysToFetch = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey
        ] as [CNKeyDescriptor]
        
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        
        var fetchedContacts: [Contact] = []
        try contactStore.enumerateContacts(with: request) { contact, _ in
            let phoneNumber = contact.phoneNumbers.first?.value.stringValue ?? ""
            fetchedContacts.append(Contact(
                id: contact.identifier,
                name: "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces),
                phoneNumber: phoneNumber,
                isHidden: false
            ))
        }
        
        DispatchQueue.main.async {
            self.contacts = fetchedContacts
            self.loadHiddenContacts()
        }
    }
    
    func toggleBlackOut(for contact: Contact) async throws {
        var updatedContact = contact
        updatedContact.isHidden.toggle()
        
        if updatedContact.isHidden {
            updatedContact.maskedName = "Hidden Contact \(Int.random(in: 1000...9999))"
            updatedContact.maskedPhoneNumber = String(repeating: "•", count: 10)
            try await removeFromContactsApp(contactId: contact.id)
        } else {
            try await restoreToContactsApp(contact: contact)
        }
        
        if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
            DispatchQueue.main.async {
                self.contacts[index] = updatedContact
            }
        }
        
        try saveHiddenContacts()
    }
    
    private func removeFromContactsApp(contactId: String) async throws {
        let keysToFetch = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey
        ] as [CNKeyDescriptor]
        
        let predicate = CNContact.predicateForContacts(withIdentifiers: [contactId])
        
        let contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
        guard let contact = contacts.first else { return }
        
        let request = CNSaveRequest()
        request.delete(contact.mutableCopy() as! CNMutableContact)
        
        try contactStore.execute(request)
    }
    
    private func restoreToContactsApp(contact: Contact) async throws {
        let mutableContact = CNMutableContact()
        
        let nameComponents = contact.name.components(separatedBy: " ")
        mutableContact.givenName = nameComponents.first ?? ""
        if nameComponents.count > 1 {
            mutableContact.familyName = nameComponents.dropFirst().joined(separator: " ")
        }
        
        let phoneNumber = CNPhoneNumber(stringValue: contact.phoneNumber)
        let phoneNumberValue = CNLabeledValue(label: CNLabelHome, value: phoneNumber)
        mutableContact.phoneNumbers = [phoneNumberValue]
        
        let request = CNSaveRequest()
        request.add(mutableContact, toContainerWithIdentifier: nil)
        
        try contactStore.execute(request)
    }
    
    private func saveHiddenContacts() throws {
        let hiddenContacts = contacts.filter { $0.isHidden }
        let encoder = JSONEncoder()
        let data = try encoder.encode(hiddenContacts)
        try keychainManager.save(data, service: hiddenContactsKey, account: "blackout")
    }
    
    private func loadHiddenContacts() {
        do {
            let data = try keychainManager.load(service: hiddenContactsKey, account: "blackout")
            let decoder = JSONDecoder()
            let hiddenContacts = try decoder.decode([Contact].self, from: data)
            
            for hiddenContact in hiddenContacts {
                if let index = contacts.firstIndex(where: { $0.id == hiddenContact.id }) {
                    contacts[index] = hiddenContact
                }
            }
        } catch {
            print("No hidden contacts found or error loading: \(error)")
        }
    }
} 