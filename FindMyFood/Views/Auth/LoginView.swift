import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var canNavigate = false
    @State private var showingLocalError = false
    @State private var localErrorMessage = ""

    var body: some View {
        VStack(spacing: 30) {
            // Title
//            Text("Login")
//                .font(.system(.largeTitle, design: .serif))
//                .fontWeight(.bold)
//                .foregroundColor(Color.accentColor)

            // Input Fields
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.gray)
                    TextField("Email", text: $email)
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
                    .padding(.trailing, 50) // Increased space for the eye icon

                    HStack {
                        Spacer()
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 5) // Fine-tune this value to move it further to the right
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                
                // Error message display
                if showingLocalError {
                    Text(localErrorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.top, 4)
                        .transition(.opacity)
                }
            }

            // Login Button
            Button(action: {
                // Reset error state when attempting to login
                showingLocalError = false
                
                authViewModel.login(email: email, password: password) { success in
                    if success {
                        canNavigate = true
                    } else if let errorMessage = authViewModel.error {
                        // Show the error locally instead of in an alert
                        localErrorMessage = errorMessage
                        showingLocalError = true
                    }
                }
            }) {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Login")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(email.isEmpty || password.isEmpty || authViewModel.isLoading ? Color.gray : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
            .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)

            .font(.headline)
            .foregroundColor(Color.accentColor)

            // Sign-Up Navigation
            HStack {
                Text("Don't have an account?")
                    .font(.body)
                NavigationLink("Sign up here", destination: SignUpView())
                    .font(.headline)
                    .foregroundColor(Color.accentColor)
            }
            
            HStack{
                NavigationLink("Forgot Password?", destination: ResetPasswordView())
                    .font(.headline)
                    .foregroundColor(Color.accentColor)
            }
        }
        .padding()
        .animation(.easeInOut(duration: 0.2), value: showingLocalError)
        // We'll keep the alert for other types of errors, but login errors will be shown inline
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK", role: .cancel) {
                authViewModel.showError = false
            }
        } message: {
            Text(authViewModel.error ?? "An unknown error occurred")
        }
        .onChange(of: authViewModel.error) { newError in
            if newError != nil && !authViewModel.showError {
                // If there's an error but the alert isn't showing, display it locally
                localErrorMessage = newError ?? ""
                showingLocalError = true
            }
        }
    }
}
