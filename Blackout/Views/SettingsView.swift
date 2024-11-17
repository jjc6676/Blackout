import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var contactManager: ContactManager
    @State private var showingNewGroupSheet = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Contact Groups") {
                    NavigationLink(destination: GroupsView()) {
                        HStack {
                            Image(systemName: "folder.fill")
                            Text("Manage Groups")
                        }
                    }
                }
                
                Section("App Settings") {
                    // Placeholder for future settings
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "app.badge.fill")
                            Text("App Icon")
                        }
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "bell.fill")
                            Text("Notifications")
                        }
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "lock.fill")
                            Text("Privacy & Security")
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
} 