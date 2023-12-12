//
//  ChatBoxView.swift
//  InstantMessaging
//
//  Created by Timothy on 9/12/23.
//

import SwiftUI
import SwiftData
import SwiftStomp
import Combine

struct ChatBoxView: View {
    var stomp: StompManager
    
    @Binding var senderNickName: String
    var recipient: User
    
    @State private var message = ""
    @State private var messages = [ChatMessage]()
    
    // use ChatMessage.timestamp type as scrolId
    @State private var scrollId: Date?
    var receivedCancellable: AnyCancellable?
    
    var body: some View {
        VStack {
            Text("Chatting with \(recipient.fullName)")
                .font(.headline)
                .padding(.top, 10)
                .padding(.bottom, 10)
            
            Divider()
            
            Button("DEBUG", systemImage: "gobackward") {
                Task {
                    await getMessages()
                }
            }
            
            ScrollView {
                ForEach(messages, id:\.timestamp) { msg in
                    if (msg.senderId == senderNickName) {
                        HStack {
                            Spacer()
                            Text(msg.content)
                                .padding()
                                .background(msg.senderId == senderNickName ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    else {
                        HStack {
                            Text(msg.content)
                                .padding()
                                .background(msg.senderId == senderNickName ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            Spacer()
                        }
                    }
                }
                .padding()
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrollId, anchor: .bottom)
            
            HStack {
                TextField("Message", text: $message, axis: .vertical)
                    .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(20)
                    .textFieldStyle(PlainTextFieldStyle())
                    .shadow(radius: 3)
                
                Button("", systemImage: "paperplane") {
                    Task {
                        await sendMessage()
                    }
                }
            }
        }
        .onChange(of: recipient) {
            Task {
                await getMessages()
            }
        }
        .onAppear() {
            Task {
                await getMessages()
            }
        }
        .onReceive(stomp.receivedSubject) { receivedMessage in
            receiveMessage(msg: receivedMessage)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
    
    func receiveMessage(msg: String) {
        // convert to json
        if let jsonData = msg.data(using: .utf8) {
            do {
                let chatMessage = try JSONDecoder().decode(ChatMessage.self, from: jsonData)
                if (recipient.nickName == chatMessage.senderId) {
                    messages.append(chatMessage)
                    scrollId = messages.last?.timestamp
                }
            } catch {
                print("Error decoding ChatMessage:", error.localizedDescription)
            }
        }
    }
    
    func getMessages() async {
        let url = URL(string: "http://localhost:8088/messages/\(senderNickName)/\(recipient.nickName)")!
        
        Task {
            do {
                usleep(250000) // sleep  0.25
                // usleep(1000000) //  sleep 1s
                let (data, _) = try await URLSession.shared.data(from: url)
                
                messages = try JSONDecoder().decode([ChatMessage].self, from: data)
                
                scrollId = messages.last?.timestamp
            } catch {
                print("GET request failed: \(error.localizedDescription)")
                print(String(describing: error))
            }
        }
    }
    
    func sendMessage() async {
        let chatMessage = ChatMessage(senderId: senderNickName, recipientId: recipient.nickName, content: message, timestamp: Date.now)
        print(Date.now)
        
        guard let encoded = try? JSONEncoder().encode(chatMessage) else {
            print("Failed to encode order")
            return
        }
        let jsonString = String(data: encoded, encoding: String.Encoding.utf8)
        print(jsonString!)
        
        stomp.swiftStomp.send(body: chatMessage, to: "/app/chat")
        message = ""
        
        await getMessages()
    }
}

#Preview {
    let stomp = StompManager()
    @State var recipient = User(nickName: "test", fullName: "testName", status: Status.ONLINE)
    @State var senderNickName = ""
    return ChatBoxView(stomp: stomp, senderNickName: $senderNickName, recipient: recipient)
}
