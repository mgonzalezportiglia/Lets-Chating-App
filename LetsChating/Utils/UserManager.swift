//
//  UserManager.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 08/06/2023.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

final class UserManager {
    
    // Singleton
    static let shared = UserManager()
    
    private init() { }

    private let userCollection = FirebaseManager.shared.storage.collection(FirebaseManager.COLLECTION_USERS)
    
    private func userDocument(userId: String) -> DocumentReference {
        userCollection.document(userId)
    }
    
    func createDBUser(user: DBUser) async throws {
        let userExists = try await alreadyExistsDBUser(userId: user.userId)
        if !userExists {
            try userDocument(userId: user.userId).setData(from: user, merge: false)
        } else {
            // Update last login
            try userDocument(userId: user.userId).setData(from: [DBUser.CodingKeys.lastLogin.rawValue: user.lastLogin], merge: true)
        }
    }
    
    func fetchDBUser(userId: String) async -> DBUser? {
        do {
            return try await userDocument(userId: userId).getDocument(as: DBUser.self)
        } catch let err {
            print("Error fetching DBUser from collection: \(err.localizedDescription)")
        }
        return nil
    }
    
    func alreadyExistsDBUser(userId: String) async throws -> Bool {
        let document = try await userCollection.document(userId).getDocument()
        return document.exists
    }
    
    func fetchAllDBUser() async throws -> [DBUser] {
        var dbUsers: [DBUser] = [DBUser]()
        
        guard let userLogedId = FirebaseManager.shared.auth.currentUser?.uid else { return [] }
        
        let snapshot = try await userCollection.getDocuments()
        
        for document in snapshot.documents {
            let user = try document.data(as: DBUser.self)
            if userLogedId != user.userId {
                dbUsers.append(user)
            }
        }
        
        return dbUsers
    }
    
    func fetchAllDBUserIn(open conversations: [DBLastMessage], notInclude userIdLoged: String) async -> [DBUser] {
        var dbUsers = [DBUser]()
        
        let usersId = conversations.map {
            if $0.fromUserId == userIdLoged {
                return $0.toUserId
            } else {
                return $0.fromUserId
            }
        }
        
        for item in usersId {
            if let uid = item {
                let dbUserFetched = await fetchDBUser(userId: uid)
                
                if let user = dbUserFetched {
                    dbUsers.append(user)
                }
            }
        }
        
        return dbUsers
    }
    
    func setConversationTrakerInfo(messageId: String, dbUserParam: DBUser, with userId: String) {
        do {
            var dbUser = dbUserParam
            
            guard let conversations = dbUser.conversationsTracker else { return }
            
            let hasConversation = conversations.first { dictionary in
                let uid = dictionary[DBUser.CodingKeys.userId.rawValue]
                let mid = dictionary[DBMessage.CodingKeys.messageId.rawValue]
                
                return uid == userId && mid == messageId
            }
            
            if hasConversation == nil {
                dbUser.appendConversation(messagId: messageId, userId: userId)
                try userDocument(userId: dbUser.userId).setData(from: dbUser, merge: true)
            }
        } catch let err {
            print("Error when append a new conversation tracker to user \(userId), error: \(err.localizedDescription)")
        }
    }
    
    func appendTrackerTo(trackerId: String, userId: String, anotherUserId: String) async {
        // FETCH USER`S
        guard let userDb = await fetchDBUser(userId: userId)
        else { return }
        
        // APPEND TRACKER IF NEEDED
        setConversationTrakerInfo(messageId: trackerId, dbUserParam: userDb, with: anotherUserId)
    }
    
    
    // With information about User Loged
    func fetchConversationIdSelectedIfExists(with recipientDBUser: DBUser) async -> String? {
        // FIND TRACKER ID IF EXISTS
        if let conversationDictionary = await checkMatchingChatBetweenLogedInAnd(recipientDBUser) {
            return conversationDictionary[DBMessage.CodingKeys.messageId.rawValue]
        }
    
        return nil
    }
    
    func checkMatchingChatBetweenLogedInAnd(_ recipientDBUser: DBUser) async -> [String: String]? {
        // FETCH USER LOGED IN
        guard let userLogedId = FirebaseManager.shared.auth.currentUser?.uid,
              let senderUser = await fetchDBUser(userId: userLogedId)
        else { return nil }
        
        // CHECK IF IT HAS CONVERSATION WITH SELECTED RECIPIENT USER
        let conversationWithUserSelected = senderUser.conversationsTracker?.first(where: { conversationDictionary in
            let uid = conversationDictionary[DBUser.CodingKeys.userId.rawValue]
            return recipientDBUser.userId == uid
        })
        
        return conversationWithUserSelected
    }
    
    // Without information about User Loged
    func checkTrackerIdIfExists(from userId: String, with anotherUserId: String) async -> String? {
        guard let userFrom = await fetchDBUser(userId: userId) else { return nil }
        
        // check if it has conversation with another user
        let conversationWithUserSelected = userFrom.conversationsTracker?.first(where: { conversationDictionary in
            let uid = conversationDictionary[DBUser.CodingKeys.userId.rawValue]
            return anotherUserId == uid
        })
        
        if let conversationFounded = conversationWithUserSelected {
            return conversationFounded[DBMessage.CodingKeys.messageId.rawValue]
        }
        
        return nil
    }
    
    func updateFirestokePushTokenIfNeeded() async -> Void {
        guard
            let userLogedId = FirebaseManager.shared.auth.currentUser?.uid,
            let fcmToken = UserDefaults.standard.value(forKey: FirebaseManager.UserDefaultsKey.fcmToken.rawValue) as? String
        else { return }
        
        do {
            var userDB = try await userDocument(userId: userLogedId).getDocument(as: DBUser.self)
            if let tokenFromUser = userDB.fcmToken,
               fcmToken != tokenFromUser {
                userDB.updateToken(fcmToken: fcmToken)
                try userDocument(userId: userLogedId).setData(from: userDB, merge: true)
            }
        } catch let err {
            print("Error updating user fcm token to push notifications: \(err.localizedDescription)")
        }
        
    }
    
    func updateProfile(userDB: DBUser) {
        do {
            try userDocument(userId: userDB.userId).setData(from: userDB, merge: true)
        } catch let err {
            print("Error updating user profile: \(err.localizedDescription)")
        }
    }
    
    func userFilterById(userId: String, users: [DBUser]?) -> DBUser? {
        if let users = users {
            let user = users.first { $0.userId == userId }
            if let user = user {
                return user
            }
        }
        
        return nil
    }
    
    
}
