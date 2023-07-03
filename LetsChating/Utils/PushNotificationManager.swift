//
//  PushNotificationManager.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 08/06/2023.
//

import Foundation
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class PushNotificationManager: NSObject, UIApplicationDelegate {
    let gcmMessageIDKey = "gcm.message_id"//"gcm.message_id"
    
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
                
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNs)
            print("available iOS 10.0")
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in})
        } else {
            print("not available iOS 10.0")
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .sound, .badge], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
                
        application.registerForRemoteNotifications()
                
        print("didFinishLaunchingWithOptions")
        return true
    }
      
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
            
        print("enter here didReceiveRemoteNotification...")
            
            switch application.applicationState {
            case .background:
                print("the app is in background mode")
            case .inactive:
                print("the app is in inactive mode")
            default:
                print("the app is in active mode")
            }
            
        print(userInfo)
            completionHandler(.newData)
    }
    
    
}

extension PushNotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // to obtain FCM token, this is for each device in your application
        if let token = fcmToken {
            UserDefaults.standard.set(token, forKey: FirebaseManager.UserDefaultsKey.fcmToken.rawValue)
        }
    }
}

@available(iOS 10, *)
extension PushNotificationManager: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            
        print("userNotificationCenter willPresent")
              
        print("UNNotification: ", notification)
        let userInfo = notification.request.content.userInfo
        
        print("asd")
        print(notification.request.content.badge)
            print("-----------------------------")
            print(notification.request.content.userInfo)
            print("-----------------------------")
            print(notification.request.content.sound)
            print("-----------------------------")
            print(notification.request.content.body)

        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        
        print(userInfo)

        // Change this to your preferred presentation option
        completionHandler([[.banner, .badge, .sound]])
    }
    
    

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Successfully registered for notifications!")
        // Required to make FCM work since we disabled swizzling!
        Messaging.messaging().apnsToken = deviceToken
        // String version of APNS so we can use save it/use it later/do analytics.
        let apnsToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
                
        print("apnsToken: ", apnsToken)
        print("deviceToken: ", deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {

    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {
              
        print("userNotificationCenter didReceive")
        let userInfo = response.notification.request.content.userInfo

        print("UNNotificationResponse: ", response)
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID from userNotificationCenter didReceive: \(messageID)")
        }

        print(userInfo)

        completionHandler()
    }
    
}

