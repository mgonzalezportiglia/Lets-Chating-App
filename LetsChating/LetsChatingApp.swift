//
//  LetsChatingApp.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 08/06/2023.
//

import SwiftUI
import FirebaseCore
import UserNotifications
import FirebaseMessaging

@main
struct LetsChatingApp: App {
    @UIApplicationDelegateAdaptor(PushNotificationManager.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            LoginView().environmentObject(AuthenticationViewModel())
        }
    }
}
