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
    
    @State private var previousMessage: ChatMessage?
    
    var body: some View {
        VStack {
            HStack {
                Text("\(recipient.fullName)")
                    .font(.headline)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Divider()
                .frame(height: 1)
                .overlay(.black)
            
//            Button("DEBUG", systemImage: "gobackward") {
//                Task {
//                    await getMessages()
//                }
//            }
            
            ScrollView {
                ForEach(messages, id:\.timestamp) { msg in
                    if isNewDay(previousDate: previousMessage?.timestamp, currentDate: msg.timestamp) {
                        Text(formatDate(msg.timestamp))
                            .font(.caption)
                            .foregroundColor(.gray)
                        Divider() // Add a divider for separation
                    }
                    
                    if (msg.senderId == senderNickName) {
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(msg.content)
                                    .padding()
                                    .background(msg.senderId == senderNickName ? Color.blue : Color.indigo)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                
                                Text(formatTimestamp(msg.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .onAppear() {
                            previousMessage = msg
                        }
                    }
                    else {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(msg.content)
                                    .padding()
                                    .background(msg.senderId == senderNickName ? Color.blue : Color.indigo)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                
                                Text(formatTimestamp(msg.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .onAppear() {
                            previousMessage = msg
                        }
                    }
                }
                .padding()
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrollId, anchor: .bottom)
            
            HStack {
                TextField("Message", text: $message, axis: .vertical)
                    .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 8))
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(15)
                    .textFieldStyle(PlainTextFieldStyle())
                    .shadow(radius: 3)
                
                Button("", systemImage: "paperplane") {
                    Task {
                        await sendMessage()
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("Logged in as: \(senderNickName)")
                    .font(.headline)
                    .foregroundColor(.green)
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
    
    func isNewDay(previousDate: Date?, currentDate: Date) -> Bool {
        guard let previousDate = previousDate else {
            return true // Display the date for the first message
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: previousDate)
        let previousDay = calendar.date(from: components)!

        return !calendar.isDate(currentDate, inSameDayAs: previousDay)
    }

    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM"
        return dateFormatter.string(from: date)
    }

    
    // Function to format timestamp
    func formatTimestamp(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"  // Customize the timestamp format as needed
        return formatter.string(from: timestamp)
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
