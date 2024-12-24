import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var canNavigate = false

    var body: some View {
        VStack(spacing: 30) {
            // Title
            Text("Login")
                .font(.system(.largeTitle, design: .serif))
                .fontWeight(.bold)
                .foregroundColor(Color.customOrange)

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

            }

            // Login Button
            Button(action: {
                authViewModel.login(email: email, password: password) { success in
                    if success {
                        canNavigate = true
                    }
                }
            }) {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Login")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(username.isEmpty || password.isEmpty || authViewModel.isLoading ? Color.gray : Color.customOrange)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
            .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)

            .font(.headline)
            .foregroundColor(Color.customOrange)

            // Sign-Up Navigation
            HStack {
                Text("Don't have an account?")
                    .font(.body)
                NavigationLink("Sign up here", destination: SignUpView())
                    .font(.headline)
                    .foregroundColor(Color.customOrange)
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
