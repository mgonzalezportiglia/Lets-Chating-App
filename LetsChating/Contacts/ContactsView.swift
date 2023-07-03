//
//  ContactsView.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 08/06/2023.
//

import SwiftUI

@MainActor
class ContactsViewModel: ObservableObject {
    
    @Published private(set) var usersDb: [DBUser] = [DBUser]()
    @Published var contactsSearched: String = ""
    
    var filteredUsers: [DBUser] {
        guard !contactsSearched.isEmpty else { return usersDb }
        
        return usersDb.filter { user in
            user.namePriority.lowercased().contains(contactsSearched.lowercased())
        }
    }
    
    func loadDBUsers() async throws {
        self.usersDb = try await UserManager.shared.fetchAllDBUser()
    }
    
}

struct ContactsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var vm: ContactsViewModel = ContactsViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(self.vm.filteredUsers, id: \.self) { user in
                    NavigationLink(value: user) {
                        HStack {
                            Text(user.firtsLetter)
                                .frame(width: 40, height: 40)
                                .background {
                                    Color.gray
                                }
                                .cornerRadius(10)
                                .shadow(radius: 5, x: 2, y: 2)
                                .font(.system(size: 18, weight: .bold))
                            VStack(alignment: .leading) {
                                Text(user.email ?? "unknown")
                                    .font(.system(size: 20, weight: .bold))
                            }
                            Spacer()
                        }
                        .padding()
                        .foregroundColor(Color(.label))
                    }
                    Divider()
                        .frame(height: 2)
                        .background(Color(.systemFill))
                }
                .navigationDestination(for: DBUser.self) { item in
                    ChattingView(user: item)
                        .navigationBarBackButtonHidden(true)
                }
            }
            .navigationBarTitleDisplayMode(.large)
            //TODO: make operate searchable
            .searchable(text: self.$vm.contactsSearched, placement: .navigationBarDrawer(displayMode: .always) , prompt: "Look for a contact")
            .navigationTitle("Contacts")
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
        .task {
            try? await vm.loadDBUsers()
        }
        
    }
}

struct ContactsView_Previews: PreviewProvider {
    static var previews: some View {
        ContactsView(vm: ContactsViewModel())
    }
}
