//
//  ChatsView.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 08/06/2023.
//

import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

@MainActor
class ChatsViewModel: ObservableObject {
    
    let uid: String
    
    @Published var conversations: [DBLastMessage] = [DBLastMessage]()
    @Published var usersDb: [DBUser]? = nil
    @Published var userDb: DBUser? = nil
    @Published var newMessagesOpen = false
    @Published var confirmationDialogOpen = false
    @Published var profileSettingsOpen = false
    
    var lastChatsListener: ListenerRegistration?
    
    init(uid: String) {
        self.uid = uid
    }
    
    func loadCurrentChats() async {
        self.userDb = await UserManager.shared.fetchDBUser(userId: self.uid)
        
        if let dbUser = self.userDb {
            lastChatsListener = MessageManager.shared.lastChatsListener(user: dbUser) { lastMessages in
                self.conversations = lastMessages
                Task {
                    await self.loadUsersInformation()
                }
            }
        }
    }
    
    func loadUsersInformation() async {
        let usersDb = await UserManager.shared.fetchAllDBUserIn(open: self.conversations, notInclude: self.uid)
        
        self.usersDb = usersDb
    }
    
    func deleteConversation(_ conversation: DBLastMessage) async {
        
        guard let fromUser = conversation.fromUserId,
              let toUser = conversation.toUserId,
              let userLoged = self.userDb
        else { return }
        
        let userIdToDelete = userLoged.userId == fromUser ? toUser : fromUser
        
        await MessageManager.shared.deleteChat(selected: userIdToDelete, from: userLoged)
    }
    
}

struct ChatsView: View {
    
    @EnvironmentObject private var authVM: AuthenticationViewModel
    @StateObject var chatsVM: ChatsViewModel
    
    var body: some View {
        NavigationStack {
            /* Custom Nav Bar */
            HStack {
                VStack(alignment: .leading) {
                    DataUserLogedView
                        .padding()
                }
                Spacer()
                Button {
                    chatsVM.confirmationDialogOpen.toggle()
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 24))
                }
                .padding()
            }
            .background(Color(.quaternaryLabel))
            /* / Custom Nav Bar */
            ScrollView {
                if chatsVM.conversations.isEmpty {
                    HStack {
                        Text("You don't have any \(Text("conversation").bold()) yet, start chatting now.")
                            .padding()
                            .background(Color(.systemFill))
                            .font(.system(size: 18))
                            .cornerRadius(4)
                    }
                    .padding()
                }
                ForEach(chatsVM.conversations, id: \.self) { conversation in
                    ZStack {
                        NavigationLink(value: conversation) {
                            HStack {
                                if
                                    let fromUser = conversation.fromUserId,
                                    let userLoged = self.chatsVM.userDb,
                                    userLoged.userId == fromUser,
                                    let user = UserManager.shared.userFilterById(userId: conversation.toUserId!, users: self.chatsVM.usersDb) {
                                    
                                    ChatCardImageView(user: user)
                                } else if let user = UserManager.shared.userFilterById(userId: conversation.fromUserId!, users: self.chatsVM.usersDb) {
                                    
                                    ChatCardImageView(user: user)
                                }
                                VStack(alignment: .leading) {
                                    HStack {
                                        if
                                            let fromUser = conversation.fromUserId,
                                            let userLoged = self.chatsVM.userDb,
                                            userLoged.userId == fromUser,
                                            let user = UserManager.shared.userFilterById(userId: conversation.toUserId!, users: self.chatsVM.usersDb) {
                                            
                                            ChatCardTextView(user: user, conversation: conversation)
                                        } else if let user = UserManager.shared.userFilterById(userId: conversation.fromUserId!, users: self.chatsVM.usersDb) {
                                            
                                            ChatCardTextView(user: user, conversation: conversation)
                                        }
                                    }
                                    
                                    if let lastMessage = conversation.lastMessage,
                                       !lastMessage.isEmpty {
                                        Text(lastMessage)
                                            .font(.system(size: 18, weight: .regular))
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxHeight: 50)
                                            .truncationMode(.tail)
                                    } else {
                                        HStack {
                                            Image(systemName: "minus.circle.fill")
                                            Text("Message deleted")
                                        }
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundColor(.gray)
                                        .frame(maxHeight: 50)
                                        .italic()
                                    }
                                    
                                }
                                Spacer()
                            }
                            .padding()
                            .foregroundColor(Color(.label))
                        }
                    }
                    .contextMenu {
                        Group {
                            Button(role: .destructive) {
                                Task {
                                    await self.chatsVM.deleteConversation(conversation)
                                }
                            } label : {
                                Image(systemName: "trash")
                                    .font(.system(size: 24))
                                Text("Delete")
                            }
                        }
                    }
                    Divider()
                        .frame(height: 2)
                        .background(Color(.systemFill))
                }
                .navigationDestination(for: DBLastMessage.self) { conversation in
                    if
                        let userLoged = self.chatsVM.userDb,
                        userLoged.userId == conversation.fromUserId,
                        let user = UserManager.shared.userFilterById(userId: conversation.toUserId!, users: self.chatsVM.usersDb) {
                        ChattingView(user: user)
                            .navigationBarBackButtonHidden(true)
                    } else if let user = UserManager.shared.userFilterById(userId: conversation.fromUserId!, users: self.chatsVM.usersDb) {
                        ChattingView(user: user)
                            .navigationBarBackButtonHidden(true)
                    }
                }
            }
            .toolbar {
                
                ChatsToolbarBottom {
                    chatsVM.newMessagesOpen.toggle()
                }
                
            }
        }
        .confirmationDialog("", isPresented: self.$chatsVM.confirmationDialogOpen, actions: {
            Button("Profile settings") {
                chatsVM.profileSettingsOpen.toggle()
            }
            
            Button("Sign Out", role: .destructive) {
                self.chatsVM.lastChatsListener?.remove()
                self.authVM.resetForm()
                self.authVM.signOut()
            }
        }, message: { })
        .fullScreenCover(isPresented: self.$chatsVM.profileSettingsOpen, content: {
            ProfileSettings(didUpdateProfile: {
                Task {
                    self.chatsVM.userDb = await UserManager.shared.fetchDBUser(userId: self.chatsVM.uid)
                }
            })
        })
        .fullScreenCover(isPresented: self.$chatsVM.newMessagesOpen) {
            ContactsView(vm: ContactsViewModel())
        }
        .onAppear {
            Task {
                await chatsVM.loadCurrentChats()
                await UserManager.shared.updateFirestokePushTokenIfNeeded()
            }
        }
        .onDisappear {
            self.chatsVM.conversations.removeAll()
            self.chatsVM.lastChatsListener?.remove()
        }
    }
    
    var DataUserLogedView: some View {
        HStack {
            if let photo = self.chatsVM.userDb?.profileImageUrl,
                photo.contains("http") {
                WebImage(url: URL(string: photo))
                    .resizable()
                    .frame(width: 60, height: 60)
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(20)
                    .shadow(radius: 10, x: 5, y: 5)
            } else if let first = self.chatsVM.userDb?.firtsLetter {
                Text(first)
                    .frame(width: 60, height: 60)
                    .background {
                        Color.gray
                    }
                    .cornerRadius(20)
                    .shadow(radius: 10, x: 5, y: 5)
                    .font(.system(size: 20, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(chatsVM.userDb?.namePriority ?? "Unknown")
                    .font(.title2.bold())
                HStack {
                    Text("")
                        .frame(width: 10, height: 10)
                        .background(Color.green)
                        .clipShape(Circle())
                    Text("online")
                }
            }
        }
    }
    
}

struct ChatCardTextView: View {
    
    let user: DBUser
    let conversation: DBLastMessage
    
    var body: some View {
        Text(user.namePriority)
            .font(.system(size: 20, weight: .bold))
        Spacer()
        Text(Utils.formatDateTimeAgo(conversation.timestamp))
    }
}

struct ChatCardImageView: View {
    let user: DBUser
    
    var body: some View {
        if let photo = user.profileImageUrl,
           photo.contains("http") {
            WebImage(url: URL(string: photo))
                .resizable()
                .frame(width: 40, height: 40)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(10)
                .shadow(radius: 5, x: 2, y: 2)
        } else {
            Text(user.firtsLetter)
                .frame(width: 40, height: 40)
                .background {
                    Color.gray
                }
                .cornerRadius(10)
                .shadow(radius: 5, x: 2, y: 2)
                .font(.system(size: 18, weight: .bold))
        }
    }
}

struct ChatsToolbarBottom: ToolbarContent {
    let messageHandler: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            Button {
                messageHandler()
              //newMessageHandler()
            } label: {
                Text("+ New message")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

}

struct ChatsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ChatsView(chatsVM: ChatsViewModel(uid: "123"))//.preferredColorScheme(.dark)
        }
    }
}
