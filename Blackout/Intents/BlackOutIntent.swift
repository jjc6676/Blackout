import AppIntents
import SwiftUI

struct BlackOutIntent: AppIntent {
    static var title: LocalizedStringResource = "BlackOut Contact"
    static var description: IntentDescription = IntentDescription("Hide or show a contact")
    
    @Parameter(title: "Contact Identifier")
    var contactIdentifier: String
    
    @Parameter(title: "Contact Name")
    var contactName: String
    
    init() {}
    
    init(contactIdentifier: String, contactName: String) {
        self.contactIdentifier = contactIdentifier
        self.contactName = contactName
    }
    
    func perform() async throws -> some IntentResult {
        // Here we'll add the actual blackout logic later
        return .result()
    }
} 