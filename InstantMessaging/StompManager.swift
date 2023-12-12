//
//  StompManager.swift
//  InstantMessaging
//
//  Created by Timothy on 6/12/23.
//

import Foundation
import SwiftStomp
import Starscream
import Combine

class StompManager: SwiftStompDelegate, ObservableObject {
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
        print("didReceive")
    }
    
    func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {
        print("onConnect")
    }
    
    func onDisconnect(swiftStomp: SwiftStomp, disconnectType: StompDisconnectType) {
        print("onDisconnect")
    }
    
    var receivedSubject = PassthroughSubject<String, Never>()
    
    func onMessageReceived(swiftStomp: SwiftStomp, message: Any?, messageId: String, destination: String, headers: [String : String]) {
        print("onMessageReceived")
        
        guard let unwrappedMessage = message as? String else {
            print("Error: Message is nil or not a string")
            return
        }
        
        print("received: \(message!)")
        print("destination: \(destination)")
        
        if destination.contains("/queue/messages") {
            receivedSubject.send(unwrappedMessage)
            print("sending received message")
        }
    }
    
    func onReceipt(swiftStomp: SwiftStomp, receiptId: String) {
        print("onReceipt")
    }
    
    func onError(swiftStomp: SwiftStomp, briefDescription: String, fullDescription: String?, receiptId: String?, type: StompErrorType) {
        print("onError")
        print(briefDescription) // check if SockJS is disabled in backend
    }
    
    func onSocketEvent(eventName: String, description: String) {
        print("onConnect")
    }
    
    var swiftStomp: SwiftStomp!

    init() {
        let url = URL(string: "http://localhost:8088/ws")!
        
        swiftStomp = SwiftStomp(host: url)
        swiftStomp.delegate = self
        swiftStomp.autoReconnect = true

        swiftStomp.connect()
    }

}

