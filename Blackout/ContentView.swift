//
//  ContentView.swift
//  Blackout
//
//  Created by Jason Choplin on 11/17/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var contactManager = ContactManager()
    @StateObject private var groupManager = GroupManager()
    
    var body: some View {
        TabView {
            ContactListView()
                .tabItem {
                    Label("Contacts", systemImage: "person.fill")
                }
            
            HiddenContactsView()
                .tabItem {
                    Label("Hidden", systemImage: "eye.slash.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environmentObject(contactManager)
        .environmentObject(groupManager)
    }
}

#Preview {
    ContentView()
}
