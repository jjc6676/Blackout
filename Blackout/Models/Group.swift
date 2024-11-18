import Foundation

struct Group: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var contacts: [String]
    
    init(id: UUID = UUID(), name: String, contacts: [String] = []) {
        self.id = id
        self.name = name
        self.contacts = contacts
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Group, rhs: Group) -> Bool {
        lhs.id == rhs.id
    }
} 