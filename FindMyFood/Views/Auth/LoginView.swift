import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var canNavigate = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.largeTitle)
                .foregroundColor(Color.accentColor)
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                VStack {
                    Button(action: {
                        authViewModel.login(username: username, password: password) { success in
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
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(username.isEmpty || password.isEmpty || authViewModel.isLoading)
                }
                .navigationDestination(isPresented: $canNavigate) {
                    MainView()
                }
            
            Button("Forgot password?") {
                // Implement forgot password
            }
            .foregroundColor(Color.accentColor)
            
            HStack {
                Text("Don't have an account?")
                NavigationLink("Sign up here", destination: SignUpView())
                    .foregroundColor(Color.accentColor)
            }
        }
        .padding()
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authViewModel.error?.errorDescription ?? "An unknown error occurred")
        }
    }
}
