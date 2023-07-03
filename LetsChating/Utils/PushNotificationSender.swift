//
//  PushNotificationSender.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 08/06/2023.
//

import Foundation

class PushNotificationSender {
    
    static let shared = PushNotificationSender()
    
    func sendPushNotification(to token: String, title: String, body: String) {
        //let urlString = "https://fcm.googleapis.com/fcm/send"
        let urlString = "https://fcm.googleapis.com/v1/projects/letschating-91012/messages:send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = [
           /* "to" : token,
            "notification" : ["title" : title, "body" : body],
            "data" : ["user" : "test_id"]
            */
            "message": [
                  "token": token,
                  "notification": [
                    "body":"This is an FCM notification message!",
                    "title":"FCM Message"
                  ]
            ]
        ]
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer key=AAAAorQkZ_Y:APA91bHzhlDqQgsEi7gn9Rl7SZugOyuZJ2SPnNZsXXsv8UspDhvlX-O-4JM7HqXen1178b0zDQPp99BbS1mVn1ELTws2_3jkz8p-oXh_e8OOMAV3gOLu2OdDlGQ3Bdmky49CD0DmQJSD", forHTTPHeaderField: "Authorization")
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
    }
}
