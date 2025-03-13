//
//  EditProfileView 2.swift
//  FindMyFood
//
//  Created by Sahil Nale on 1/31/25.
//
import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var profileViewModel: ProfileViewModel
    
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Profile Picture Section
                Button(action: {
                    showImagePicker = true
                }) {
                    VStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 300, height: 300)
                                .clipShape(Circle())
                        } else {
                            AsyncImage(url: URL(string: authViewModel.currentUser?.profilePicture ?? "")) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 300, height: 300)
                                    .clipShape(Circle())
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 300, height: 300)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text("Change Profile Picture")
                            .font(.caption)
                            .foregroundColor(.customOrange)
                            .padding(.top, 8)
                    }
                }
                
                // Save Button
                Button(action: saveChanges) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Save Changes")
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.customOrange)
                .cornerRadius(10)
                .disabled(authViewModel.isLoading || selectedImage == nil)
                .padding(.horizontal)
                .opacity(selectedImage == nil ? 0.5 : 1.0)
                
                Spacer()
            }
            .navigationTitle("Edit Profile Picture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: .photoLibrary, selectedImage: $selectedImage)
            }
            .alert("Profile Update", isPresented: $authViewModel.showError) {
                Button("OK") {
                    if authViewModel.error?.contains("successfully") ?? false {
                        dismiss()
                    }
                }
            } message: {
                Text(authViewModel.error ?? "Unknown error")
            }
        }
    }
    
    private func saveChanges() {
        guard let userId = authViewModel.currentUser?.id,
              let imageData = selectedImage?.jpegData(compressionQuality: 0.8) else { return }
        
        authViewModel.updateFirestoreUser(
            userId: userId,
            name: authViewModel.currentUser?.name ?? "",
            username: authViewModel.currentUser?.username ?? "",
            email: authViewModel.currentUser?.email ?? "",
            profileImageData: imageData
        ) { success in
            if success {
                Task {
                    // Reload profile data before dismissing
                    await profileViewModel.loadProfile()
                    await MainActor.run {
                        dismiss()
                    }
                }
            }
        }
    }
}
