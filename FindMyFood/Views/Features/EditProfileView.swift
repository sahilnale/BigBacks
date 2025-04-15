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
    @State private var showDeleteConfirmation = false
    
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
                
                // Delete Account Button
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Text("Delete Account")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
                .padding(.horizontal)
                
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
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone.")
            }
        }
    }
    
    private func deleteAccount() {
        guard let userId = authViewModel.currentUser?.id else { return }
        authViewModel.deleteAccount(userId: userId) { success in
            if success {
                dismiss()
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
