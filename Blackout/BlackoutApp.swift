//
//  BlackoutApp.swift
//  Blackout
//
//  Created by Jason Choplin on 11/17/24.
//

import SwiftUI

@main
struct BlackoutApp: App {
    @StateObject private var contactManager = ContactManager()
    @StateObject private var groupManager = GroupManager()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(contactManager)
                .environmentObject(groupManager)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        Task {
                            try? await contactManager.refreshContacts()
                        }
                    }
                }
        }
    }
}
