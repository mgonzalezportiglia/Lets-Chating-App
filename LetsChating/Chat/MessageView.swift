//
//  MessageView.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 29/06/2023.
//

import SwiftUI

struct MessageView: View {
    
    let chat: DBMessage?
    let userRecipientId: String
    let scrollHandler: ((String)) -> Void
    
    @EnvironmentObject var vm: ChattingViewModel
    
    var body: some View {
        
        if let chat = self.chat {
            
            if let typeMessage = chat.typeMessage {
                
                if typeMessage != .date {
                    if userRecipientId == chat.fromUserId {
                        RecipientMessageView(vmParent: self.vm, dbMessage: chat, userRecipientId: userRecipientId,
                            onTapScrollTo: ({ proxyPosition in
                                scrollHandler(proxyPosition)
                        }))
                            .id(chat.messageId)
                    } else {
                        SenderMessageView(vmParent: self.vm, dbMessage: chat,
                            onTapScrollTo: ({ proxyPosition in
                                scrollHandler(proxyPosition)
                            }))
                            .id(chat.messageId)
                    }
                } else if typeMessage == .date {
                    HStack {
                        HorizontalDivider(color: Color(.gray).opacity(0.5), height: 2)
                        Text(Utils.formatDate(timestamp: chat.timestamp))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(.lightText))
                            .padding(8)
                            .background(Color(.gray).opacity(0.5))
                            .cornerRadius(8)
                        HorizontalDivider(color: Color(.gray).opacity(0.5), height: 2)
                            
                    }
                }
                
            }
            
        }
        
    }
}


struct SenderMessageView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let vmParent: ChattingViewModel
    let dbMessage: DBMessage
    
    let onTapScrollTo: (String) -> Void
    
    var body: some View {
        HStack {
            Spacer()
            
            if let typeMessage = dbMessage.typeMessage,
               typeMessage == .chat {
                Text(dbMessage.message ?? "")
                    .padding()
                    .background(Color(.link))
                    .cornerRadius(10)
                    .contextMenu {
                        MenuItems(
                            onTapActionDelete: {
                                Task {
                                    await MessageManager.shared.deleteMessageForAll(this: vmParent.trackers, dbMessage.messageId, lastMessageTo: vmParent.lastMessageId == dbMessage.messageId)
                                }                            },
                            onTapActionReply: ({
                                vmParent.messageToReply = dbMessage
                                vmParent.showReplyContainer.toggle()
                            }))
                    }
            } else if let typeMessage = dbMessage.typeMessage,
                      typeMessage == .chatDeleted {
                HStack {
                    Image(systemName: "minus.circle.fill")
                    Text("Message deleted")
                }
                .padding()
                .background(Color(.link))
                .cornerRadius(10)
                .italic()
                .opacity(0.5)
            } else if let typeMessage = dbMessage.typeMessage,
                      typeMessage == .chatReply,
                      let originalId = dbMessage.replyTo,
                      let originalMessage = vmParent.messages.first(where: { message in
                          message.messageId == originalId }) {
                VStack {
                    if let originalMess = originalMessage.message,
                       !originalMess.isEmpty {
                        Text(originalMess)
                            .lineLimit(3)
                            .italic()
                            .font(.system(size: 16))
                            .padding(10)
                            .background(Color(.lightGray).opacity(0.5))
                            .cornerRadius(10)
                            .onTapGesture {
                                onTapScrollTo(originalMessage.messageId)
                            }
                        Text(dbMessage.message ?? "")
                    } else {
                        HStack {
                            Image(systemName: "minus.circle.fill")
                            Text("Message deleted")
                        }
                        .lineLimit(3)
                        .italic()
                        .font(.system(size: 16))
                        .padding(10)
                        .background(Color(.lightGray).opacity(0.5))
                        .cornerRadius(10)
                        .onTapGesture {
                            onTapScrollTo(originalMessage.messageId)
                        }
                    Text(dbMessage.message ?? "")
                    }
                }
                    .padding()
                    .background(Color(.link))
                    .cornerRadius(10)
                    .contextMenu {
                        MenuItems(
                            onTapActionDelete: {
                                Task {
                                    await MessageManager.shared.deleteMessageForAll(this: vmParent.trackers, dbMessage.messageId, lastMessageTo: vmParent.lastMessageId == dbMessage.messageId)
                                }
                            },
                            onTapActionReply: ({
                                vmParent.messageToReply = dbMessage
                                vmParent.showReplyContainer.toggle()
                            }))

                    }
                
            }
            Text(Utils.formatDateMessage(dbMessage.timestamp))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? Color(.lightText) : .black)
        }
    }
}


struct RecipientMessageView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let vmParent: ChattingViewModel
    let dbMessage: DBMessage
    let userRecipientId: String
    
    let onTapScrollTo: (String) -> Void
    
    var body: some View {
       HStack {
            Text(Utils.formatDateMessage(dbMessage.timestamp))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? Color(.lightText) : .black)
            if let typeMessage = dbMessage.typeMessage,
               typeMessage == .chat {
                Text(dbMessage.message ?? "")
                    .padding()
                    .background(Color(.darkGray))
                    .cornerRadius(10)
                    .contextMenu {
                        MenuItems {
                            // onTapActionDelete
                            // i want to delete only for me, not for recipient to
                            Task {
                                await MessageManager.shared.deleteMessageForAll(this: vmParent.trackers, dbMessage.messageId, lastMessageTo: vmParent.lastMessageId == dbMessage.messageId, removeFromTrackers: userRecipientId)
                            }
                        } onTapActionReply: {
                            vmParent.messageToReply = dbMessage
                            vmParent.showReplyContainer.toggle()
                        }

                    }
            } else if let typeMessage = dbMessage.typeMessage,
                      typeMessage == .chatDeleted {
                HStack {
                    Image(systemName: "minus.circle.fill")
                    Text("Message deleted")
                }
                .padding()
                .background(Color(.darkGray))
                .cornerRadius(10)
                .italic()
                .opacity(0.5)
            } else if let typeMessage = dbMessage.typeMessage,
                      typeMessage == .chatReply,
                      let originalId = dbMessage.replyTo,
                      let originalMessage = vmParent.messages.first(where: { message in
                          message.messageId == originalId }) {
                VStack {
                    if let originalMess = originalMessage.message,
                       !originalMess.isEmpty {
                        Text(originalMess)
                            .lineLimit(3)
                            .italic()
                            .font(.system(size: 16))
                            .padding(10)
                            .background(Color(.lightGray).opacity(0.5))
                            .cornerRadius(10)
                            .onTapGesture {
                                onTapScrollTo(originalMessage.messageId)
                            }
                        Text(dbMessage.message ?? "")
                    } else {
                        HStack {
                            Image(systemName: "minus.circle.fill")
                            Text("Message deleted")
                        }
                        .lineLimit(3)
                        .italic()
                        .font(.system(size: 16))
                        .padding(10)
                        .background(Color(.lightGray).opacity(0.5))
                        .cornerRadius(10)
                        .onTapGesture {
                            onTapScrollTo(originalMessage.messageId)
                        }
                    Text(dbMessage.message ?? "")
                    }
                }
                    .padding()
                    .background(Color(.darkGray))
                    .cornerRadius(10)
                    .contextMenu {
                        MenuItems(
                            onTapActionDelete: {
                                Task {
                                    await MessageManager.shared.deleteMessageForAll(this: vmParent.trackers, dbMessage.messageId, lastMessageTo: vmParent.lastMessageId == dbMessage.messageId, removeFromTrackers: userRecipientId)
                                }
                            },
                            onTapActionReply: ({
                                vmParent.messageToReply = dbMessage
                                vmParent.showReplyContainer.toggle()
                            }))

                    }
                
            }
            Spacer()
        }
    }
}


struct MenuItems: View {
    
    let onTapActionDelete: () -> Void
    let onTapActionReply: () -> Void
    
    var body: some View {
        Group {
            Button {
                onTapActionDelete()
            } label: {
                Image(systemName: "trash.circle.fill")
                Text("Delete")
            }
            Button {
                onTapActionReply()
            } label: {
                Image(systemName: "arrowshape.turn.up.left.circle.fill")
                Text("Reply")
            }
        }
    }
}

struct HorizontalDivider: View {
    
    let color: Color
    let height: CGFloat
    
    init(color: Color, height: CGFloat = 0.5) {
        self.color = color
        self.height = height
    }
    
    var body: some View {
        color
            .frame(height: height)
    }
}


struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        
        MessageView(chat: nil, userRecipientId: "user", scrollHandler: ({ _ in}))
    }
}
