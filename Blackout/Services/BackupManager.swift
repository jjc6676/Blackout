import Foundation
import Contacts
import SwiftUI

class BackupManager {
    static let shared = BackupManager()
    private let contactStore = CNContactStore()
    
    // MARK: - Backup Creation
    func createBackup(type: BackupType = .manual) async throws -> Backup {
        let contacts = try await fetchAllContacts()
        let groups: [Group] = [] // Explicitly typed empty array
        let settings: [String: String] = [:] // implement settings backup
        
        let backupData = BackupData(
            contacts: contacts,
            groups: groups,
            settings: settings,
            type: type
        )
        
        // Convert to Data
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(backupData)
        
        // Create Backup
        return Backup(
            type: type,
            contactCount: contacts.count,
            groupCount: groups.count,
            data: encodedData
        )
    }
    
    private func fetchAllContacts() async throws -> [Contact] {
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
            CNContactUrlAddressesKey,
            CNContactNoteKey,
            CNContactSocialProfilesKey,
            CNContactRelationsKey
        ] as [CNKeyDescriptor]
        
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        var contacts: [Contact] = []
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try contactStore.enumerateContacts(with: request) { contact, _ in
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
                        note: contact.note,
                        imageData: contact.imageData,
                        thumbnailImageData: contact.thumbnailImageData,
                        socialProfiles: [],  // Initialize as empty array since we're not fetching these
                        urlAddresses: contact.urlAddresses.map {
                            Contact.URLAddress(
                                label: $0.label ?? "other",
                                url: $0.value as String
                            )
                        },
                        relations: []  // Initialize as empty array since we're not fetching these
                    )
                    contacts.append(newContact)
                }
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
        
        return contacts
    }
    
    // MARK: - Backup Restoration
    func restore(_ backup: Backup, options: RestoreOptions) async throws {
        // Decode backup data
        guard let backupData = try? JSONDecoder().decode(BackupData.self, from: backup.data) else {
            throw BackupError.storageError("Failed to decode backup data")
        }
        
        // Check if we need to restore contacts
        if options.contains(.contacts) {
            // Request contact access if needed
            let authStatus = CNContactStore.authorizationStatus(for: .contacts)
            if authStatus != .authorized {
                let granted = try await contactStore.requestAccess(for: .contacts)
                guard granted else {
                    throw BackupError.contactAccessDenied
                }
            }
            
            // Create save request
            let saveRequest = CNSaveRequest()
            
            // Process each contact
            for contactData in backupData.contacts {
                let contact = CNMutableContact()
                
                // Basic info (only keep what exists in Contact model)
                contact.givenName = contactData.givenName
                contact.familyName = contactData.familyName
                
                // Phone numbers
                contact.phoneNumbers = contactData.phoneNumbers.map {
                    CNLabeledValue(label: $0.label, value: CNPhoneNumber(stringValue: $0.number))
                }
                
                // Email addresses
                contact.emailAddresses = contactData.emailAddresses.map {
                    CNLabeledValue(label: $0.label, value: $0.email as NSString)
                }
                
                // Postal addresses
                contact.postalAddresses = contactData.postalAddresses.map {
                    let address = CNMutablePostalAddress()
                    address.street = $0.street
                    address.city = $0.city
                    address.state = $0.state
                    address.postalCode = $0.postalCode
                    address.country = $0.country
                    return CNLabeledValue(label: $0.label, value: address)
                }
                
                // Birthday
                if let birthday = contactData.birthday {
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.year, .month, .day], from: birthday)
                    contact.birthday = components
                }
                
                // Note
                if let note = contactData.note {
                    contact.note = note
                }
                
                // Images
                if let imageData = contactData.imageData {
                    contact.imageData = imageData
                }
                
                // Social profiles
                contact.socialProfiles = contactData.socialProfiles.map {
                    CNLabeledValue(
                        label: nil,
                        value: CNSocialProfile(
                            urlString: nil,
                            username: $0.username,
                            userIdentifier: nil,
                            service: $0.service
                        )
                    )
                }
                
                // URLs
                contact.urlAddresses = contactData.urlAddresses.map {
                    CNLabeledValue(label: $0.label, value: $0.url as NSString)
                }
                
                // Relations
                contact.contactRelations = contactData.relations.map {
                    CNLabeledValue(
                        label: $0.label,
                        value: CNContactRelation(name: $0.name)
                    )
                }
                
                // Add contact to save request
                saveRequest.add(contact, toContainerWithIdentifier: nil)
            }
            
            // Execute save request
            try contactStore.execute(saveRequest)
        }
    }
    
    // MARK: - Backup Preview
    func getPreviewData(for backup: Backup) async throws -> BackupPreviewData {
        // Create a decoder
        let decoder = JSONDecoder()
        
        // Decode the backup data
        let backupData: BackupData
        do {
            backupData = try decoder.decode(BackupData.self, from: backup.data)
        } catch {
            throw BackupError.storageError("Failed to decode backup data: \(error.localizedDescription)")
        }
        
        // Convert settings dictionary to array of BackupSetting
        let settings = backupData.settings.map { key, value in
            BackupSetting(key: key, value: value)
        }
        
        // Create and return the preview data
        return BackupPreviewData(
            contacts: backupData.contacts,
            groups: backupData.groups,
            settings: settings
        )
    }
}

// MARK: - Error Types
enum BackupError: LocalizedError {
    case storageError(String)
    case contactAccessDenied
    
    var errorDescription: String? {
        switch self {
        case .storageError(let details):
            return "Storage error: \(details)"
        case .contactAccessDenied:
            return "Contact access was denied"
        }
    }
} 
