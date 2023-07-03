//
//  DBUser.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 08/06/2023.
//

import Foundation

enum AccountState: String, CaseIterable, Identifiable, Codable {
    var id: Self { self }
    
    case available = "Available"
    case occupied = "Occupied"
    case atSchool = "At School"
    case atTheCinema = "At the Cinema"
    case atWork = "At Work"
    case lowBattery = "Low Battery"
    case inMeeting = "In a Meeting"
    case atTheGym = "At the Gym"
    case emergenciesOnly = "Emergencies only"
}

struct DBUser: Codable, Hashable {
    let userId: String
    let email: String?
    var profileImageUrl: String?
    let lastLogin: Date?
    var conversationsTracker: [[String: String]]?
    var fcmToken: String?
    var nickname: String?
    var accountState: AccountState?
    
    var namePriority: String {
        if let nick = nickname {
            return nick
        } else if let emailNick = email {
            return emailNick
        }
        return "Unknown"
    }
    
    var firtsLetter: String {
        if let first = namePriority.first?.uppercased() {
            return first
        }
        return ""
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email = "email"
        case profileImageUrl = "profile_image_url"
        case lastLogin = "last_login"
        case conversationsTracker = "conversations_tracker"
        case fcmToken = "fcm_token"
        case nickname = "nickname"
        case accountState = "account_state"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        self.lastLogin = try container.decodeIfPresent(Date.self, forKey: .lastLogin)
        self.conversationsTracker = try container.decodeIfPresent([[String: String]].self, forKey: .conversationsTracker)
        self.fcmToken = try container.decodeIfPresent(String.self, forKey: .fcmToken)
        self.nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        self.accountState = try container.decodeIfPresent(AccountState.self, forKey: .accountState)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.userId, forKey: .userId)
        try container.encodeIfPresent(self.email, forKey: .email)
        try container.encodeIfPresent(self.profileImageUrl, forKey: .profileImageUrl)
        try container.encodeIfPresent(self.lastLogin, forKey: .lastLogin)
        try container.encodeIfPresent(self.conversationsTracker, forKey: .conversationsTracker)
        try container.encodeIfPresent(self.fcmToken, forKey: .fcmToken)
        try container.encodeIfPresent(self.nickname, forKey: .nickname)
        try container.encodeIfPresent(self.accountState, forKey: .accountState)
    }
    
    init(userId: String,
         email: String,
         profileImageUrl: String,
         lastLogin: Date,
         conversationsTracker: [[String: String]],
         fcmToken: String,
         nickname: String,
         accountState: AccountState) {
        self.userId = userId
        self.email = email
        self.profileImageUrl = profileImageUrl
        self.lastLogin = lastLogin
        self.conversationsTracker = conversationsTracker
        self.fcmToken = fcmToken
        self.nickname = nickname
        self.accountState = accountState
    }
    
    mutating func appendConversation(messagId: String, userId: String) {
        let dictionaryFounded = conversationsTracker?.first(where: { dictionary in
            let uid = dictionary[DBUser.CodingKeys.userId.rawValue]
            let mid = dictionary[DBMessage.CodingKeys.messageId.rawValue]
            return uid == userId && mid == messagId
        })
        
        if dictionaryFounded == nil {
            conversationsTracker?.append([
                DBUser.CodingKeys.userId.rawValue : userId,
                DBMessage.CodingKeys.messageId.rawValue : messagId
            ])
        }
    }
    
    mutating func updateToken(fcmToken: String) {
        self.fcmToken = fcmToken
    }
    
    mutating func updateProfile(nickname: String?, photo: String?, accountState: AccountState?) {
        if let nickname = nickname {
            self.nickname = nickname
        }
        if let photo = photo {
            self.profileImageUrl = photo
        }
        if let accountState = accountState {
            self.accountState = accountState
        }
    }
    
}
