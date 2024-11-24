import SwiftUI
import Firebase
import FirebaseStorage

// ImageUploader Class
import Firebase
import FirebaseStorage
import UIKit

class ImageUploader {
    static func uploadImage(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageConversion", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to convert image to data."])))
            return
        }
        
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("images/\(UUID().uuidString).jpg")
        
        let uploadTask = imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let downloadURL = url {
                    completion(.success(downloadURL.absoluteString))
                }
            }
        }
        
        uploadTask.observe(.progress) { snapshot in
            if let progress = snapshot.progress {
                print("Upload progress: \(progress.completedUnitCount) / \(progress.totalUnitCount)")
            }
        }
    }
}


// SwiftUI View
struct ImageUploaderView: View {
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var uploadStatus: String = "No image uploaded yet."
    @State private var isUploading = false

    var body: some View {
        VStack(spacing: 20) {
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

            Button("Select Image") {
                isImagePickerPresented = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)

            Button("Upload Image") {
                if let image = selectedImage {
                    isUploading = true
                    ImageUploader.uploadImage(image: image) { result in
                        DispatchQueue.main.async {
                            isUploading = false
                            switch result {
                            case .success(let url):
                                uploadStatus = "Upload successful! URL: \(url)"
                            case .failure(let error):
                                uploadStatus = "Upload failed: \(error.localizedDescription)"
                            }
                        }
                    }
                } else {
                    uploadStatus = "Please select an image first."
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
