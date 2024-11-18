import Foundation

public enum BackupType: String, Codable {
    case quick
    case full
}

public struct Backup: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let type: BackupType
    public let contactCount: Int
    public let groupCount: Int
    public let data: Data
    
    public init(id: UUID = UUID(), 
         date: Date = Date(), 
         type: BackupType, 
         contactCount: Int, 
         groupCount: Int, 
         data: Data) {
        self.id = id
        self.date = date
        self.type = type
        self.contactCount = contactCount
        self.groupCount = groupCount
        self.data = data
    }
}

// Optional: Add convenience methods if needed
extension Backup {
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 