//
//  ChatView.swift
//  InstantMessaging
//
//  Created by Timothy on 9/12/23.
//

import SwiftUI

struct ChatView: View {
    var stomp: StompManager
    @Binding var senderNickName: String
    @Binding var isLoggedIn: Bool
    
    @State private var user: User?
    @State private var users = [User]()
    @State private var recipient: User?
    
    var body: some View {
        NavigationStack {
            HStack {
                VStack {
                    Text("Users")
                        .font(.title)
                    ForEach(users, id: \.nickName) { user in
                        // sender cannot talk to himself
                        if (user.nickName != senderNickName) {
                            Button(action: {
                                recipient = user
                            }) {
                                HStack() {
                                    Image(systemName: "person.circle")
                                    Text(user.nickName)
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                    Button("Logout") {
                        Task {
                            logout()
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .foregroundColor(.red)
                }
                .padding(10)
                .onAppear {
                    Task {
                        await getUsers()
                        await getUser()
                    }
                }
                
                if let recipient = recipient {
                    ChatBoxView(stomp: stomp, senderNickName: $senderNickName, recipient: recipient)
                } else {
                    Text("Select a user to start chatting")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
        
    func logout() {
        Task {
            user?.status = Status.OFFLINE
            stomp.swiftStomp.send(body: user, to: "/app/user.disconnectUser")
            isLoggedIn = false
        }
    }
    
    func getUser() async {
        let url = URL(string: "http://localhost:8088/user/\(senderNickName)")!
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let userDecoded = try JSONDecoder().decode(User.self, from: data)
                user = userDecoded
            } catch {
                print("GET request failed: \(error.localizedDescription)")
                print(String(describing: error))
            }
        }
    }
    
    func getUsers() async {
        let url = URL(string: "http://localhost:8088/users")!
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let usersDecoded = try JSONDecoder().decode([User].self, from: data)
                users = usersDecoded
            } catch {
                print("GET request failed: \(error.localizedDescription)")
                print(String(describing: error))
            }
        }
    }
        
}

#Preview {
    let stomp = StompManager()
    @State var senderNickName = ""
    @State var isLoggedIn = true
    return ChatView(stomp: stomp, senderNickName: $senderNickName, isLoggedIn: $isLoggedIn)
}
