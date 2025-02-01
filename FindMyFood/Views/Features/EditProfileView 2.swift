//
//  EditProfileView 2.swift
//  FindMyFood
//
//  Created by Sahil Nale on 1/31/25.
//
import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var name = ""
    @State private var email = ""
    
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
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            AsyncImage(url: URL(string: "YOUR_PROFILE_URL")) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text("Change Profile Picture")
                            .font(.caption)
                            .foregroundColor(.customOrange)
                            .padding(.top, 8)
                    }
                }
                
                // Form Fields
                VStack(spacing: 16) {
                    TextField("Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    Button(action: {
                        // Save changes action
                    }) {
                        Text("Save Changes")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.customOrange)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .navigationTitle("Edit Profile")
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
        }
    }
}
