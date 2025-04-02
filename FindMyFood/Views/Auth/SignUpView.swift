import SwiftUI
import PhotosUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var name = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var shouldNavigateToVerifyEmail = false
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedProfileImage: UIImage? = nil

    private var isFormValid: Bool {
        !name.isEmpty &&
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        password.count >= 8
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile Picture Section
                VStack {
                    if let image = selectedProfileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 4)
                            )
                            .onTapGesture {
                                showImagePicker = true
                            }
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Text("Add Profile Picture")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .frame(alignment: .center)
                            )
                            .onTapGesture {
                                showImagePicker = true
                            }
                    }
                }

                // Form Title
                Text("Sign Up")
                    .font(.system(.largeTitle, design: .serif))
                    .fontWeight(.bold)
                    .foregroundColor(Color.accentColor)

                // Form Fields
                VStack(spacing: 15) {
                    InputField(iconName: "person", placeholder: "Full Name", text: $name)
                    InputField(iconName: "person.fill", placeholder: "Username", text: $username)
                    InputField(iconName: "envelope", placeholder: "Email address", text: $email, keyboardType: .emailAddress)
                    SecureInputField(isPasswordVisible: $isPasswordVisible, text: $password, placeholder: "Password")
                    SecureInputField(isPasswordVisible: $isConfirmPasswordVisible, text: $confirmPassword, placeholder: "Confirm Password")
                    if password != confirmPassword && !confirmPassword.isEmpty {
                        Text("Passwords do not match")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                // Sign-Up Button
                // Sign-Up Button
                Button(action: {
                    shouldNavigateToVerifyEmail = true // Navigate to VerifyEmailView
                }) {
                    Text("Sign Up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid || authViewModel.isLoading)
                .padding(.top, 10)

                // Navigation to Verify Email
                NavigationLink(
                    destination: VerifyEmailView(
                        name: name,
                        username: username,
                        email: email,
                        password: password,
                        profileImageData: selectedProfileImage?.jpegData(compressionQuality: 0.8) // Pass image data
                    )
                    .environmentObject(authViewModel),
                    isActive: $shouldNavigateToVerifyEmail,
                    label: { EmptyView() }
                )
            }
            .padding()
            .alert("Error", isPresented: $authViewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(authViewModel.error ?? "An unknown error occurred")
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(
                    sourceType: sourceType,
                    selectedImage: $selectedProfileImage
                )
            }
        }
    }
}


struct ProfileImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ProfileImagePicker

        init(_ parent: ProfileImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}




// MARK: - Reusable InputField Component
struct InputField: View {
    let iconName: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - SecureInputField Component
struct SecureInputField: View {
    @Binding var isPasswordVisible: Bool
    @Binding var text: String
    let placeholder: String

    var body: some View {
        ZStack {
            HStack {
                Image(systemName: "lock")
                    .foregroundColor(.gray)
                if isPasswordVisible {
                    TextField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .padding(.trailing, 50)

            HStack {
                Spacer()
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 5)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
}

