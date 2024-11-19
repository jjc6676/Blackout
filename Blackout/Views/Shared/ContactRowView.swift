import SwiftUI

struct ContactRowView: View {
    let contact: Contact
    var action: (() -> Void)? = nil
    
    private var displayName: String {
        if contact.name.isEmpty {
            return contact.phoneNumber
        }
        return contact.name
    }
    
    private var displayPhoneNumber: String {
        if contact.phoneNumber.isEmpty {
            return "No phone number"
        }
        return contact.phoneNumber
    }
    
    var body: some View {
        Button(action: { action?() }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(displayName)
                        .font(.headline)
                        .foregroundColor(contact.isHidden ? .secondary : .primary)
                    Text(displayPhoneNumber)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: contact.isHidden ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(contact.isHidden ? .red : .primary)
            }
            .padding(.vertical, 4)
        }
    }
} 