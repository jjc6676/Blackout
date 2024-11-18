import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var contactManager: ContactManager
    @EnvironmentObject private var groupManager: GroupManager
    @State private var showingBackupPicker = false
    @State private var showingRestoreAlert = false
    @State private var backupKey: String?
    
    var body: some View {
        List {
            Section("Backup") {
                Button {
                    Task {
                        await DataManager.shared.createBackup(
                            type: .quick,
                            groups: groupManager.groups,
                            contactManager: contactManager
                        )
                    }
                } label: {
                    Label("Create Backup", systemImage: "square.and.arrow.up")
                }
                
                Button {
                    showingBackupPicker = true
                } label: {
                    Label("Restore Backup", systemImage: "square.and.arrow.down")
                }
            }
            
            Section("About") {
                Link(destination: URL(string: "https://www.example.com/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                
                Link(destination: URL(string: "https://www.example.com/terms")!) {
                    Label("Terms of Service", systemImage: "doc.text")
                }
                
                Label("Version 1.0", systemImage: "info.circle")
            }
        }
        .navigationTitle("Settings")
        .fileImporter(
            isPresented: $showingBackupPicker,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                backupKey = url.lastPathComponent
                showingRestoreAlert = true
            case .failure(let error):
                print("Error selecting backup: \(error)")
            }
        }
        .alert("Restore Backup", isPresented: $showingRestoreAlert) {
            Button("Restore", role: .destructive) {
                if let key = backupKey {
                    Task {
                        try? await DataManager.shared.restoreBackup(
                            key: key,
                            groupManager: groupManager,
                            contactManager: contactManager
                        )
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will replace all your current data. Are you sure?")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
} 