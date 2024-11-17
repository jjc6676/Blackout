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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(contactManager)
        }
    }
}
