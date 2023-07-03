//
//  ChattingView.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 29/06/2023.
//

import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI
import Combine

//typealias TrackerDictionary = [String: String]

@MainActor
class ChattingViewModel: ObservableObject {
    
    @Published var message = ""
    @Published var messages: [DBMessage] = [DBMessage]()
    @Published var trackerId = ""
    @Published var messageToReply: DBMessage? = nil
    
    @Published var lastMessageId: String = ""
    @Published var showReplyContainer: Bool = false
    @Published var trackers: [TrackerChat] = [TrackerChat]()
    @Published var sendButtonDisabled = false
    
    let textAllowed = 500
    
    var messageListener: ListenerRegistration?
    
    func loadChat(recipient dbUser: DBUser) async {
        
        guard let userIdLoged = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let trackerSender = await UserManager.shared.checkTrackerIdIfExists(from: userIdLoged, with: dbUser.userId)
        let trackerRecipient = await UserManager.shared.checkTrackerIdIfExists(from: dbUser.userId, with: userIdLoged)
        
        if let trackerRecipientId = trackerRecipient {
            self.trackers.append(TrackerChat(user_id: dbUser.userId, message_id: trackerRecipientId))
        }
        
        if let trackerID = trackerSender {
            self.trackers.append(TrackerChat(user_id: userIdLoged, message_id: trackerID))
            
            self.trackerId = trackerID
            messageListener = MessageManager.shared.messagesListener(by: trackerID) { messages in
                self.messages = messages
            }
            
            
        }
    }
    
    func sendMessage(to dbUser: DBUser) async {
        do {
            self.sendButtonDisabled = true
            
            if !self.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                try await MessageManager.shared.createConversation(recipient: dbUser, message: self.message.trimmingCharacters(in: .whitespacesAndNewlines), replyMessageId: self.messageToReply?.messageId)
            } else {
                self.message = ""
                self.sendButtonDisabled = false
            }
            
        } catch let err {
            print("Error creating message: ", err.localizedDescription)
        }
        
        self.message = ""
        self.sendButtonDisabled = false

        if self.messages.isEmpty {
            // re execute loadChat, because no tracker exist until the first message to listen on
            print("Re execute load chat because the tracker dont exists")
            await loadChat(recipient: dbUser)
        }
        
    }

}

struct ChattingView: View {
    
    let user: DBUser
    
    @StateObject var vm: ChattingViewModel = ChattingViewModel()
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showProfileRecipient = false
    
    var body: some View {
        NavigationView {
            
            ScrollViewReader { scrollProxy in
                ScrollView {
                    ForEach(self.vm.messages, id: \.messageId) { chat in
                        
                        MessageView(chat: chat, userRecipientId: user.userId, scrollHandler: ({ proxyPosition in
                            withAnimation {
                                scrollProxy.scrollTo(proxyPosition)
                            }
                        }))
                        .environmentObject(self.vm)
                        
                    }
                    .padding(.vertical)
                }
                .padding(.bottom, 100)
                .onAppear {
                    self.vm.lastMessageId = self.vm.messages.last?.messageId ?? ""
                    withAnimation {
                        scrollProxy.scrollTo(self.vm.messages.last?.messageId)
                    }
                }
                .onChange(of: self.vm.messages.count) { _ in
                    self.vm.lastMessageId = self.vm.messages.last?.messageId ?? ""
                    withAnimation {
                        scrollProxy.scrollTo(self.vm.messages.last?.messageId)
                    }
                }
                .clipped()
                .font(.system(size: 20))
                .foregroundColor(Color.white)
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                .background(Color(.systemFill))
            }
            
            .toolbar() {
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button() {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                
                ToolbarItem(placement: .navigation) {
                    Button {
                        showProfileRecipient.toggle()
                    } label: {
                        HStack {
                            if let photo = user.profileImageUrl,
                               photo.contains("http") {
                                WebImage(url: URL(string: photo))
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(15)
                                    .shadow(radius: 10, x: 5, y: 5)
                            } else if let first = user.firtsLetter {
                                Text(first)
                                    .frame(width: 40, height: 40)
                                    .background {
                                        Color.gray
                                    }
                                    .cornerRadius(15)
                                    .shadow(radius: 10, x: 5, y: 5)
                                    .font(.system(size: 18, weight: .bold))
                            }
                            VStack(alignment: .leading) {
                                Text(user.namePriority)
                                    .bold()
                                if let accountState = user.accountState {
                                    Text(accountState.rawValue)
                                        .font(.system(size: 14))
                                }
                            }
                            .foregroundColor(colorScheme == .dark ? .white: .black)
                        }
                    }
                }
            }
            .toolbarBackground(Color(.quaternaryLabel), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            
        }
        .fullScreenCover(isPresented: $showProfileRecipient, content: {
            ProfileRecipientSettings(userDb: self.user)
        })
        
        .onAppear {
            Task {
                await self.vm.loadChat(recipient: self.user)
            }
        }
        .onDisappear {
            self.vm.messages.removeAll()
            self.vm.messageListener?.remove()
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 0) {
                if self.vm.showReplyContainer {
                    withAnimation {
                        messageReply
                            .background(Color(.systemGray2))
                    }
                }
                messageFieldOverlay
                    .background(Color(.darkText))
            }
        }

    }
    
    
    
    /* MESSAGE REPLY */
    var messageReply: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                if let chatReply = self.vm.messageToReply,
                   let fromUserId = chatReply.fromUserId {
                    
                    Text(fromUserId == user.userId ? user.namePriority : "You")
                           .bold()
                       Text(chatReply.message ?? "")
                       .frame(maxHeight: 40)
                       .truncationMode(.tail)
                    
                }
            }
            .padding(.horizontal)
            
            Button {
                self.vm.showReplyContainer = false
            } label: {
                Image(systemName: "x.circle.fill")
            }
            .font(.system(size: 20))
        }
        .padding(.trailing)
        .frame(maxWidth: .infinity)
        
    }
    /* / MESSAGE REPLY */
    
    /* MESSAGE FIELD OVERLAY */
    var messageFieldOverlay: some View {
        HStack(spacing: 0) {
            TextField("Message", text: self.$vm.message, axis: .vertical)
                .onReceive(Just(self.vm.message), perform: { _ in
                    limitText(self.vm.textAllowed)
                })
                .textFieldStyle(CustomTextFieldStyle(backgroundColor: Color(.lightText)))
                .lineLimit(5)
                .padding()
            Button {
                Task {
                    self.vm.showReplyContainer = false
                    await self.vm.sendMessage(to: self.user)
                }
            } label: {
                HStack {
                    Image(systemName: "chevron.right")
                        .frame(width: 40, height: 40)
                }
                .background(Color(.systemBlue))
                .foregroundColor(Color(.white))
                .cornerRadius(15)
            }
            .disabled(self.vm.sendButtonDisabled)
        }
    }
    /* / MESSAGE FIELD OVERLAY */
    
    func limitText(_ allowed: Int) {
        if self.vm.message.count > allowed {
            self.vm.message = String(self.vm.message.prefix(allowed))
        }
    }
    
    
}

struct CustomTextFieldStyle: TextFieldStyle {
    
    let backgroundColor: Color
    
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(8)
            .background(self.backgroundColor)
            .border(Color(.gray))
            .cornerRadius(8)
            .font(.custom("", size: 20))
    }
    
}


struct ChattingView_Previews: PreviewProvider {
    static var previews: some View {
        let user = DBUser(userId: "123", email: "example@gmail.com", profileImageUrl: "", lastLogin: Date(), conversationsTracker: [], fcmToken: "", nickname: "Pepe", accountState: .available)
        
        NavigationView {
            ChattingView(user: user)
        }
    }
}
