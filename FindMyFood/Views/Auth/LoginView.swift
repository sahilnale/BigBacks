import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            TextField("Email address", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Login") {
                authViewModel.login()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button("Forgot password?") {
                // Implement forgot password
            }
            .foregroundColor(.orange)
            
            HStack {
                Text("Don't have an account?")
                NavigationLink("Sign up here", destination: SignUpView())
                    .foregroundColor(.orange)
            }
        }
        .padding()
    }
}
