import Foundation

// MARK: - Core Types
public enum BackupType: String, Codable {
    case quick
    case full
    case manual
    case scheduled
}

public enum BackupScheduleType: String, Codable {
    case daily
    case weekly
    case custom
    case none
}

// MARK: - Backup Model
public struct Backup: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let type: BackupType
    public let contactCount: Int
    public let groupCount: Int
    public let data: Data
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: BackupType,
        contactCount: Int,
        groupCount: Int,
        data: Data
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.contactCount = contactCount
        self.groupCount = groupCount
        self.data = data
    }
    
    public var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Data Models
public struct BackupData: Codable {
    let contacts: [Contact]
    let groups: [Group]
    let settings: [String: String]
    let type: BackupType
}

public struct BackupPreviewData {
    let contacts: [Contact]
    let groups: [Group]
    let settings: [BackupSetting]
}

public struct BackupSetting: Identifiable {
    public let id: UUID
    public let key: String
    public let value: String
    
    public init(key: String, value: String, id: UUID = UUID()) {
        self.id = id
        self.key = key
        self.value = value
    }
}

// MARK: - Options
public struct RestoreOptions: OptionSet {
    public let rawValue: Int
    
    public static let contacts = RestoreOptions(rawValue: 1 << 0)
    public static let groups = RestoreOptions(rawValue: 1 << 1)
    public static let settings = RestoreOptions(rawValue: 1 << 2)
    
    public static let all: RestoreOptions = [.contacts, .groups, .settings]
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public struct ContactBackupData: Codable {
    let identifier: String
    let givenName: String
    let familyName: String
    let phoneNumbers: [PhoneNumber]
    let emailAddresses: [Email]
    let postalAddresses: [PostalAddress]
    let birthday: Date?
    let notes: String?
    
    struct PhoneNumber: Codable {
        let label: String
        let number: String
    }
    
    struct Email: Codable {
        let label: String
        let address: String
    }
    
    struct PostalAddress: Codable {
        let label: String
        let street: String
        let city: String
        let state: String
        let postalCode: String
        let country: String
    }
} 