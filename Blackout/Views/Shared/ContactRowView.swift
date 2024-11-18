import SwiftUI

struct ContactRowView: View {
    let contact: Contact
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(contact.displayName)
                        .font(.headline)
                        .foregroundColor(contact.isHidden ? .secondary : .primary)
                    Text(contact.displayPhoneNumber)
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