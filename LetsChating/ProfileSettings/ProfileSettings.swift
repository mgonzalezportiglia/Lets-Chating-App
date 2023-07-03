//
//  ProfileSettings.swift
//  LetsChating
//
//  Created by Matias Gonzalez Portiglia on 10/06/2023.
//

import SwiftUI
import PhotosUI
import FirebaseStorage
import SDWebImageSwiftUI

class ProgressStatus {
    @State var inProgress: Bool = true
    @State var progressCount: CGFloat = 0
}

class ProfileSettingsViewModel: ObservableObject {
    
    @Published var nickname: String = ""
    @Published var selectedState: AccountState = .available
    @Published var selectedItem: PhotosPickerItem? = nil
    @Published var selectedItemData: Data? = nil
    @Published var userDB: DBUser? = nil
    @Published var inProgress: Bool = false
    
    init() { }
    
    func loadUserData() async {
        let uid = FirebaseManager.shared.auth.currentUser?.uid
        if let uid = uid {
            let userFetched = await UserManager.shared.fetchDBUser(userId: uid)
            Task { @MainActor in
                self.userDB = userFetched
                self.nickname = userFetched?.nickname ?? ""
                self.selectedState = userFetched?.accountState ?? .available
            }
        }
    }
    
    func updateUserInformation(userUpdatedCompletionHandler: @escaping (() -> Void)) {
        self.inProgress = true
        
        guard var userToUpdate = self.userDB
        else {
            self.inProgress = false
            return
        }
        
        
        if let imageData = self.selectedItemData,
           let compressedImage = UIImage(data: imageData)?.jpegData(compressionQuality: 0.01) {
            
            let storageRef = Storage.storage().reference().child("\(userToUpdate.userId).png")
            
            // Uploading image to Firestore
            storageRef.putData(compressedImage, metadata: nil) { metadata, error in
                if let error = error {
                    self.inProgress = false
                    print("Error uploading image to firestore: ", error.localizedDescription)
                    return
                } else {
                    storageRef.downloadURL { url, error in
                        let imageURL = url?.absoluteString
                        
                        userToUpdate.updateProfile(nickname: self.nickname, photo: imageURL, accountState: self.selectedState)
                        UserManager.shared.updateProfile(userDB: userToUpdate)
                        self.inProgress = false
                        
                        userUpdatedCompletionHandler() // Fetch user information again
                    }
                }
            }
            
        } else {
            // Update user profile without image
            
            userToUpdate.updateProfile(nickname: self.nickname, photo: nil, accountState: self.selectedState)
            UserManager.shared.updateProfile(userDB: userToUpdate)
            self.inProgress = false
            
            userUpdatedCompletionHandler() // Fetch user information again
        }
        
    }
}

struct ProfileSettings: View {
    
    let didUpdateProfile: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm: ProfileSettingsViewModel = ProfileSettingsViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("Choose your profile photo and your nickname") {
                        TextField("Name", text: self.$vm.nickname)
                        PhotosPicker(
                            selection: self.$vm.selectedItem,
                            matching: .images,
                            photoLibrary: .shared()) {
                            Text("Edit photo")
                                .padding(10)
                                .background {
                                    Color.gray
                                        .cornerRadius(10)
                                }
                                .foregroundColor(.white)
                                    
                        }
                            .onChange(of: self.vm.selectedItem) { newItem in
                                Task {
                                    // Retrieve selected asset in the form of Data
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        self.vm.selectedItemData = data
                                    }
                                }
                            }
                        
                        if let photo = self.vm.userDB?.profileImageUrl,
                           photo.contains("http") &&
                            self.vm.selectedItem == nil {
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
                        } else if let selectedImageData = self.vm.selectedItemData,
                            let uiImage = UIImage(data: selectedImageData) {
                            HStack(alignment: .center) {
                                Spacer()
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .frame(width: 150, height: 150)
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(20)
                                    .shadow(radius: 10, x: 5, y: 5)
                                    .padding(6)
                                Spacer()
                            }
                        }
                    }
                    Section("Account State") {
                        Picker("Choose state", selection: self.$vm.selectedState) {
                            ForEach(AccountState.allCases) { state in
                                Text(state.rawValue).tag(state)
                            }
                        }
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !self.vm.inProgress {
                        Button {
                            self.vm.updateUserInformation(userUpdatedCompletionHandler: {
                                didUpdateProfile()
                            })
                        } label: {
                            HStack {
                                Text("Save")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        ProgressView()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await self.vm.loadUserData()
            }
        }
        
    }
}

struct ProfileSettings_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSettings {
            
        }
    }
}
