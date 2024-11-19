import SwiftUI

struct BackupScheduleView: View {
    @ObservedObject var viewModel: BackupViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Schedule Type", selection: $viewModel.backupScheduleType) {
                        Text("None").tag(BackupScheduleType.none)
                        Text("Daily").tag(BackupScheduleType.daily)
                        Text("Weekly").tag(BackupScheduleType.weekly)
                        Text("Custom").tag(BackupScheduleType.custom)
                    }
                    .pickerStyle(.segmented)
                    
                    switch viewModel.backupScheduleType {
                    case .daily:
                        DatePicker("Backup Time",
                                 selection: $viewModel.customBackupTime,
                                 displayedComponents: .hourAndMinute)
                    case .weekly:
                        Picker("Day of Week", selection: $viewModel.weeklyBackupDay) {
                            Text("Sunday").tag(1)
                            Text("Monday").tag(2)
                            Text("Tuesday").tag(3)
                            Text("Wednesday").tag(4)
                            Text("Thursday").tag(5)
                            Text("Friday").tag(6)
                            Text("Saturday").tag(7)
                        }
                        DatePicker("Time",
                                 selection: $viewModel.customBackupTime,
                                 displayedComponents: .hourAndMinute)
                    case .custom:
                        customScheduleView
                    case .none:
                        Text("No automatic backups")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Backup Schedule")
                }
            }
            .navigationTitle("Backup Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.updateSchedule()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var customScheduleView: some View {
        VStack(alignment: .leading) {
            Toggle("Monday", isOn: $viewModel.scheduleSettings.monday)
            Toggle("Tuesday", isOn: $viewModel.scheduleSettings.tuesday)
            Toggle("Wednesday", isOn: $viewModel.scheduleSettings.wednesday)
            Toggle("Thursday", isOn: $viewModel.scheduleSettings.thursday)
            Toggle("Friday", isOn: $viewModel.scheduleSettings.friday)
            Toggle("Saturday", isOn: $viewModel.scheduleSettings.saturday)
            Toggle("Sunday", isOn: $viewModel.scheduleSettings.sunday)
            DatePicker("Time",
                     selection: $viewModel.customBackupTime,
                     displayedComponents: .hourAndMinute)
        }
    }
} 