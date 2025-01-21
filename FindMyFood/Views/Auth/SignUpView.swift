import SwiftUI

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
    @State private var selectedProfileImage: UIImage? = nil
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

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
                // Profile Picture Section (optional)
                VStack {
                    if let image = selectedProfileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.customOrange, lineWidth: 4)
                            )
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Text("Add Profile Picture")
                                    .font(.headline)
                                    .foregroundColor(.gray)
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
                    .foregroundColor(Color.customOrange)

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
                Button(action: {
                    let profileImageData = selectedProfileImage?.jpegData(compressionQuality: 0.8)
                    authViewModel.signUp(
                        name: name,
                        username: username,
                        email: email,
                        password: password,
                        profileImageData: profileImageData
                    ) { success in
                        if success {
                            shouldNavigateToVerifyEmail = true
                        }
                    }
                }) {
                    Text("Sign Up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.customOrange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid || authViewModel.isLoading)
                .padding(.top, 10)

                NavigationLink(
                    destination: VerifyEmailView()
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

