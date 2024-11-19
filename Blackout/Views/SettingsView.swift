import SwiftUI

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @State private var showingPrivacyPolicy = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Data Management")) {
                    NavigationLink("Backups") {
                        BackupsView()
                    }
                }
                
                Section(header: Text("Preferences")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                }
                
                Section(header: Text("About")) {
                    NavigationLink("Privacy Policy") {
                        Text("Privacy Policy Content")
                            .padding()
                    }
                    
                    NavigationLink("Terms of Service") {
                        Text("Terms of Service Content")
                            .padding()
                    }
                    
                    Button("Rate App") {
                        // Link to App Store review
                    }
                }
                
                Section(header: Text("Support")) {
                    NavigationLink("Help Center") {
                        Text("Help Center Content")
                            .padding()
                    }
                    
                    NavigationLink("Contact Us") {
                        Text("Contact Form")
                            .padding()
                    }
                }
                
                Section {
                    Text("Version 1.0.0")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
} 