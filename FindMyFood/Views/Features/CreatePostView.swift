import SwiftUI

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss // Use dismiss to go back in the navigation stack
    @State private var postText: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false

    var body: some View {
        VStack(spacing: 20) {
            // Image Picker or Placeholder
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .cornerRadius(10)
                    .padding()
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 250)
                    .overlay(
                        Text("Tap to add an image")
                            .foregroundColor(.gray)
                    )
                    .onTapGesture {
                        showImagePicker = true
                    }
                    .padding()
            }

            // Post TextEditor
            ZStack(alignment: .topLeading) {
                if postText.isEmpty {
                    Text("Write your review here...")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $postText)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                    .frame(height: 150)
            }

            // Post Button
            Button("Post") {
                postReview()
            }
            .padding()
            .disabled(postText.isEmpty) // Disable button if text is empty

            Spacer()
        }
        .padding()
        .navigationTitle("Create Post")
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
    
    private func postReview() {
        // Perform any necessary logic for posting
        print("Posting: \(postText)")
        dismiss() // Navigate back in the stack
    }
}

// Simple ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
