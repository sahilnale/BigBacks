////
////  EditProfileView.swift
////  FindMyFood
////
////  Created by Rishik Durvasula on 11/6/24.
////
//
//import SwiftUI
//import UIKit
//
//struct EditProfileView: View {
//    @State private var showImagePicker = false
//    @State private var selectedImage: UIImage? = nil
//    @State private var username: String = ""
//    @State private var name: String = ""
//    @State private var email: String = ""
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 30) {
//            // Profile Image
//            HStack {
//                Spacer()
//                if let image = selectedImage {
//                    Image(uiImage: image)
//                        .resizable()
//                        .scaledToFill()
//                        .frame(width: 120, height: 120)
//                        .clipShape(Circle())
//                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
//                        .shadow(radius: 5)
//                } else {
//                    Image(systemName: "person.circle.fill")
//                        .font(.system(size: 120))
//                        .foregroundColor(.gray)
//                }
//                Spacer()
//            }
//            
//            // Button to trigger image picker
//            HStack {
//                Spacer()
//                Button(action: {
//                    showImagePicker = true
//                }) {
//                    Text("Change Profile Picture")
//                        .font(.headline)
//                        
//                        .padding(.top, 5)
//                }
//                Spacer()
//            }
//            
//            // Editable Fields
//            VStack(spacing: 20) {
//                CustomTextField(placeholder: "Username", text: $username)
//                CustomTextField(placeholder: "Name", text: $name)
//                CustomTextField(placeholder: "Email", text: $email)
//            }
//            
//            Spacer()
//        }
//        .padding()
//        .sheet(isPresented: $showImagePicker) {
//            ImagePicker(sourceType: .photoLibrary, selectedImage: $selectedImage)
//        }
//        .navigationTitle("Edit Profile")
//    }
//}
//
//// Custom TextField for larger styling
//struct CustomTextField: View {
//    var placeholder: String
//    @Binding var text: String
//    
//    var body: some View {
//        TextField(placeholder, text: $text)
//            .padding()
//            .frame(height: 50)
//            .background(Color(UIColor.systemGray6))
//            .cornerRadius(10)
//            .font(.system(size: 18))
//    }
//}
//
//// ImagePicker Component
//struct ImagePicker: UIViewControllerRepresentable {
//    var sourceType: UIImagePickerController.SourceType
//    @Binding var selectedImage: UIImage?
//    
//    func makeUIViewController(context: Context) -> UIImagePickerController {
//        let picker = UIImagePickerController()
//        picker.delegate = context.coordinator
//        picker.sourceType = sourceType
//        return picker
//    }
//    
//    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//    
//    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
//        let parent: ImagePicker
//        
//        init(_ parent: ImagePicker) {
//            self.parent = parent
//        }
//        
//        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
//            if let image = info[.originalImage] as? UIImage {
//                parent.selectedImage = image
//            }
//            picker.dismiss(animated: true)
//        }
//        
//        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//            picker.dismiss(animated: true)
//        }
//    }
//}
//
//
//
//
//#Preview {
//    EditProfileView()
//}
