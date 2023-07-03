//
//  DBMessage.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 08/06/2023.
//

import Foundation

struct TrackerChat {
    let user_id: String
    let message_id: String
}

enum TypeMessage: String, Codable {
    case chat = "chat"
    case chatDeleted = "chat_deleted"
    case chatReply = "chat_reply"
    case date = "date"
}

struct DBMessage: Codable, Hashable {
    let messageId: String
    let fromUserId: String?
    let toUserId: String?
    var message: String?
    let timestamp: Date?
    var typeMessage: TypeMessage?
    let replyTo: String?
    
    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case message = "message"
        case timestamp = "timestamp"
        case typeMessage = "type_message"
        case replyTo = "reply_to"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.messageId = try container.decode(String.self, forKey: .messageId)
        self.fromUserId = try container.decodeIfPresent(String.self, forKey: .fromUserId)
        self.toUserId = try container.decodeIfPresent(String.self, forKey: .toUserId)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp)
        self.typeMessage = try container.decodeIfPresent(TypeMessage.self, forKey: .typeMessage)
        self.replyTo = try container.decodeIfPresent(String.self, forKey: .replyTo)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.messageId, forKey: .messageId)
        try container.encodeIfPresent(self.fromUserId, forKey: .fromUserId)
        try container.encodeIfPresent(self.toUserId, forKey: .toUserId)
        try container.encodeIfPresent(self.message, forKey: .message)
        try container.encodeIfPresent(self.timestamp, forKey: .timestamp)
        try container.encodeIfPresent(self.typeMessage, forKey: .typeMessage)
        try container.encodeIfPresent(self.replyTo, forKey: .replyTo)
    }
    
    init(messageId: String, fromUserId: String, toUserId: String, message: String, timestamp: Date, typeMessage: TypeMessage, replyTo: String?) {
        self.messageId = messageId
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.message = message
        self.timestamp = timestamp
        self.typeMessage = typeMessage
        self.replyTo = replyTo
    }
    
    mutating func updateMessage(message: String, typeMessage: TypeMessage) {
        self.message = message
        self.typeMessage = typeMessage
    }
}
