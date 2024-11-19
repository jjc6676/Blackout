import SwiftUI

struct BackupSummaryRow: View {
    let backup: Backup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(backup.type == .quick ? "Quick Backup" : "Full Backup")
                    .font(.headline)
                Spacer()
                Text(backup.displayDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("\(backup.contactCount) contacts", systemImage: "person.2")
                Spacer()
                Label("\(backup.groupCount) groups", systemImage: "folder")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    BackupSummaryRow(backup: Backup(
        type: .quick,
        contactCount: 10,
        groupCount: 2,
        data: Data()
    ))
    .padding()
} 