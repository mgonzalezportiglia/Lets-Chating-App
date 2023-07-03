//
//  AuthenticationViewModel.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 08/06/2023.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol AuthProtocol {
    func signIn(withEmail email: String, password: String, completion: ((AuthDataResult?, Error?) -> Void)?)
}

extension Auth: AuthProtocol {
}

enum AuthenticationState {
    case authenticating
    case authenticated
    case unauthenticated
}

@MainActor
class AuthenticationViewModel: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    
    @Published var errorMessage: String = ""
    @Published var displayName: String = ""
    
    @Published var authenticationState: AuthenticationState = .unauthenticated
    
    @Published var didLogin = false
    @Published var userDb: DBUser? = nil
    
    func resetForm() -> Void {
        email = ""
        password = ""
        confirmPassword = ""
    }
    
    func createAccount(auth: Auth = FirebaseManager.shared.auth) async throws -> Bool {
        self.authenticationState = .authenticating
        self.errorMessage = ""
        //AuthErrorCodeEmailAlreadyInUse
        do {
            let authResult = try await auth.createUser(withEmail: email, password: password)
            self.authenticationState = .authenticated
            self.didLogin = true
            self.userDb = DBUser(userId: authResult.user.uid, email: authResult.user.email ?? "", profileImageUrl: "", lastLogin: Date(), conversationsTracker: [], fcmToken: "", nickname: "", accountState: .available)
            try? await UserManager.shared.createDBUser(user: self.userDb!)
            
        } catch AuthErrorCode.emailAlreadyInUse {
            self.authenticationState = .unauthenticated
            self.errorMessage = "Email provided is already in use"
        } catch AuthErrorCode.invalidEmail {
            self.authenticationState = .unauthenticated
            self.errorMessage = "Email provided is invalid"
        }
                
        return AuthenticationState.authenticated == self.authenticationState
    }
    
    func signInWithEmailPassword(auth: AuthProtocol = FirebaseManager.shared.auth) -> Bool {
        self.authenticationState = .authenticating
        
        auth.signIn(withEmail: email, password: password) { authResult, error in
            guard let user = authResult?.user, error == nil else {
                print("error - signInWithEmailPassword: \(error?.localizedDescription ?? "")")
                self.authenticationState = .unauthenticated
                self.errorMessage = "Error during sign in with email and password"
                
                return
            }

            self.authenticationState = .authenticated
            self.didLogin = true
            
            Task {
                self.userDb = DBUser(userId: user.uid, email: user.email ?? "", profileImageUrl: "", lastLogin: Date(), conversationsTracker: [], fcmToken: "", nickname: "", accountState: .available)
                try? await UserManager.shared.createDBUser(user: self.userDb!)
            }
        }
        return AuthenticationState.authenticated == self.authenticationState
    }
    
    func signOut(auth: Auth = FirebaseManager.shared.auth) {
        do {
            
            print("Loging user out from application.")
            
            try auth.signOut()
            self.authenticationState = .unauthenticated
            self.didLogin = false
            
        } catch let err {
            print("Error loging out user: ", err.localizedDescription)
        }
    }

}
