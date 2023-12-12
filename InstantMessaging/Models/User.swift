//
//  User.swift
//  InstantMessaging
//
//  Created by Timothy on 8/12/23.
//

import Foundation
import SwiftData

@Model
class User: Codable {
    let nickName: String
    let fullName: String
    var status: Status
    
    // CodingKeys is used to map enum cases to their corresponding raw values
    private enum CodingKeys: String, CodingKey {
        case nickName
        case fullName
        case status
    }
    
    // Encoder method
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nickName, forKey: .nickName)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(status, forKey: .status)
    }
    
    // Decoder initialization
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nickName = try container.decode(String.self, forKey: .nickName)
        fullName = try container.decode(String.self, forKey: .fullName)
//        status = try container.decode(Status.self, forKey: .status)
        
        // Decode status as a string and convert it to the Status enum
        if let statusString = try? container.decode(String.self, forKey: .status),
           let decodedStatus = Status(rawValue: statusString) {
            status = decodedStatus
        } else {
            throw DecodingError.dataCorruptedError(forKey: .status, in: container, debugDescription: "Invalid status string")
        }
    }
    
    init(nickName: String, fullName: String, status: Status) {
        self.nickName = nickName
        self.fullName = fullName
        self.status = status
    }
}

// enum must be Codable
enum Status: String, Codable {
    case ONLINE, OFFLINE
}
