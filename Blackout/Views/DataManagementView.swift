import SwiftUI

struct BackupInfo {
    let backup: Backup
    let type: BackupType
    let date: Date
    let contactCount: Int
    let groupCount: Int
}

struct DataManagementView: View {
    @EnvironmentObject private var contactManager: ContactManager
    @EnvironmentObject private var groupManager: GroupManager
    @State private var backups: [Backup] = []
    @State private var isProcessingBackup = false
    @State private var backupToRestore: Backup?
    @State private var alertMessage = ""
    @State private var presentationState: PresentationState = .none
    
    enum PresentationState {
        case none
        case alert
        case confirmRestore
    }
    
    var body: some View {
        List {
            Section {
                Button {
                    handleBackup(type: BackupType.quick, groups: groupManager.groups)
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("Quick Backup")
                    }
                }
                .disabled(isProcessingBackup)
                
                Button {
                    handleBackup(type: BackupType.full, groups: groupManager.groups)
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("Full Backup")
                    }
                }
                .disabled(isProcessingBackup)
            } header: {
                Text("Create Backup")
            } footer: {
                Text("Quick backup saves only hidden contacts. Full backup includes all contacts and groups.")
            }
            
            if !backups.isEmpty {
                Section {
                    ForEach(backups) { backup in
                        BackupRow(backup: backup) {
                            backupToRestore = backup
                            presentationState = .confirmRestore
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            await deleteBackups(at: indexSet)
                        }
                    }
                } header: {
                    Text("Previous Backups")
                }
            }
        }
        .navigationTitle("Backup & Restore")
        .task {
            await loadBackups()
        }
        .alert("Backup", isPresented: $presentationState.isAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Restore Backup", isPresented: $presentationState.isConfirmRestore) {
            Button("Restore", role: .destructive) {
                Task {
                    await restoreBackup()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will restore your contacts to the state they were in when this backup was created. Are you sure you want to continue?")
        }
    }
    
    private func handleBackup(type: BackupType, groups: [Group]) {
        isProcessingBackup = true
        presentationState = .none
        
        Task {
            await DataManager.shared.createBackup(
                type: type,
                groups: groups,
                contactManager: contactManager
            )
            await loadBackups()
            alertMessage = "Backup created successfully"
            isProcessingBackup = false
            
            DispatchQueue.main.async {
                presentationState = .alert
            }
        }
    }
    
    private func loadBackups() async {
        backups = DataManager.shared.getAllBackups()
    }
    
    private func deleteBackups(at indexSet: IndexSet) async {
        for index in indexSet {
            let backup = backups[index]
            DataManager.shared.deleteBackup(withId: backup.id.uuidString)
        }
        await loadBackups()
    }
    
    private func restoreBackup() async {
        guard let backup = backupToRestore else { return }
        do {
            try await DataManager.shared.restoreBackup(
                key: backup.id.uuidString,
                groupManager: groupManager,
                contactManager: contactManager
            )
            alertMessage = "Backup restored successfully"
            presentationState = .alert
        } catch {
            alertMessage = "Failed to restore backup: \(error.localizedDescription)"
            presentationState = .alert
        }
        backupToRestore = nil
    }
}

extension DataManagementView.PresentationState {
    var isAlert: Bool {
        get { self == .alert }
        set { if !newValue { self = .none } }
    }
    
    var isConfirmRestore: Bool {
        get { self == .confirmRestore }
        set { if !newValue { self = .none } }
    }
}

struct BackupRow: View {
    let backup: Backup
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                Text(backup.type == .quick ? "Quick Backup" : "Full Backup")
                    .font(.headline)
                Text(backup.displayDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(backup.contactCount) contacts, \(backup.groupCount) groups")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
