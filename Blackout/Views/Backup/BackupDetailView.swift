import SwiftUI

struct BackupDetailView: View {
    let backup: Backup
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BackupViewModel
    @EnvironmentObject private var contactManager: ContactManager
    @EnvironmentObject private var groupManager: GroupManager
    
    var body: some View {
        NavigationStack {
            BackupPreviewView(backup: backup)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Restore") {
                            viewModel.showingRestoreOptions = true
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .sheet(isPresented: $viewModel.showingRestoreOptions) {
                    RestoreOptionsView(
                        backup: backup,
                        viewModel: viewModel
                    )
                    .environmentObject(contactManager)
                    .environmentObject(groupManager)
                }
                .alert("Backup Alert", isPresented: $viewModel.showAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(viewModel.alertMessage)
                }
        }
        .onAppear {
            viewModel.contactManager = contactManager
            viewModel.groupManager = groupManager
        }
    }
}

struct BackupDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let contactManager = ContactManager()
        let groupManager = GroupManager()
        
        BackupDetailView(
            backup: Backup(
                type: .manual,
                contactCount: 10,
                groupCount: 2,
                data: Data()
            ),
            viewModel: BackupViewModel(
                contactManager: contactManager,
                groupManager: groupManager
            )
        )
        .environmentObject(contactManager)
        .environmentObject(groupManager)
    }
} 