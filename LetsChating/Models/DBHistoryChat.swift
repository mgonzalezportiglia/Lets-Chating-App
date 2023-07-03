//
//  DBHistoryChat.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 08/06/2023.
//

import Foundation

struct DBHistoryChat: Codable, Hashable {
    let historyChat: [DBMessage]?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.historyChat, forKey: .historyChat)
    }
    
    enum CodingKeys: String, CodingKey {
        case historyChat = "history_chat"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.historyChat = try container.decodeIfPresent([DBMessage].self, forKey: .historyChat)
    }
    
    init(historyChat: [DBMessage]) {
        self.historyChat = historyChat
    }
}
