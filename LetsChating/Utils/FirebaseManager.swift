//
//  FirebaseManager.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 08/06/2023.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager: NSObject {
    
    let auth: Auth
    let storage: Firestore
    
    // Singleton
    static let shared = FirebaseManager()
    
    override init() {
        
        print("init FirebaseManager")
        
        self.auth = Auth.auth()
        self.storage = Firestore.firestore()
        
        super.init()
        print("end init FirebaseManager")
    }
    
    // Constants - Cloud Firestore - Collections
    static let COLLECTION_USERS = "COLLECTION_USERS"
    static let COLLECTION_MESSAGES = "COLLECTION_MESSAGES"
    static let COLLECTION_LAST_MESSAGES = "COLLECTION_LAST_MESSAGES"
    
    // Sub-collections
    static let SUBCOLLECTION_HISTORY_CHAT = "SUBCOLLECTION_HISTORY_CHAT"
    static let SUBCOLLECTION_LAST_MESSAGES = "SUBCOLLECTION_LAST_MESSAGES"
    
    // Constants
    enum UserDefaultsKey: String {
        case fcmToken
    }
}
