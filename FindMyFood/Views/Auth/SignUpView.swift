import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPasswordMismatch = false
    @State private var isSignedUp = false
    @State private var navigateToMainView = false
    private let mapViewModel = MapViewModel() // Instance of MapViewModel
    
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
        VStack(spacing: 20) {
            Text("Sign Up")
                .font(.largeTitle)
                .foregroundColor(Color.accentColor)
            
            TextField("Full Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled()
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            
            TextField("Email address", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
            
            TextField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if password != confirmPassword && !confirmPassword.isEmpty {
                Text("Passwords do not match")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            NavigationLink(
                destination: MapView(viewModel: mapViewModel),
                isActive: $navigateToMainView
            ) {
                Button(action: {
                    guard password == confirmPassword else {
                        showPasswordMismatch = true
                        return
                    }
                    authViewModel.signUp(
                        name: name,
                        username: username,
                        email: email,
                        password: password
                    )
                    navigateToMainView = true
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign Up")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!isFormValid || authViewModel.isLoading)
            }
            
            HStack {
                Text("Already have an account?")
                NavigationLink("Login here", destination: LoginView())
                    .foregroundColor(Color.accentColor)
            }
            .padding()
            .alert("Error", isPresented: $authViewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(authViewModel.error?.errorDescription ?? "An unknown error occurred")
            }
            .onChange(of: authViewModel.isLoggedIn) { newValue in
                if newValue {
                    dismiss()
                }
            }
        }
    }
}
