//
//  ProfileRecipientSettings.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 30/06/2023.
//

import SwiftUI
import PhotosUI
import FirebaseStorage
import SDWebImageSwiftUI

struct ProfileRecipientSettings: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let userDb: DBUser
    
    var body: some View {
        
        
        NavigationStack {
            VStack {
                Form {
                    Section("Nickname") {
                        Text(self.userDb.namePriority)
                    }
                    
                    Section("Profile image") {
                        if let photo = self.userDb.profileImageUrl,
                           photo.contains("http") {
                            HStack(alignment: .center) {
                                Spacer()
                                WebImage(url: URL(string: photo))
                                    .resizable()
                                    .frame(width: 150, height: 150)
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(20)
                                    .shadow(radius: 10, x: 5, y: 5)
                                Spacer()
                            }
                        }
                    }
                    
                    Section("Account State") {
                        Text(self.userDb.accountState?.rawValue ?? "Nothing")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
        }
        
        
    }
}

struct ProfileRecipientSettings_Previews: PreviewProvider {
    static var previews: some View {
        
        let user = DBUser(userId: "123", email: "example@gmail.com", profileImageUrl: "", lastLogin: Date(), conversationsTracker: [], fcmToken: "", nickname: "Pepe", accountState: .available)
        
        ProfileRecipientSettings(userDb: user)
    }
}
