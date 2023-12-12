//
//  InstantMessagingApp.swift
//  InstantMessaging
//
//  Created by Timothy on 5/12/23.
//

import SwiftData
import SwiftUI

@main
struct InstantMessagingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [User.self, ChatMessage.self])
    }
}
