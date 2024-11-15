import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.largeTitle)
                .foregroundColor(Color.accentColor)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: {
                authViewModel.login(email: email, password: password)
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
            .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
            
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
