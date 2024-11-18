import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ContactListView()
            }
            .tabItem {
                Label("Contacts", systemImage: "person.circle")
            }
            
            NavigationStack {
                HiddenContactsView()
            }
            .tabItem {
                Label("Hidden", systemImage: "eye.slash")
            }
            
            NavigationStack {
                GroupsView()
            }
            .tabItem {
                Label("Groups", systemImage: "folder")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

#Preview {
    ContentView()
} 