import Foundation

struct Contact: Identifiable, Hashable, Codable {
    var id: String
    let name: String
    let phoneNumber: String
    var isHidden: Bool
    var dateHidden: Date?
    var maskedName: String?
    var maskedPhoneNumber: String?
    
    var displayName: String {
        isHidden ? (maskedName ?? "Hidden Contact") : name
    }
    
    var displayPhoneNumber: String {
        isHidden ? (maskedPhoneNumber ?? "••••••••••") : phoneNumber
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.id == rhs.id
    }
} 