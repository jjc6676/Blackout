import SwiftUI
import Foundation

struct RestoreOptionsView: View {
    let backup: Backup
    @ObservedObject var viewModel: BackupViewModel
    @EnvironmentObject private var contactManager: ContactManager
    @EnvironmentObject private var groupManager: GroupManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOptions: RestoreOptions = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Contacts", isOn: makeBinding(.contacts))
                    Toggle("Groups", isOn: makeBinding(.groups))
                    Toggle("Settings", isOn: makeBinding(.settings))
                } header: {
                    Text("Choose what to restore")
                } footer: {
                    Text("This will restore selected items from your backup.")
                }
            }
            .navigationTitle("Restore Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Restore") {
                        Task {
                            await viewModel.restoreSelectively(backup, options: selectedOptions)
                            dismiss()
                        }
                    }
                    .disabled(selectedOptions.isEmpty)
                }
            }
        }
        .onAppear {
            viewModel.contactManager = contactManager
            viewModel.groupManager = groupManager
        }
    }
    
    private func makeBinding(_ option: RestoreOptions) -> Binding<Bool> {
        Binding(
            get: { selectedOptions.contains(option) },
            set: { isSelected in
                if isSelected {
                    selectedOptions.insert(option)
                } else {
                    selectedOptions.remove(option)
                }
            }
        )
    }
}

struct RestoreOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        RestoreOptionsView(
            backup: Backup(
                type: .manual,
                contactCount: 10,
                groupCount: 2,
                data: Data()
            ),
            viewModel: BackupViewModel(
                contactManager: ContactManager(),
                groupManager: GroupManager()
            )
        )
        .environmentObject(ContactManager())
        .environmentObject(GroupManager())
    }
} 