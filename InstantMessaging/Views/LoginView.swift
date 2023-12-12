//
//  LoginView.swift
//  InstantMessaging
//
//  Created by Timothy on 9/12/23.
//

import SwiftUI

struct LoginView: View {
    var stomp: StompManager
    @Binding var isLoggedIn: Bool
    @Binding var senderNickName: String
    
//    @State private var nickName = "t"
    @State private var fullName = "t"
    @State private var status = Status.ONLINE
    
    var body: some View {
        VStack {
            Form {
                Section("Username") {
                    TextField("", text: $senderNickName, prompt: Text("Required"))
                }
                Section("Full name") {
                    TextField("", text: $fullName, prompt: Text("Required"))
                }
                Button("Submit") {
                    createUser()
                }
            }
        }
    }
    
    func createUser() {
        stomp.swiftStomp.send(body: "This is message's text body", to: "/app/user.test")
        let user = User(nickName: senderNickName, fullName: fullName, status: .ONLINE)
        
        guard let encoded = try? JSONEncoder().encode(user) else {
            print("Failed to encode order")
            return
        }
        
        let jsonString = String(data: encoded, encoding: String.Encoding.utf8)
        print("sent: \(jsonString!)\n")
        stomp.swiftStomp.send(body: user, to: "/app/user.addUser")
        stomp.swiftStomp.subscribe(to: "/user/\(senderNickName)/queue/messages")
        stomp.swiftStomp.subscribe(to: "/user/public")
        isLoggedIn = true
        //            stomp.swiftStomp.send(body: jsonString, to: "/app/user.addUser") // does not work
    }
}

#Preview {
    let stomp = StompManager()
    @State var isLoggedIn = false
    @State var senderNickName = ""
    return LoginView(stomp: stomp, isLoggedIn: $isLoggedIn, senderNickName: $senderNickName)
}
