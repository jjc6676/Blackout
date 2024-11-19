import Foundation
import Contacts
import SwiftUI

@MainActor
class ContactManager: ObservableObject {
    @Published private(set) var contacts: [Contact] = []
    @Published private(set) var hiddenContacts: [Contact] = []
    @Published private(set) var filteredContacts: [Contact] = []
    @Published var searchText: String = ""
    @Published private(set) var isLoading = false
    
    private let contactStore = CNContactStore()
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private var hiddenContactsURL: URL {
        documentsDirectory.appendingPathComponent("hiddenContacts.json")
    }
    
    init() {
        createHiddenContactsFileIfNeeded()
        loadHiddenContacts()
        
        Task {
            do {
                try await requestContactsAccess()
            } catch {
                print("Error requesting contact access: \(error)")
            }
        }
    }
    
    private func createHiddenContactsFileIfNeeded() {
        if !FileManager.default.fileExists(atPath: hiddenContactsURL.path) {
            let emptyArray = "[]".data(using: .utf8)!
            try? emptyArray.write(to: hiddenContactsURL)
        }
    }
    
    private func loadHiddenContacts() {
        do {
            let data = try Data(contentsOf: hiddenContactsURL)
            hiddenContacts = try JSONDecoder().decode([Contact].self, from: data)
        } catch {
            print("Error loading hidden contacts: \(error)")
            hiddenContacts = []
        }
    }
    
    private func requestContactsAccess() async throws {
        let granted = try await contactStore.requestAccess(for: .contacts)
        if granted {
            _ = try await refreshContacts()
        } else {
            throw ContactError.accessDenied
        }
    }
    
    func refreshContacts() async throws -> [Contact] {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactIdentifierKey,
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactPostalAddressesKey,
            CNContactBirthdayKey,
            CNContactImageDataKey,
            CNContactThumbnailImageDataKey,
            CNContactUrlAddressesKey
        ] as [CNKeyDescriptor]
        
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        var contacts: [Contact] = []
        
        try await withCheckedThrowingContinuation { continuation in
            do {
                try contactStore.enumerateContacts(with: request) { contact, stop in
                    let newContact = Contact(
                        id: contact.identifier,
                        name: "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces),
                        phoneNumber: contact.phoneNumbers.first?.value.stringValue ?? "",
                        isHidden: false,
                        dateHidden: nil,
                        givenName: contact.givenName,
                        familyName: contact.familyName,
                        phoneNumbers: contact.phoneNumbers.map { 
                            Contact.PhoneNumber(
                                label: $0.label ?? "other",
                                number: $0.value.stringValue
                            )
                        },
                        emailAddresses: contact.emailAddresses.map { 
                            Contact.EmailAddress(
                                label: $0.label ?? "other",
                                email: $0.value as String
                            )
                        },
                        postalAddresses: contact.postalAddresses.map {
                            Contact.PostalAddress(
                                label: $0.label ?? "other",
                                street: $0.value.street,
                                city: $0.value.city,
                                state: $0.value.state,
                                postalCode: $0.value.postalCode,
                                country: $0.value.country
                            )
                        },
                        birthday: contact.birthday?.date,
                        note: nil,
                        imageData: contact.imageData,
                        thumbnailImageData: contact.thumbnailImageData,
                        socialProfiles: [],
                        urlAddresses: contact.urlAddresses.map {
                            Contact.URLAddress(
                                label: $0.label ?? "other",
                                url: $0.value as String
                            )
                        },
                        relations: []
                    )
                    contacts.append(newContact)
                }
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
        
        self.contacts = contacts.filter { contact in
            !hiddenContacts.contains { hiddenContact in 
                hiddenContact.id == contact.id 
            }
        }
        updateFilteredContacts()
        
        return contacts
    }
    
    func updateFilteredContacts() {
        if searchText.isEmpty {
            filteredContacts = contacts
        } else {
            filteredContacts = contacts.filter { contact in
                contact.name.localizedCaseInsensitiveContains(searchText) ||
                contact.phoneNumber.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func toggleHideContact(_ contact: Contact) async throws {
        var updatedContact = contact
        updatedContact.isHidden = !contact.isHidden
        updatedContact.dateHidden = updatedContact.isHidden ? Date() : nil
        
        if updatedContact.isHidden {
            hiddenContacts.append(updatedContact)
            contacts.removeAll { $0.id == contact.id }
        } else {
            contacts.append(updatedContact)
            hiddenContacts.removeAll { $0.id == contact.id }
        }
        
        // Save hidden contacts to disk
        let encoder = JSONEncoder()
        let data = try encoder.encode(hiddenContacts)
        try data.write(to: hiddenContactsURL)
        
        // Update filtered contacts
        updateFilteredContacts()
        
        // Post notification for other views to update
        NotificationCenter.default.post(
            name: .contactVisibilityChanged,
            object: nil,
            userInfo: ["contact": contact]
        )
    }
}

enum ContactError: LocalizedError {
    case accessDenied
    case contactNotFound
    case restorationFailed
    case deletionFailed
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access to contacts was denied"
        case .contactNotFound:
            return "Contact not found"
        case .restorationFailed:
            return "Failed to restore contact"
        case .deletionFailed:
            return "Failed to delete contact"
        }
    }
}

extension Notification.Name {
    static let contactVisibilityChanged = Notification.Name("contactVisibilityChanged")
} 