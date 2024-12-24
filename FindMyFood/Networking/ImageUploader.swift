import SwiftUI
import Firebase
import FirebaseStorage

// ImageUploader Class
import Firebase
import FirebaseStorage
import UIKit

class ImageUploader {
    static func uploadImageAsync(image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageUploader", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data."])
        }
        
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("images/\(UUID().uuidString).jpg")
        
        return try await withCheckedThrowingContinuation { continuation in
            imageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                imageRef.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let url = url {
                        continuation.resume(returning: url.absoluteString)
                    }
                }
            }
        }
    }
}


// SwiftUI View
    import SwiftUI

    struct ImageUploaderView: View {
        @State private var selectedImage: UIImage?
        @State private var isImagePickerPresented = false
        @State private var uploadStatus: String = "No image uploaded yet."
        @State private var isUploading = false

        var body: some View {
            VStack(spacing: 20) {
                // Image Preview
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 200, height: 200)
                        .overlay(Text("No Image Selected").foregroundColor(.white))
                }

                // Select Image Button
                Button("Select Image") {
                    isImagePickerPresented = true
                }
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)

                // Upload Image Button
                Button("Upload Image") {
                    Task {
                        await uploadImage()
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(isUploading)

                if isUploading {
                    ProgressView()
                }

                Text(uploadStatus)
                    .padding()
                    .foregroundColor(.gray)
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker1(image: $selectedImage)
            }
            .padding()
        }

        private func uploadImage() async {
            guard let image = selectedImage else {
                uploadStatus = "Please select an image first."
                return
            }

            isUploading = true
            do {
                let imageURL = try await ImageUploader.uploadImageAsync(image: image)
                uploadStatus = "Upload successful! URL: \(imageURL)"
            } catch {
                uploadStatus = "Upload failed: \(error.localizedDescription)"
            }
            isUploading = false
        }
    }

    // Image Picker for SwiftUI
    struct ImagePicker1: UIViewControllerRepresentable {
        @Binding var image: UIImage?

        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
            let parent: ImagePicker1

            init(parent: ImagePicker1) {
                self.parent = parent
            }

            func imagePickerController(
                _ picker: UIImagePickerController,
                didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
            ) {
                if let uiImage = info[.originalImage] as? UIImage {
                    parent.image = uiImage
                }
                picker.dismiss(animated: true)
            }

            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                picker.dismiss(animated: true)
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }

        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            return picker
        }

        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    }

    // Preview
    struct ImageUploaderView_Previews: PreviewProvider {
        static var previews: some View {
            ImageUploaderView()
        }
    }
