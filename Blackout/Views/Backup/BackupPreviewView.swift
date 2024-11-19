import SwiftUI

struct BackupPreviewView: View {
    let backup: Backup
    @EnvironmentObject private var contactManager: ContactManager
    @EnvironmentObject private var groupManager: GroupManager
    @State private var previewData: BackupPreviewData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Backup Preview")
        }
        .task {
            await loadPreviewData()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView("Loading preview...")
        } else if let error = errorMessage {
            Text(error)
                .foregroundColor(.red)
        } else if let data = previewData {
            List {
                Section(header: Text("Contacts")) {
                    ForEach(data.contacts) { contact in
                        ContactPreviewRow(contact: contact)
                    }
                }
                
                Section(header: Text("Groups")) {
                    ForEach(data.groups) { group in
                        GroupPreviewRow(group: group)
                    }
                }
                
                if !data.settings.isEmpty {
                    Section(header: Text("Settings")) {
                        ForEach(data.settings) { setting in
                            SettingPreviewRow(setting: setting)
                        }
                    }
                }
            }
        }
    }
    
    private func loadPreviewData() async {
        do {
            previewData = try await BackupManager.shared.getPreviewData(for: backup)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct ContactPreviewRow: View {
    let contact: Contact
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(contact.name)
                .font(.headline)
            Text(contact.phoneNumber)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct GroupPreviewRow: View {
    let group: Group
    
    var body: some View {
        Text(group.name)
    }
}

struct SettingPreviewRow: View {
    let setting: BackupSetting
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(setting.key)
                .font(.headline)
            Text(setting.value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// Preview provider
struct BackupPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        BackupPreviewView(
            backup: Backup(
                type: .manual,
                contactCount: 10,
                groupCount: 2,
                data: Data()
            )
        )
        .environmentObject(ContactManager())
        .environmentObject(GroupManager())
    }
} 