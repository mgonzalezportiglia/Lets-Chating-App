//
//  MessageManager.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 08/06/2023.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class MessageManager {
    
    // Singleton
    static let shared = MessageManager()
    
    private init() { }
    
    private let messageCollection = FirebaseManager.shared.storage.collection(FirebaseManager.COLLECTION_MESSAGES)
    private let lastMessageCollection = FirebaseManager.shared.storage.collection(FirebaseManager.COLLECTION_LAST_MESSAGES)
    
    public func messageDocument(trackerId: String) -> DocumentReference {
        messageCollection.document(trackerId)
    }
    
    private func historyChatSubcollectionDocument(trackerId: String, messageId: String) -> DocumentReference {
        messageDocument(trackerId: trackerId).collection(FirebaseManager.SUBCOLLECTION_HISTORY_CHAT).document(messageId)
    }
    
    func dateInformationMessage(userSenderId: String, userRecipientId: String, lastTime: Date) -> DBMessage {
        return DBMessage(
           messageId: UUID().uuidString,
           fromUserId: userSenderId,
           toUserId: userRecipientId,
           message: "",
           timestamp: lastTime - 1,
           typeMessage: .date,
           replyTo: nil)
    }
    
    func createConversation(recipient dbUser: DBUser, message: String, replyMessageId: String? = nil) async throws {
        
        guard let userLogedId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let dbMessageNew: DBMessage = DBMessage(
           messageId: UUID().uuidString,
           fromUserId: userLogedId,
           toUserId: dbUser.userId,
           message: message,
           timestamp: Date(),
           typeMessage: replyMessageId != nil ? .chatReply : .chat,
           replyTo: replyMessageId)
        
        try await insertConversation(for: userLogedId, with: dbUser.userId, message: dbMessageNew)
        try await insertConversation(for: dbUser.userId, with: userLogedId, message: dbMessageNew)
    }
    
    func insertConversation(for userForId: String, with userWithId: String, message: DBMessage) async throws {
        
        guard let userLogedId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        var trackerId = UUID().uuidString
        var mergeFlag = false
        
        // CHECK IF EXIST CONVERSATION BETWEEN BOTH
        if let trackerIdFounded = await UserManager.shared.checkTrackerIdIfExists(from: userForId, with: userWithId) {
            // EXISTS, SO APPEND
            trackerId = trackerIdFounded
            
            mergeFlag = true
            
            let lastMessageFetched = try await lastMessageDocument(userId: userForId).collection(FirebaseManager.SUBCOLLECTION_LAST_MESSAGES).document(trackerId).getDocument(as: DBLastMessage.self)
            
            if Utils.todayIsGratherThan(lastMessageFetched.timestamp) {
                let dateMessage = dateInformationMessage(userSenderId: message.fromUserId!, userRecipientId: message.toUserId!, lastTime: message.timestamp!)
                try historyChatSubcollectionDocument(trackerId: trackerId, messageId: dateMessage.messageId).setData(from: dateMessage, merge: mergeFlag)
            }
            
        } else {
            // NEW CONVERSATION
           
            mergeFlag = false
           
            await UserManager.shared.appendTrackerTo(trackerId: trackerId, userId: userForId, anotherUserId: userWithId)
            
            let dateMessage = dateInformationMessage(userSenderId: message.fromUserId!, userRecipientId: message.toUserId!, lastTime: message.timestamp!)
            try historyChatSubcollectionDocument(trackerId: trackerId, messageId: dateMessage.messageId).setData(from: dateMessage, merge: mergeFlag)
            
        }
        
        try historyChatSubcollectionDocument(trackerId: trackerId, messageId: message.messageId).setData(from: message, merge: mergeFlag)
        
        let dbLastMessage = DBLastMessage(dbMessage: message)
        try lastMessageDocument(userId: userForId).collection(FirebaseManager.SUBCOLLECTION_LAST_MESSAGES).document(trackerId).setData(from: dbLastMessage, merge: false)
    }
    
    func alreadyExistsDBMessage(messageId: String) async throws -> Bool {
        let document = try await messageCollection.document(messageId).getDocument()
        return document.exists
    }
    
    func appendMessage(dbMessage: DBMessage) async throws {
        // to an existing conversation
        try messageDocument(trackerId: dbMessage.messageId).setData(from: dbMessage, merge: false)
    }
    
    func messagesListener(by messageId: String, completionHandler: @escaping ((_ messages: [DBMessage]) -> Void)) -> ListenerRegistration {
        
        messageDocument(trackerId: messageId).collection(FirebaseManager.SUBCOLLECTION_HISTORY_CHAT).order(by: DBMessage.CodingKeys.timestamp.rawValue, descending: false).addSnapshotListener { querySnapshot, err in
            guard let documents = querySnapshot?.documents else { return }
            
            completionHandler(documents.map { queryDocumentSnapshot -> DBMessage in
                return try! queryDocumentSnapshot.data(as: DBMessage.self)
            })
            
        }
        
    }
    
    func deleteMessageForAll(this trackers: [TrackerChat], _ messageId: String, lastMessageTo: Bool = false, removeFromTrackers: String? = nil) async {
        do {
            
            var trackersFiltered = trackers
            
            if let removeUserId = removeFromTrackers {
                trackersFiltered = trackers.filter { tracker in
                    tracker.user_id != removeUserId
                }
            }
            
            for tracker in trackersFiltered {
                
                let trackerId = tracker.message_id
                let userId = tracker.user_id
                
                var dbMessageUpdated = try await historyChatSubcollectionDocument(trackerId: trackerId, messageId: messageId).getDocument(as: DBMessage.self)
                dbMessageUpdated.updateMessage(message: "", typeMessage: .chatDeleted)
                
                try historyChatSubcollectionDocument(trackerId: trackerId, messageId: messageId).setData(from: dbMessageUpdated, merge: true)
                
                if lastMessageTo {
                    try updateLastMessageFor(userId: userId, last: dbMessageUpdated, trackerId: trackerId)
                }
            }
            
        } catch let err {
            print("Error trying to delete messages, error \(err.localizedDescription)")
        }
    }
    
    func deleteChat(selected userId: String, from userDb: DBUser) async {
        do {
            var userDbToUpdate = userDb
            var indexToRemove: Int? = nil
            var trackerId: String? = nil
            
            // Find index to remove from conversations
            if var conversations = userDbToUpdate.conversationsTracker {
                for (index, conversationDictionary) in conversations.enumerated() {
                    if conversationDictionary[DBUser.CodingKeys.userId.rawValue] == userId {
                        trackerId = conversationDictionary[DBMessage.CodingKeys.messageId.rawValue]
                        indexToRemove = index
                        break
                    }
                }
                
                if let indexToRemove = indexToRemove,
                   let trackerId = trackerId {
                    conversations.remove(at: indexToRemove)
                    
                    userDbToUpdate.conversationsTracker = conversations
                    UserManager.shared.updateProfile(userDB: userDbToUpdate)
                    
                    messageDocument(trackerId: trackerId).delete() { err in
                        if let err = err {
                            print("Error removing document \(err)")
                        } else {
                            print("Document removed successfully!")
                        }
                    }
                    
                    lastMessageDocument(userId:userDbToUpdate.userId).collection(FirebaseManager.SUBCOLLECTION_LAST_MESSAGES).document(trackerId).delete() { err in
                        if let err = err {
                            print("Error removing document \(err)")
                        } else {
                            print("Document removed successfully!")
                        }
                    }
                }
                
            }
        } catch let err {
            print("Error deleting conversation with \(userId), error: \(err.localizedDescription)")
        }
    }

    
}

extension MessageManager {
    
    // EXTENSION RELATED TO - COLLECTION_LAST_MESSAGES
    
    private func lastMessageDocument(userId: String) -> DocumentReference {
        lastMessageCollection.document(userId)
    }
    
    func updateLastMessageFor(userId: String, last message: DBMessage, trackerId: String) throws {
        let dbLastMessage = DBLastMessage(dbMessage: message)
        
        try lastMessageDocument(userId: userId).collection(FirebaseManager.SUBCOLLECTION_LAST_MESSAGES).document(trackerId).setData(from: dbLastMessage, merge: false)
    }
    
    func lastChatsListener(user dbUserLoged: DBUser, completionHandler: @escaping ((_ lastMessages: [DBLastMessage]) -> Void)) -> ListenerRegistration {
        lastMessageDocument(userId: dbUserLoged.userId).collection(FirebaseManager.SUBCOLLECTION_LAST_MESSAGES).addSnapshotListener { queryDocument, err in
            guard let documents = queryDocument?.documents else { return }
            
            completionHandler(documents.map { queryDocumentSnapshot -> DBLastMessage in
                return try! queryDocumentSnapshot.data(as: DBLastMessage.self)
            })
        }
        
    }
    
    
}
