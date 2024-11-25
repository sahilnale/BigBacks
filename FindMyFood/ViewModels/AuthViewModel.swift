import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User? {
        didSet {
            // Save currentUser to UserDefaults when it changes
            if let user = currentUser {
                if let encodedUser = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(encodedUser, forKey: "currentUser")
                }
                // Save ID to Keychain
                AuthManager.shared.setUserId(user.id)
            } else {
                // Clear both UserDefaults and Keychain if user logs out
                UserDefaults.standard.removeObject(forKey: "currentUser")
                AuthManager.shared.clearUserId()
            }
        }
    }
    
    @Published var error: NetworkError?
    @Published var isLoading = false
    @Published var showError = false
    
    var isLoggedIn: Bool {
        currentUser != nil && AuthManager.shared.isLoggedIn
    }
    
    init() {
        if AuthManager.shared.isLoggedIn {
            if let savedUserData = UserDefaults.standard.data(forKey: "currentUser"),
               let decodedUser = try? JSONDecoder().decode(User.self, from: savedUserData) {
                self.currentUser = decodedUser
            } else {
                Task {
                    await refreshCurrentUser()
                }
            }
        }
    }
    
    func refreshCurrentUser() async {
        guard let userId = AuthManager.shared.userId else { return }
        
        do {
            let user = try await NetworkManager.shared.getCurrentUser(userId: userId)
            await MainActor.run {
                self.currentUser = user
            }
        } catch {
            await MainActor.run {
                self.logout()
            }
        }
    }
    
    func login(username: String, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        Task {
            do {
                let user = try await NetworkManager.shared.login(username: username, password: password)
                self.currentUser = user
                self.isLoading = false
                print("LOGGED IN: ", user)
                completion(true)
            } catch let error as NetworkError {
                self.error = error
                self.showError = true
                self.isLoading = false
                completion(false)
            } catch {
                self.error = .serverError(error.localizedDescription)
                self.showError = true
                self.isLoading = false
                completion(false)
            }
        }
    }
    
    func signUp(name: String, username: String, email: String, password: String, completion: @escaping (Bool) -> Void) {
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
                login(username: username, password: password) { success in
                    if success {
                        print("Login successful!")
                    } else {
                        print("Login failed.")
                    }
                }
                completion(true)
            } catch let error as NetworkError {
                self.error = error
                self.showError = true
                self.isLoading = false
                completion(false)
            } catch {
                self.error = .serverError(error.localizedDescription)
                self.showError = true
                self.isLoading = false
                completion(false)
            }
        }
    }
    
    func logout() {
        currentUser = nil
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }
        
        let uppercaseRegex = ".*[A-Z]+.*"
        let lowercaseRegex = ".*[a-z]+.*"
        let numberRegex = ".*[0-9]+.*"
        
        let uppercasePredicate = NSPredicate(format: "SELF MATCHES %@", uppercaseRegex)
        let lowercasePredicate = NSPredicate(format: "SELF MATCHES %@", lowercaseRegex)
        let numberPredicate = NSPredicate(format: "SELF MATCHES %@", numberRegex)
        
        return uppercasePredicate.evaluate(with: password) &&
               lowercasePredicate.evaluate(with: password) &&
               numberPredicate.evaluate(with: password)
    }
}

import Foundation
import Security

class AuthManager {
    static let shared = AuthManager()
    
    private let userIdKey = "com.bigbacksapp.userId"
    private init() {}
    
    var userId: String? {
        get {
            return KeychainHelper.load(key: userIdKey)
        }
        set {
            if let newValue = newValue {
                KeychainHelper.save(newValue, key: userIdKey)
            } else {
                KeychainHelper.delete(key: userIdKey)
            }
        }
    }
    
    func setUserId(_ id: String) {
        userId = id
    }
    
    func clearUserId() {
        userId = nil
    }
    
    var isLoggedIn: Bool {
        return userId != nil
    }
}

// Helper class for Keychain operations
private class KeychainHelper {
    static func save(_ value: String, key: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            print("Error saving to Keychain: \(status)")
            return
        }
    }
    
    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }
        return nil
    }
    
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
