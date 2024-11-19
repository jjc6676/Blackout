import SwiftUI

struct BackupsView: View {
    @EnvironmentObject private var contactManager: ContactManager
    @EnvironmentObject private var groupManager: GroupManager
    @StateObject private var viewModel: BackupViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: BackupViewModel(
            contactManager: ContactManager(),  // Temporary instance
            groupManager: GroupManager()       // Temporary instance
        ))
    }
    
    var body: some View {
        List {
            Section {
                Button {
                    Task {
                        await viewModel.performQuickBackup()
                    }
                } label: {
                    Label("Quick Backup", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isProcessingBackup)
                
                Button {
                    Task {
                        await viewModel.performFullBackup()
                    }
                } label: {
                    Label("Full Backup", systemImage: "arrow.up.circle")
                }
                .disabled(viewModel.isProcessingBackup)
                
                NavigationLink {
                    BackupScheduleView(viewModel: viewModel)
                } label: {
                    Label("Backup Settings", systemImage: "gear")
                }
            } header: {
                Text("Backup Options")
            } footer: {
                Text("Quick backup saves your essential contacts. Full backup includes all contacts from your Contacts app.")
            }
            
            if !viewModel.backups.isEmpty {
                Section {
                    ForEach(viewModel.backups) { backup in
                        BackupSummaryRow(backup: backup)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectedBackup = backup
                                viewModel.showingBackupDetail = true
                            }
                    }
                    .onDelete { indexSet in
                        Task {
                            await viewModel.deleteBackups(at: indexSet)
                        }
                    }
                } header: {
                    Text("Backup History")
                }
            }
        }
        .navigationTitle("Backups")
        .alert("Backup Alert", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
        .sheet(isPresented: $viewModel.showingBackupDetail) {
            if let backup = viewModel.selectedBackup {
                BackupDetailView(backup: backup, viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.contactManager = contactManager
            viewModel.groupManager = groupManager
        }
    }
} 