import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var error: NetworkError?
    @Published var isLoading = false
    @Published var showError = false
    
    var isLoggedIn: Bool {
        currentUser != nil
    }
    
    func login(email: String, password: String) {
        isLoading = true
        
        Task {
            do {
                let user = try await NetworkManager.shared.login(email: email, password: password)
                self.currentUser = user
                self.isLoading = false
            } catch let error as NetworkError {
                self.error = error
                self.showError = true
                self.isLoading = false
            } catch {
                self.error = .serverError(error.localizedDescription)
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    func signUp(name: String, username: String, email: String, password: String) {
        isLoading = true
        
        Task {
            do {
                let user = try await NetworkManager.shared.signUp(
                    name: name,
                    username: username,
                    email: email,
                    password: password
                )
                self.currentUser = user
                self.isLoading = false
            } catch let error as NetworkError {
                self.error = error
                self.showError = true
                self.isLoading = false
            } catch {
                self.error = .serverError(error.localizedDescription)
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    func logout() {
        currentUser = nil
    }
    
    // Helper method to validate email format
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // Helper method to validate password strength
    func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters long
        guard password.count >= 8 else { return false }
        
        // Contains at least one uppercase letter
        let uppercaseRegex = ".*[A-Z]+.*"
        // Contains at least one lowercase letter
        let lowercaseRegex = ".*[a-z]+.*"
        // Contains at least one number
        let numberRegex = ".*[0-9]+.*"
        
        let uppercasePredicate = NSPredicate(format: "SELF MATCHES %@", uppercaseRegex)
        let lowercasePredicate = NSPredicate(format: "SELF MATCHES %@", lowercaseRegex)
        let numberPredicate = NSPredicate(format: "SELF MATCHES %@", numberRegex)
        
        return uppercasePredicate.evaluate(with: password) &&
               lowercasePredicate.evaluate(with: password) &&
               numberPredicate.evaluate(with: password)
    }
}
