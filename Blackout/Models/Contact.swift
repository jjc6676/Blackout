import Foundation

struct Contact: Codable, Identifiable {
    let id: String
    let name: String
    let phoneNumber: String
    var isHidden: Bool
    var dateHidden: Date?
    let givenName: String
    let familyName: String
    let phoneNumbers: [PhoneNumber]
    let emailAddresses: [EmailAddress]
    let postalAddresses: [PostalAddress]
    let birthday: Date?
    let note: String?
    let imageData: Data?
    let thumbnailImageData: Data?
    let socialProfiles: [SocialProfile]
    let urlAddresses: [URLAddress]
    let relations: [Relation]
    
    struct PhoneNumber: Codable {
        let label: String
        let number: String
    }
    
    struct EmailAddress: Codable {
        let label: String
        let email: String
    }
    
    struct PostalAddress: Codable {
        let label: String
        let street: String
        let city: String
        let state: String
        let postalCode: String
        let country: String
    }
    
    struct SocialProfile: Codable {
        let service: String
        let username: String
    }
    
    struct URLAddress: Codable {
        let label: String
        let url: String
    }
    
    struct Relation: Codable {
        let name: String
        let label: String
    }
} 