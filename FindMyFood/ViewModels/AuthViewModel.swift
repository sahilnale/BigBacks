import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var email = ""
    @Published var password = ""
    
    func login() {
        // Implement login logic
        isLoggedIn = true
    }
    
    func signUp(firstName: String, lastName: String, email: String, password: String) {
        // Implement signup logic
        isLoggedIn = true
    }
}
