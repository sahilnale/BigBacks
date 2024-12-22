import Firebase
import SwiftUI
import FirebaseAuth
import FirebaseStorage

@MainActor
class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()
    
    
    @Published var error: String?
    @Published var isLoading = false
    @Published var showError = false
    
    @Published var currentUser: User? = nil
    
    
    init() {
            Task {
                await loadCurrentUser()
            }
        }
    
    func loadCurrentUser() async {
            guard let firebaseUser = Auth.auth().currentUser else {
                self.currentUser = nil
                return
            }

            let db = Firestore.firestore()
            do {
                let userDoc = try await db.collection("users").document(firebaseUser.uid).getDocument()
                
                guard let data = userDoc.data(),
                      let name = data["name"] as? String,
                      let username = data["username"] as? String,
                      let email = data["email"] as? String else {
                    self.currentUser = nil
                    return
                }

                await MainActor.run {
                    self.currentUser = User(
                        id: firebaseUser.uid,
                        name: name,
                        username: username,
                        email: email,
                        friends: data["friends"] as? [String] ?? [],
                        friendRequests: data["friendRequests"] as? [String] ?? [],
                        pendingRequests: data["pendingRequests"] as? [String] ?? [],
                        posts: [],
                        profilePicture: data["profilePicture"] as? String,
                        loggedIn: true
                    )
                }
            } catch {
                print("Failed to fetch current user: \(error.localizedDescription)")
                self.currentUser = nil
            }
        }


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
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                let userId = result.user.uid
                
                let db = Firestore.firestore()
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
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    completion(false)
                }
            }
        }
    }


    
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        Task {
            do {
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                let userId = result.user.uid
                
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
                        posts: [],
                        profilePicture: data["profilePicture"] as? String,
                        loggedIn: true
                    )
                    
                    await MainActor.run {
                        self.currentUser = user
                        self.isLoading = false
                        completion(true)
                    }
                } else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found."])
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    completion(false)
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
            
            let isoFormatter = ISO8601DateFormatter()
                isoFormatter.timeZone = TimeZone(abbreviation: "UTC")
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                let isoTimestampString = isoFormatter.string(from: Date())

            // Step 2: Save Post in Firestore
            let db = Firestore.firestore()
            let postId = UUID().uuidString
            let newPost: [String: Any] = [
                "id": postId,
                "userId": userId,
                "imageUrl": imageUrl,
                "timestamp": isoTimestampString,
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
    
    func getUserById(friendId: String) async throws -> User? {
        let userDocument = try await Firestore.firestore()
            .collection("users")
            .document(friendId)
            .getDocument()

        guard let data = userDocument.data() else {
            throw UserFetchError.documentNotFound
        }

        // Manual decoding of Firestore document
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let username = data["username"] as? String,
              let email = data["email"] as? String,
              let friends = data["friends"] as? [String],
              let friendRequests = data["friendRequests"] as? [String],
              let pendingRequests = data["pendingRequests"] as? [String],
              let posts = data["posts"] as? [String] else {
            throw NetworkError.decodingError
        }

        let profilePicture = data["profilePicture"] as? String
        let loggedIn = data["loggedIn"] as? Bool ?? false

        return User(
            id: id,
            name: name,
            username: username,
            email: email,
            friends: friends,
            friendRequests: friendRequests,
            pendingRequests: pendingRequests,
            posts: [], // Assuming `Post` initializer for post IDs
            profilePicture: profilePicture,
            loggedIn: loggedIn
        )
    }
    
    func searchUsers(by usernamePrefix: String) async throws -> [User] {
        let db = Firestore.firestore()
        let usersRef = db.collection("users")
        var users: [User] = []
        
        // Convert the search prefix to lowercase
        let lowercasedPrefix = usernamePrefix.lowercased()
        let endString = lowercasedPrefix + "\u{f8ff}" // Add a high Unicode character to create the upper bound
        
        do {
            // Query using the lowercased prefix
            let querySnapshot = try await usersRef
                .whereField("username", isGreaterThanOrEqualTo: lowercasedPrefix)
                .whereField("username", isLessThanOrEqualTo: endString)
                .getDocuments()
            
            for document in querySnapshot.documents {
                let data = document.data()
                guard let id = document.documentID as? String,
                      let name = data["name"] as? String,
                      let username = data["username"] as? String,
                      let email = data["email"] as? String else {
                    continue
                }
                
                // Optional fields
                let friends = data["friends"] as? [String] ?? []
                let friendRequests = data["friendRequests"] as? [String] ?? []
                let pendingRequests = data["pendingRequests"] as? [String] ?? []
                let posts = data["posts"] as? [String] ?? []
                let profilePicture = data["profilePicture"] as? String
                let loggedIn = data["loggedIn"] as? Bool ?? false
                
                let user = User(
                    id: id,
                    name: name,
                    username: username,
                    email: email,
                    friends: friends,
                    friendRequests: friendRequests,
                    pendingRequests: pendingRequests,
                    posts: [], // Convert string IDs to Post objects if needed
                    profilePicture: profilePicture,
                    loggedIn: loggedIn
                )
                users.append(user)
            }
        } catch {
            throw NetworkError.serverError("Failed to search users: \(error.localizedDescription)")
        }
        
        return users
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
enum UserFetchError: Error, LocalizedError {
    case documentNotFound
    case missingRequiredFields
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .documentNotFound:
            return "The user document could not be found."
        case .missingRequiredFields:
            return "The user document is missing required fields."
        case .decodingFailed:
            return "Failed to decode user data."
        }
    }
}
