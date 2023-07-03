//
//  DBLastMessage.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 08/06/2023.
//

import Foundation

struct DBLastMessage: Codable, Hashable {
    let lastMessageId: String
    let lastMessage: String?
    let fromUserId: String?
    let toUserId: String?
    let timestamp: Date?
    
    enum CodingKeys: String, CodingKey {
        case lastMessageId = "last_message_id"
        case lastMessage = "last_message"
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case timestamp = "timestamp"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.lastMessageId = try container.decode(String.self, forKey: .lastMessageId)
        self.lastMessage = try container.decodeIfPresent(String.self, forKey: .lastMessage)
        self.fromUserId = try container.decodeIfPresent(String.self, forKey: .fromUserId)
        self.toUserId = try container.decodeIfPresent(String.self, forKey: .toUserId)
        self.timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.lastMessageId, forKey: .lastMessageId)
        try container.encodeIfPresent(self.lastMessage, forKey: .lastMessage)
        try container.encodeIfPresent(self.fromUserId, forKey: .fromUserId)
        try container.encodeIfPresent(self.toUserId, forKey: .toUserId)
        try container.encodeIfPresent(self.timestamp, forKey: .timestamp)
    }
    
    init(dbMessage: DBMessage) {
        self.lastMessageId = dbMessage.messageId
        self.lastMessage = dbMessage.message
        self.fromUserId = dbMessage.fromUserId
        self.toUserId = dbMessage.toUserId
        self.timestamp = dbMessage.timestamp ?? Date()
    }
}
