import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var shouldNavigate = false

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
        VStack(spacing: 30) {
            // Title
            Text("Sign Up")
                .font(.system(.largeTitle, design: .serif))
                .fontWeight(.bold)
                .foregroundColor(Color.accentColor)

            // Input Fields
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.gray)
                    TextField("Full Name", text: $name)
                        .autocorrectionDisabled()
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)

                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)

                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.gray)
                    TextField("Email address", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)

                ZStack {
                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.gray)
                        if isPasswordVisible {
                            TextField("Password", text: $password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Password", text: $password)
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

                ZStack {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                        if isConfirmPasswordVisible {
                            TextField("Confirm Password", text: $confirmPassword)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                    }
                    .padding(.trailing, 50)

                    HStack {
                        Spacer()
                        Button(action: {
                            isConfirmPasswordVisible.toggle()
                        }) {
                            Image(systemName: isConfirmPasswordVisible ? "eye" : "eye.slash")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 5)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)

                if password != confirmPassword && !confirmPassword.isEmpty {
                    Text("Passwords do not match")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            // Sign-Up Button
            Button(action: {
                authViewModel.signUp(name: name, username: username, email: email, password: password) { success in
                    if success {
                        shouldNavigate = true
                    }
                }
            }) {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                }
            }
            .disabled(!isFormValid || authViewModel.isLoading)
            .navigationDestination(isPresented: $shouldNavigate) {
                MainTabView()
            }

            // Already have an account?
            HStack {
                Text("Already have an account?")
                    .font(.body)
                NavigationLink("Login here", destination: LoginView())
                    .font(.headline)
                    .foregroundColor(Color.accentColor)
            }
        }
        .padding()
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authViewModel.error ?? "An unknown error occurred")
        }
    }
}
