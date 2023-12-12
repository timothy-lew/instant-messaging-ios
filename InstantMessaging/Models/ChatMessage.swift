//
//  ChatMessage.swift
//  InstantMessaging
//
//  Created by Timothy on 9/12/23.
//

import Foundation
import SwiftData

@Model
class ChatMessage: Codable {
    let id: String?
    let chatId: String?
    let senderId: String
    let recipientId: String
    let content: String
    let timestamp: Date
    
    // CodingKeys is used to map enum cases to their corresponding raw values
    private enum CodingKeys: String, CodingKey {
        case id
        case chatId
        case senderId
        case recipientId
        case content
        case timestamp
    }
    
    // Encoder method
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(recipientId, forKey: .recipientId)
        try container.encode(content, forKey: .content)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    // Decoder initialization
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        senderId = try container.decode(String.self, forKey: .senderId)
        recipientId = try container.decode(String.self, forKey: .recipientId)
        content = try container.decode(String.self, forKey: .content)
//        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // Decode timestamp as a string and convert it to a Date
        let timestampString = try container.decode(String.self, forKey: .timestamp)
        if let date = ChatMessage.dateFormatter.date(from: timestampString) {
            timestamp = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .timestamp, in: container, debugDescription: "Failed to parse timestamp")
        }
    }
    
    init(senderId: String, recipientId: String, content: String, timestamp: Date) {
        self.senderId = senderId
        self.recipientId = recipientId
        self.content = content
        self.timestamp = timestamp
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
}
