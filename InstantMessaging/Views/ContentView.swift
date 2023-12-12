//
//  ContentView.swift
//  InstantMessaging
//
//  Created by Timothy on 5/12/23.
//

import SwiftUI
import Starscream
import SwiftStomp

struct ContentView: View {
    private var stomp = StompManager()
    @State var isLoggedIn = false
    @State var senderNickName = "t"
    
    var body: some View {
        NavigationStack {
            if isLoggedIn == false {
                LoginView(stomp: stomp, isLoggedIn: $isLoggedIn, senderNickName: $senderNickName)
            }
            else {
                ChatView(stomp: stomp, senderNickName: $senderNickName, isLoggedIn: $isLoggedIn)
            }
            
        }
        
    }
}

#Preview {
    ContentView()
}
