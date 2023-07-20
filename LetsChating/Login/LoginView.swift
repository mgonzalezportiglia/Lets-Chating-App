//
//  LoginView.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 08/06/2023.
//

import SwiftUI

struct LoginView: View {
    
    //with EnvironmentObject you can share the information from the View Model in your hole app (views and subviews).
    @EnvironmentObject var authenticationVM: AuthenticationViewModel
    
    @State private var emailAccount: String = ""
    @State private var passwordAccount: String = ""
    
    @State private var isLoginPicked = true
    
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("", selection: $isLoginPicked) {
                    Text("Login")
                        .tag(true)
                    Text("Create account")
                        .tag(false)
                }
                .pickerStyle(.segmented)
                .onChange(of: isLoginPicked) { newValue in
                    authenticationVM.resetForm()
                }
                
                Form {
                    
                    if isLoginPicked{
                        Group {
                            HStack {
                                Spacer()
                                Image("Image")
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .aspectRatio(contentMode: .fit)
                                    .padding(6)
                                    .cornerRadius(20)
                                    .shadow(radius: 10, x: 5, y: 5)
                                    
                                    
                                
                                Spacer()
                            }
                            
                            /*
                            TextFieldView(title: "Nickname / Email", text: $authenticationVM.email)
                            
                            TextFieldView(title: "Password", text: $authenticationVM.password)
                            */
                            TextField("Nickname / Email", text: $authenticationVM.email)
                            
                            TextField("Password", text: $authenticationVM.password)
                            
                            Button {
                                Task {
                                    await logIn()
                                }
                            } label: {
                                Spacer()
                                Text("Login")
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        Group {
                            /*TextFieldView(title: "Email", text: $authenticationVM.email)
                            TextFieldView(title: "Password", text: $authenticationVM.password)
                            TextFieldView(title: "Repeat password", text: $authenticationVM.confirmPassword)*/
                            
                            TextField("Email", text: $authenticationVM.email)
                            TextField("Password", text: $authenticationVM.password)
                            TextField("Repeat password", text: $authenticationVM.confirmPassword)
                            Button {
                                Task {
                                    await createAccount()
                                }
                            } label: {
                                Spacer()
                                Text("Create")
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    
                    Text(authenticationVM.errorMessage)
                        .foregroundColor(.red)
                    
                    Text(authenticationVM.displayName)
                        .foregroundColor(.blue)
                }
            
            }
            .padding()
        }
        
        .fullScreenCover(isPresented: self.$authenticationVM.didLogin) {
            ChatsView(chatsVM: ChatsViewModel(uid: authenticationVM.userDb?.userId ?? ""))
        }
    }
    
    
    private func createAccount() async {
        do {
            let authFlag = try await authenticationVM.createAccount()
        } catch {
            print("Error ocurrs")
        }
    }
    
    private func logIn() async {
        let response = await authenticationVM.signInWithEmailPassword()
    }

}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView().environmentObject(AuthenticationViewModel())
    }
}

struct TextFieldView: View {
    
    @State var title: String = ""
    @Binding var text: String
    
    init(title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 13))
                TextField(title, text: $text)
            }
            .padding(.trailing, 20)
        }
        .overlay {
            HStack {
                Spacer()
                Button {
                    
                } label: {
                    Image(systemName: "multiply.circle.fill")
                }
            }
            .offset(x: 0, y: 10)
        }
    }
}
