import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var username = ""
    @Published var password = ""
    
    func login() {
        // Implement login logic
        isLoggedIn = true
    }
    
    func signUp(firstName: String, lastName: String, username: String, email: String, password: String) {
        // Implement signup logic
        isLoggedIn = true
    }
}
