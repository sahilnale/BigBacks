import Firebase
import SwiftUI
import FirebaseAuth
import FirebaseStorage

@MainActor
class AuthViewModel: ObservableObject {
    
    
    @Published var error: String?
    @Published var isLoading = false
    @Published var showError = false
    
    @Published var currentUser: User? = nil


    func fetchCurrentUser() async throws -> User {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in."])
        }

        let db = Firestore.firestore()
        let userDoc = try await db.collection("users").document(userId).getDocument()

        guard let data = userDoc.data(),
              let name = data["name"] as? String,
              let username = data["username"] as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user data."])
        }

        return User(
            id: userId,
            name: name,
            username: username,
            email: data["email"] as? String ?? "",
            friends: data["friends"] as? [String] ?? [],
            friendRequests: data["friendRequests"] as? [String] ?? [],
            pendingRequests: data["pendingRequests"] as? [String] ?? [],
            posts: [], // Handle posts separately if needed
            profilePicture: data["profilePicture"] as? String,
            loggedIn: true
        )
    }
    
    
    
    var isLoggedIn: Bool {
        currentUser != nil
    }
    
    func signUp(name: String, username: String, email: String, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        Task {
            do {
                // Create user with Firebase Authentication
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                let userId = result.user.uid
                
                // Save additional user details to Firestore
                let user = User(
                    id: userId,
                    name: name,
                    username: username,
                    email: email,
                    friends: [],
                    friendRequests: [],
                    pendingRequests: [],
                    posts: [],
                    profilePicture: nil,
                    loggedIn: true
                )
                
                let db = Firestore.firestore()
                try await db.collection("users").document(userId).setData([
                    "id": userId,
                    "name": name,
                    "username": username,
                    "email": email,
                    "friends": [],
                    "friendRequests": [],
                    "pendingRequests": [],
                    "posts": [],
                    "profilePicture": "",
                    "loggedIn": true
                ])
                
                await MainActor.run {
                    self.currentUser = user
                    self.isLoading = false
                    completion(true) // Sign-up succeeded
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.showError = true
                    self.isLoading = false
                    completion(false) // Sign-up failed
                }
            }
        }
    }

    
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        Task {
            do {
                // Sign in the user with Firebase Authentication
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                let userId = result.user.uid
                
                // Fetch user details from Firestore
                let db = Firestore.firestore()
                let userDoc = try await db.collection("users").document(userId).getDocument()
                
                if let data = userDoc.data(),
                   let name = data["name"] as? String,
                   let username = data["username"] as? String {
                    let user = User(
                        id: userId,
                        name: name,
                        username: username,
                        email: email,
                        friends: data["friends"] as? [String] ?? [],
                        friendRequests: data["friendRequests"] as? [String] ?? [],
                        pendingRequests: data["pendingRequests"] as? [String] ?? [],
                        posts: [], // Assume posts are fetched separately
                        profilePicture: data["profilePicture"] as? String,
                        loggedIn: true
                    )
                    
                    await MainActor.run {
                        self.currentUser = user
                        self.isLoading = false
                        completion(true) // Login successful
                    }
                } else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found."])
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.showError = true
                    self.isLoading = false
                    completion(false) // Login failed
                }
            }
        }
    }

    
    func logout() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
        } catch {
            self.error = error.localizedDescription
            self.showError = true
        }
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
    
    func addPost(
            imageData: Data,
            review: String,
            location: String,
            restaurantName: String,
            starRating: Int
        ) async throws -> Post {
            guard let userId = Auth.auth().currentUser?.uid else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])
            }
            
            print("in progress")

            // Step 1: Upload Image to Firebase Storage
            let imageRef = Storage.storage().reference().child("posts/\(UUID().uuidString).jpg")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

            let uploadTask = try await imageRef.putDataAsync(imageData, metadata: metadata)
            let imageUrl = try await imageRef.downloadURL().absoluteString

            // Step 2: Save Post in Firestore
            let db = Firestore.firestore()
            let postId = UUID().uuidString
            let newPost: [String: Any] = [
                "id": postId,
                "userId": userId,
                "imageUrl": imageUrl,
                "timestamp": FieldValue.serverTimestamp(),
                "review": review,
                "location": location,
                "restaurantName": restaurantName,
                "starRating": starRating,
                "likes": 0,
                "likedBy": [],
                "comments": []
            ]

            try await db.collection("posts").document(postId).setData(newPost)

            // Step 3: Update Current User's Posts
            let userRef = db.collection("users").document(userId)
            try await userRef.updateData([
                "posts": FieldValue.arrayUnion([postId])
            ])

            // Return the created post object
            return Post(
                _id: postId,
                userId: userId,
                imageUrl: imageUrl,
                timestamp: "", // You can fetch the timestamp from Firestore if needed
                review: review,
                location: location,
                restaurantName: restaurantName,
                likes: 0,
                likedBy: [],
                starRating: starRating,
                comments: []
            )
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
