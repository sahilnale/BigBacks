import SwiftUI
import FirebaseMessaging
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()

    @Published var error: String?
    @Published var isLoading = false
    @Published var showError = false
    @Published var currentUser: User? = nil
    @Published var isAuthenticated: Bool = false

    init() {
        Task {
            await loadCurrentUser()
        }
    }

    // MARK: - Load Current User
    func loadCurrentUser() async {
        guard let firebaseUser = Auth.auth().currentUser else {
            await MainActor.run {
                self.currentUser = nil
            }
            return
        }

        let db = Firestore.firestore()
        do {
            let userDoc = try await db.collection("users").document(firebaseUser.uid).getDocument()
            guard let data = userDoc.data() else {
                await MainActor.run {
                    self.currentUser = nil
                }
                return
            }

            await MainActor.run {
                self.currentUser = User(
                    id: firebaseUser.uid,
                    name: data["name"] as? String ?? "",
                    username: data["username"] as? String ?? "",
                    email: data["email"] as? String ?? "",
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
            await MainActor.run {
                self.currentUser = nil
            }
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
    
    func updateFirestoreUser(
        userId: String,
        name: String,
        username: String,
        email: String,
        profileImageData: Data?,
        completion: @escaping (Bool) -> Void
    ) {
        isLoading = true
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        Task {
            do {
                // Check if the user document exists
                let document = try await userRef.getDocument()
                if document.exists {
                    print("User already exists in Firestore. Updating data...")
                } else {
                    print("User does not exist in Firestore. Creating new document...")
                }
                
                // Upload profile picture if provided
                var profilePictureUrl: String? = nil
                if let imageData = profileImageData {
                    profilePictureUrl = try await uploadProfilePicture(imageData: imageData)
                }

                // Update Firestore document
                let userData: [String: Any] = [
                    "id": userId,
                    "name": name,
                    "username": username,
                    "email": email,
                    "profilePicture": profilePictureUrl ?? "",
                    "loggedIn": true
                ]
                try await userRef.setData(userData, merge: true)

                await MainActor.run {
                    self.isLoading = false
                    completion(true)
                }
            } catch {
                print("Failed to update Firestore user: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                    self.error = error.localizedDescription
                    completion(false)
                }
            }
        }
    }

    
    func createUser(
        name: String,
        username: String,
        email: String,
        password: String,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        Task {
            do {
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                try await result.user.sendEmailVerification()
                completion(true, nil)
            } catch {
                completion(false, error)
            }
        }
    }

    
    func sendVerificationEmail(email: String, password: String, completion: @escaping (Bool) -> Void) {
            isLoading = true
            Task {
                do {
                    // Create user in Firebase Auth
                    let result = try await Auth.auth().createUser(withEmail: email, password: password)
                    try await result.user.sendEmailVerification()

                    await MainActor.run {
                        self.isLoading = false
                        completion(true)
                    }
                } catch {
                    await MainActor.run {
                        self.error = error.localizedDescription
                        self.showError = true
                        self.isLoading = false
                        completion(false)
                    }
                }
            }
    }
    
    
    
    var isLoggedIn: Bool {
        currentUser != nil
    }
    
    func uploadProfilePicture(imageData: Data) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])
        }

        let imageRef = Storage.storage().reference().child("profilePictures/\(userId)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
        let imageUrl = try await imageRef.downloadURL().absoluteString

        return imageUrl
    }

    
    func signUp(
        name: String,
        username: String,
        email: String,
        password: String,
        profileImageData: Data?,
        completion: @escaping (Bool) -> Void
    ) {
        isLoading = true
        Task {
            let db = Firestore.firestore()
            do {
                // Check if the username already exists
                let querySnapshot = try await db.collection("users").whereField("username", isEqualTo: username).getDocuments()
                if !querySnapshot.documents.isEmpty {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Username already taken."])
                }

                // Create the user in Firebase Auth
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                let userId = result.user.uid

                // Upload the profile picture (if provided)
                var profilePictureUrl: String? = nil
                if let imageData = profileImageData {
                    profilePictureUrl = try await uploadProfilePicture(imageData: imageData)
                }

                // Create the user document in Firestore
                let user: [String: Any] = [
                    "id": userId,
                    "name": name,
                    "username": username,
                    "email": email,
                    "friends": [],
                    "friendRequests": [],
                    "pendingRequests": [],
                    "posts": [],
                    "profilePicture": profilePictureUrl ?? "",
                    "loggedIn": false
                ]
                try await db.collection("users").document(userId).setData(user)

                // Send email verification
                try await result.user.sendEmailVerification()

                await MainActor.run {
                    self.isLoading = false
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.showError = true
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
                    
                    // Provide a user-friendly error message for authentication errors
                    let nsError = error as NSError
                    let errorCode = nsError.code
                    
                    // Handle Firebase Auth errors - these use specific error codes
                    if nsError.domain == AuthErrorDomain {
                        // Common Firebase auth error codes
                        switch errorCode {
                        case 17011, 17009, 17008: // userNotFound, wrongPassword, invalidEmail
                            self.error = "Incorrect email or password. Please try again."
                        case 17005: // userDisabled
                            self.error = "Your account has been disabled. Please contact support."
                        case 17010: // tooManyRequests
                            self.error = "Too many failed login attempts. Please try again later."
                        case 17020: // networkError
                            self.error = "Network error. Please check your internet connection and try again."
                        default:
                            self.error = "Login failed. Please try again."
                        }
                    } else {
                        self.error = "Login failed. Please try again."
                    }
                    
                    // We don't show the alert for login errors, as they'll be displayed inline in the login view
                    self.showError = false
                    completion(false)
                }
            }
        }
    }
    
    func resetPassword(email: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: email)
                await MainActor.run {
                    self.error = "Password reset email sent! Please check your inbox."
                    self.showError = true
                    self.isLoading = false
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.showError = true
                    self.isLoading = false
                    completion(false)
                }
            }
        }
    }

    func refreshCurrentUser() async throws {
            guard let firebaseUser = Auth.auth().currentUser else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is logged in."])
            }
            try await firebaseUser.reload()

            if firebaseUser.isEmailVerified {
                // Update the app's user model to reflect verification status
                await MainActor.run {
                    self.currentUser = User(
                        id: firebaseUser.uid,
                        name: self.currentUser?.name ?? "",
                        username: self.currentUser?.username ?? "",
                        email: firebaseUser.email ?? "",
                        friends: self.currentUser?.friends ?? [],
                        friendRequests: self.currentUser?.friendRequests ?? [],
                        pendingRequests: self.currentUser?.pendingRequests ?? [],
                        posts: self.currentUser?.posts ?? [],
                        profilePicture: self.currentUser?.profilePicture,
                        loggedIn: true
                    )
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
        imageDatas: [Data], // Changed to accept an array of images
        review: String,
        location: String,
        restaurantName: String,
        starRating: Int
    ) async throws -> Post {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])
        }

        print("Uploading images...")

        var imageUrls: [String] = []

        // Upload each image and get its URL
        for imageData in imageDatas {
            let imageRef = Storage.storage().reference().child("posts/\(UUID().uuidString).jpg")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

            _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
            let imageUrl = try await imageRef.downloadURL().absoluteString
            imageUrls.append(imageUrl)
        }

        print("Images uploaded successfully!")

        // Save Post in Firestore
        let db = Firestore.firestore()
        let postId = UUID().uuidString
        let newPost: [String: Any] = [
            "id": postId,
            "userId": userId,
            "imageUrls": imageUrls, // Store array of image URLs
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

        // Update Current User's Posts
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "posts": FieldValue.arrayUnion([postId])
        ])

        // Return the created post object
        return Post(
            _id: postId,
            userId: userId,
            imageUrls: imageUrls, // Return the array of URLs
            timestamp: Timestamp(date: Date()), // You can fetch the timestamp from Firestore if needed
            review: review,
            location: location,
            restaurantName: restaurantName,
            likes: 0,
            likedBy: [],
            starRating: starRating,
            comments: []
        )
    }
    
//    func getUserById(friendId: String) async throws -> User? {
//        let userDocument = try await Firestore.firestore()
//            .collection("users")
//            .document(friendId)
//            .getDocument()
//
//        guard let data = userDocument.data() else {
//            throw UserFetchError.documentNotFound
//        }
//
//        // Manual decoding of Firestore document
//        guard let id = data["id"] as? String,
//              let name = data["name"] as? String,
//              let username = data["username"] as? String,
//              let email = data["email"] as? String,
//              let friends = data["friends"] as? [String],
//              let friendRequests = data["friendRequests"] as? [String],
//              let pendingRequests = data["pendingRequests"] as? [String],
//              let posts = data["posts"] as? [String] else {
//            throw NetworkError.decodingError
//        }
//
//        let profilePicture = data["profilePicture"] as? String
//        let loggedIn = data["loggedIn"] as? Bool ?? false
//
//        return User(
//            id: id,
//            name: name,
//            username: username,
//            email: email,
//            friends: friends,
//            friendRequests: friendRequests,
//            pendingRequests: pendingRequests,
//            posts: [], // Assuming `Post` initializer for post IDs
//            profilePicture: profilePicture,
//            loggedIn: loggedIn
//        )
//    }
//
    
    func getUserById(friendId: String) async throws -> User? {
        let userDocument = try await Firestore.firestore()
            .collection("users")
            .document(friendId)
            .getDocument()

        guard let data = userDocument.data() else {
            print("Debug: No data found for user ID \(friendId)")
            throw UserFetchError.documentNotFound
        }

        // Use the document ID directly instead of expecting an "id" field
        let profilePicture = data["profilePicture"] as? String
        let loggedIn = data["loggedIn"] as? Bool ?? false

        // Make optional fields truly optional
        return User(
            id: friendId, // Use the Firestore document ID
            name: data["name"] as? String ?? "",
            username: data["username"] as? String ?? "",
            email: data["email"] as? String ?? "",
            friends: data["friends"] as? [String] ?? [],
            friendRequests: data["friendRequests"] as? [String] ?? [],
            pendingRequests: data["pendingRequests"] as? [String] ?? [],
            posts: [], // or handle posts differently if needed
            profilePicture: profilePicture,
            loggedIn: loggedIn
        )
    }
    
    func searchUsers(by query: String) async throws -> [User] {
        let db = Firestore.firestore()
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in."])
        }

        var users: [User] = []
        let lowercasedQuery = query.lowercased()

        do {
            // Get all users and filter in memory for more flexible matching
            let querySnapshot = try await db.collection("users").getDocuments()
            
            for document in querySnapshot.documents {
                let userId = document.documentID
                
                // Skip current user
                if userId == currentUserId {
                    continue
                }
                
                let data = document.data()
                let name = (data["name"] as? String ?? "").lowercased()
                let username = (data["username"] as? String ?? "").lowercased()
                
                // Check if query matches any part of name or username
                if name.contains(lowercasedQuery) || username.contains(lowercasedQuery) {
                    if let user = try? createUserFromDocument(document) {
                        users.append(user)
                    }
                }
            }
            
            // Sort results by relevance (exact matches first, then partial matches)
            users.sort { user1, user2 in
                let name1 = user1.name.lowercased()
                let name2 = user2.name.lowercased()
                let username1 = user1.username.lowercased()
                let username2 = user2.username.lowercased()
                
                // Check for exact matches first
                let exactMatch1 = name1 == lowercasedQuery || username1 == lowercasedQuery
                let exactMatch2 = name2 == lowercasedQuery || username2 == lowercasedQuery
                
                if exactMatch1 != exactMatch2 {
                    return exactMatch1
                }
                
                // Then check for starts with
                let startsWith1 = name1.hasPrefix(lowercasedQuery) || username1.hasPrefix(lowercasedQuery)
                let startsWith2 = name2.hasPrefix(lowercasedQuery) || username2.hasPrefix(lowercasedQuery)
                
                if startsWith1 != startsWith2 {
                    return startsWith1
                }
                
                // Finally sort by name
                return name1 < name2
            }
            
        } catch {
            throw NetworkError.serverError("Failed to search users: \(error.localizedDescription)")
        }
        return users
    }

    private func createUserFromDocument(_ document: QueryDocumentSnapshot) throws -> User {
        let data = document.data()
        let userId = document.documentID

        guard let name = data["name"] as? String,
              let username = data["username"] as? String,
              let email = data["email"] as? String else {
            throw NetworkError.decodingError
        }

        let friends = data["friends"] as? [String] ?? []
        let friendRequests = data["friendRequests"] as? [String] ?? []
        let pendingRequests = data["pendingRequests"] as? [String] ?? []
        let profilePicture = data["profilePicture"] as? String
        let loggedIn = data["loggedIn"] as? Bool ?? false

        return User(
            id: userId,
            name: name,
            username: username,
            email: email,
            friends: friends,
            friendRequests: friendRequests,
            pendingRequests: pendingRequests,
            posts: [],
            profilePicture: profilePicture,
            loggedIn: loggedIn
        )
    }
        
    // MARK: - Send Friend Request

    func sendFriendRequest(from fromUserId: String, to toUserId: String, fromUserName: String) async throws {
        let db = Firestore.firestore()

        // Check for duplicate request or already friends
        let fromUserDoc = try await db.collection("users").document(fromUserId).getDocument()
        let toUserDoc = try await db.collection("users").document(toUserId).getDocument()

        let fromPending = fromUserDoc.data()?["pendingRequests"] as? [String] ?? []
        let toIncoming = toUserDoc.data()?["friendRequests"] as? [String] ?? []
        let fromFriends = fromUserDoc.data()?["friends"] as? [String] ?? []

        if fromPending.contains(toUserId) || toIncoming.contains(fromUserId) || fromFriends.contains(toUserId) {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request already sent or user already added."])
        }

        // Save request to friendRequests collection
        try await db.collection("friendRequests").addDocument(data: [
            "fromUserId": fromUserId,
            "toUserId": toUserId,
            "fromUserName": fromUserName,
            "timestamp": Timestamp()
        ])

        // Update user arrays
        try await db.collection("users").document(fromUserId).updateData([
            "pendingRequests": FieldValue.arrayUnion([toUserId])
        ])
        try await db.collection("users").document(toUserId).updateData([
            "friendRequests": FieldValue.arrayUnion([fromUserId])
        ])
    }


        // MARK: - Update FCM Token
        func updateFCMTokenForCurrentUser() async throws {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            let fcmToken = try await Messaging.messaging().token()
            
            let db = Firestore.firestore()
            try await db.collection("users").document(userId).updateData([
                "fcmToken": fcmToken
            ])

            print("FCM token updated for user: \(userId)")
        }

    
    func getFriendRequests(for userId: String) async throws -> [(User, String)] {
        let db = Firestore.firestore()

        // Query the friendRequests collection for requests sent to this user
        let friendRequestSnapshot = try await db.collection("friendRequests")
            .whereField("toUserId", isEqualTo: userId)
            .getDocuments()

        var friendRequests: [(User, String)] = []

        for document in friendRequestSnapshot.documents {
            let data = document.data()
            if let fromUserId = data["fromUserId"] as? String,
               let fromUserName = data["fromUserName"] as? String {
                // Fetch the user who sent the friend request
                let friendDoc = try await db.collection("users").document(fromUserId).getDocument()
                if let friendData = friendDoc.data() {
                    let user = User(
                        id: fromUserId,
                        name: friendData["name"] as? String ?? "",
                        username: friendData["username"] as? String ?? "",
                        email: friendData["email"] as? String ?? "",
                        friends: friendData["friends"] as? [String] ?? [],
                        friendRequests: [],
                        pendingRequests: [],
                        posts: [],
                        profilePicture: friendData["profilePicture"] as? String,
                        loggedIn: friendData["loggedIn"] as? Bool ?? false
                    )
                    friendRequests.append((user, fromUserName))
                }
            }
        }

        return friendRequests
    }
    
//    func acceptFriendRequest(currentUserId: String, friendId: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        let db = Firestore.firestore()
//
//        let friendRequestQuery = db.collection("friendRequests")
//            .whereField("toUserId", isEqualTo: currentUserId)
//            .whereField("fromUserId", isEqualTo: friendId)
//
//        Task {
//            do {
//                let friendRequestSnapshot = try await friendRequestQuery.getDocuments()
//                print("Found \(friendRequestSnapshot.documents.count) friend requests to accept")
//
//                db.runTransaction({ transaction, errorPointer in
//                    do {
//                        print("Transaction started for accepting friend request.")
//
//                        // References to user documents
//                        let currentUserRef = db.collection("users").document(currentUserId)
//                        let friendRef = db.collection("users").document(friendId)
//
//                        // Get current user document
//                        let currentUserSnapshot = try transaction.getDocument(currentUserRef)
//                        guard var currentUserData = currentUserSnapshot.data(),
//                              var currentUserFriends = currentUserData["friends"] as? [String] else {
//                            print("Failed to fetch current user data.")
//                            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch current user data."])
//                        }
//
//                        // Get friend document
//                        let friendSnapshot = try transaction.getDocument(friendRef)
//                        if let friendData = friendSnapshot.data() {
//                            print("✅ Friend data fetched successfully:", friendData)
//                        } else {
//                            print("⚠️ Friend document exists but has no data.")
//                        }
//                        let friendData = friendSnapshot.data() ?? [:] // Default to empty dictionary
//                        var friendFriends = friendData["friends"] as? [String] ?? [] // Default to empty array
//
//
//                        print("Fetched both users' data successfully.")
//
//                        // Add each other to friends list
//                        currentUserFriends.append(friendId)
//                        friendFriends.append(currentUserId)
//
//                        // Update user documents
//                        transaction.updateData(["friends": currentUserFriends], forDocument: currentUserRef)
//                        transaction.updateData(["friends": friendFriends], forDocument: friendRef)
//
//                        print("Updated friends list in transaction.")
//
//                        // Delete friend request
//                        for doc in friendRequestSnapshot.documents {
//                            transaction.deleteDocument(doc.reference)
//                        }
//
//                        print("Deleted friend request document.")
//
//                        // Remove the pending request from the sender's document
//                        transaction.updateData([
//                            "pendingRequests": FieldValue.arrayRemove([currentUserId])
//                        ], forDocument: friendRef)
//
//                        print("Removed pending request entry from sender.")
//
//                    } catch {
//                        errorPointer?.pointee = error as NSError
//                        print("Transaction failed: \(error.localizedDescription)")
//                    }
//                    return nil
//                }) { _, error in
//                    if let error = error {
//                        print("Error in accepting request transaction: \(error.localizedDescription)")
//                        completion(.failure(error))
//                    } else {
//                        print("Friend request accepted successfully.")
//                        completion(.success(()))
//                    }
//                }
//            } catch {
//                print("Error fetching friend request: \(error.localizedDescription)")
//                completion(.failure(error))
//            }
//        }
//    }

    func acceptFriendRequest(currentUserId: String, friendId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()

        let friendRequestQuery = db.collection("friendRequests")
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("fromUserId", isEqualTo: friendId)

        Task {
            do {
                let friendRequestSnapshot = try await friendRequestQuery.getDocuments()

                db.runTransaction({ transaction, errorPointer in
                    do {
                        let currentUserRef = db.collection("users").document(currentUserId)
                        let friendRef = db.collection("users").document(friendId)

                        let currentUserSnapshot = try transaction.getDocument(currentUserRef)
                        let friendSnapshot = try transaction.getDocument(friendRef)

                        var currentUserFriends = currentUserSnapshot.data()?["friends"] as? [String] ?? []
                        var friendFriends = friendSnapshot.data()?["friends"] as? [String] ?? []

                        currentUserFriends.append(friendId)
                        friendFriends.append(currentUserId)

                        transaction.updateData(["friends": currentUserFriends], forDocument: currentUserRef)
                        transaction.updateData(["friends": friendFriends], forDocument: friendRef)

                        // 🧹 Clean up requests from both sides
                        transaction.updateData([
                            "friendRequests": FieldValue.arrayRemove([friendId])
                        ], forDocument: currentUserRef)

                        transaction.updateData([
                            "pendingRequests": FieldValue.arrayRemove([currentUserId])
                        ], forDocument: friendRef)

                        for doc in friendRequestSnapshot.documents {
                            transaction.deleteDocument(doc.reference)
                        }

                    } catch {
                        errorPointer?.pointee = error as NSError
                    }
                    return nil
                }) { _, error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }

            } catch {
                completion(.failure(error))
            }
        }
    }

    
    func rejectFriendRequest(currentUserId: String, friendId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let currentUserRef = db.collection("users").document(currentUserId)
        let friendRef = db.collection("users").document(friendId)

        // Query the friendRequests collection to find the specific request
        let friendRequestQuery = db.collection("friendRequests")
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("fromUserId", isEqualTo: friendId)
        
        Task {
               do {
                   let friendRequestSnapshot = try await friendRequestQuery.getDocuments()

                   db.runTransaction({ transaction, errorPointer in
                       do {
                           // Delete all friend request documents
                           for doc in friendRequestSnapshot.documents {
                               transaction.deleteDocument(doc.reference)
                           }

                           // Remove IDs from both users' arrays
                           transaction.updateData([
                               "friendRequests": FieldValue.arrayRemove([friendId])
                           ], forDocument: currentUserRef)

                           transaction.updateData([
                               "pendingRequests": FieldValue.arrayRemove([currentUserId])
                           ], forDocument: friendRef)

                       }
                       return nil
                   }) { _, error in
                       if let error = error {
                           completion(.failure(error))
                       } else {
                           completion(.success(()))
                       }
                   }
               } catch {
                   completion(.failure(error))
               }
           }
       }
    
    func deletePost(postId: String) async throws {
        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(postId)
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in."])
        }
        let userRef = db.collection("users").document(userId)

        // Define a closure with a specific return type
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.runTransaction({ (transaction, errorPointer) -> Void in
                do {
                    // Fetch the post document
                    let postSnapshot = try transaction.getDocument(postRef)
                    guard postSnapshot.exists else {
                        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Post not found."])
                    }

                    // Update the user's `posts` array by removing the post ID
                    transaction.updateData([
                        "posts": FieldValue.arrayRemove([postId])
                    ], forDocument: userRef)

                    // Delete the post document
                    transaction.deleteDocument(postRef)
                } catch {
                    // Set the error in the transaction's error pointer
                    errorPointer?.pointee = error as NSError
                }
            }) { (_, error) in
                // Handle the transaction's completion
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    // Post successfully deleted, send notification
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .postDeleted,
                            object: nil,
                            userInfo: ["postId": postId]
                        )
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    
    func fetchPostDetailsFromFeed(userId: String) async throws -> [(post: Post, user: User)] {
        let db = Firestore.firestore()

        // Fetch the user's friends list and posts
        let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let userData = userDoc.data(),
              let friendsList = userData["friends"] as? [String],
              let userPosts = userData["posts"] as? [String] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data missing or invalid."])
        }

        var feed: [(post: Post, user: User)] = []

        // Fetch user's own posts
        for postId in userPosts {
            if let post = try? await fetchPostDetails(postId: postId) {
                feed.append((post: post, user: try await fetchUserDetails(userId: userId)))
            }
        }

        // Fetch friends' posts
        for friendId in friendsList {
            let friendDoc = try await db.collection("users").document(friendId).getDocument()
            guard let friendData = friendDoc.data(),
                  let friendPosts = friendData["posts"] as? [String] else {
                continue
            }

            for postId in friendPosts {
                if let post = try? await fetchPostDetails(postId: postId) {
                    feed.append((post: post, user: try await fetchUserDetails(userId: friendId)))
                }
            }
        }

        return feed
    }

    func fetchPostDetails(postId: String) async throws -> Post {
        let db = Firestore.firestore()
        let postDoc = try await db.collection("posts").document(postId).getDocument()

        guard let postData = postDoc.data() else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Post not found."])
        }

        let commentsData = postData["comments"] as? [[String: Any]] ?? []
        let comments: [Comment] = commentsData.compactMap { data in
            guard let id = data["id"] as? String,
                  let commentId = data["commentId"] as? String,
                  let userId = data["userId"] as? String,
                  let profilePhotoUrl = data["profilePhotoUrl"] as? String,
                  let text = data["text"] as? String,
                  let timestamp = data["timestamp"] as? Timestamp else {
                return nil
            }
            return Comment(
                id: id,
                commentId: commentId,
                userId: userId,
                profilePhotoUrl: profilePhotoUrl,
                text: text,
                timestamp: timestamp.dateValue()
            )
        }

        return Post(
            _id: postDoc.documentID,
            userId: postData["userId"] as? String ?? "",
            imageUrls: postData["imageUrls"] as? [String] ?? [], // Fetch the array of image URLs
            timestamp: postData["timestamp"] as? Timestamp ?? Timestamp(date: Date()),
            review: postData["review"] as? String ?? "",
            location: postData["location"] as? String ?? "",
            restaurantName: postData["restaurantName"] as? String ?? "",
            likes: postData["likes"] as? Int ?? 0,
            likedBy: postData["likedBy"] as? [String] ?? [],
            starRating: postData["starRating"] as? Int ?? 0,
            comments: comments
        )
    }



    private func fetchUserDetails(userId: String) async throws -> User {
        let db = Firestore.firestore()
        let userDoc = try await db.collection("users").document(userId).getDocument()

        guard let userData = userDoc.data() else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found."])
        }

        return User(
            id: userDoc.documentID,
            name: userData["name"] as? String ?? "",
            username: userData["username"] as? String ?? "",
            email: userData["email"] as? String ?? "",
            friends: userData["friends"] as? [String] ?? [],
            friendRequests: userData["friendRequests"] as? [String] ?? [],
            pendingRequests: userData["pendingRequests"] as? [String] ?? [],
            posts: userData["posts"] as? [Post] ?? [],
            profilePicture: userData["profilePicture"] as? String,
            loggedIn: true
        )
    }
    
    
    func toggleLike(postId: String, userId: String, isCurrentlyLiked: Bool) async throws -> (newLikeCount: Int, isLiked: Bool) {
        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(postId)
        
        return try await withCheckedThrowingContinuation { continuation in
            db.runTransaction({ transaction, _ in
                let postSnapshot: DocumentSnapshot
                do {
                    postSnapshot = try transaction.getDocument(postRef)
                } catch {
                    continuation.resume(throwing: error)
                    return nil
                }
                
                guard let postData = postSnapshot.data(),
                      let currentLikes = postData["likes"] as? Int,
                      var likedBy = postData["likedBy"] as? [String] else {
                    continuation.resume(throwing: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid post data."]))
                    return nil
                }
                
                if isCurrentlyLiked {
                    // User is disliking the post
                    likedBy.removeAll { $0 == userId }
                    transaction.updateData([
                        "likes": currentLikes - 1,
                        "likedBy": likedBy
                    ], forDocument: postRef)
                    continuation.resume(returning: (newLikeCount: currentLikes - 1, isLiked: false))
                } else {
                    // User is liking the post
                    likedBy.append(userId)
                    transaction.updateData([
                        "likes": currentLikes + 1,
                        "likedBy": likedBy
                    ], forDocument: postRef)
                    continuation.resume(returning: (newLikeCount: currentLikes + 1, isLiked: true))
                }
                return nil
            }, completion: { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                }
            })
        }
    }

        
        // Fetch updated post details
        
    func addComment(to postId: String, comment: Comment) async throws -> Comment {
        let db = Firestore.firestore()
        let commentData: [String: Any] = [
            "id": comment.id,
            "commentId": comment.commentId,
            "userId": comment.userId,
            "profilePhotoUrl": comment.profilePhotoUrl,
            "text": comment.text,
            "timestamp": Timestamp(date: comment.timestamp)
        ]

        try await db.collection("posts").document(postId).updateData([
            "comments": FieldValue.arrayUnion([commentData])
        ])

        return comment
    }
    
    func removeFriend(currentUserId: String, friendId: String) async throws {
        let db = Firestore.firestore()
        let currentUserRef = db.collection("users").document(currentUserId)
        let friendRef = db.collection("users").document(friendId)

        try await db.runTransaction { transaction, errorPointer in
            // Fetch current user's data
            let currentUserSnapshot: DocumentSnapshot
            do {
                currentUserSnapshot = try transaction.getDocument(currentUserRef)
            } catch {
                errorPointer?.pointee = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch current user data."])
                return nil
            }

            // Fetch friend's data
            let friendSnapshot: DocumentSnapshot
            do {
                friendSnapshot = try transaction.getDocument(friendRef)
            } catch {
                errorPointer?.pointee = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch friend data."])
                return nil
            }

            // Extract friends list and remove each other
            guard var currentUserFriends = currentUserSnapshot.data()?["friends"] as? [String],
                  var friendFriends = friendSnapshot.data()?["friends"] as? [String] else {
                errorPointer?.pointee = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid friend data."])
                return nil
            }

            currentUserFriends.removeAll { $0 == friendId }
            friendFriends.removeAll { $0 == currentUserId }

            // Update Firestore documents
            transaction.updateData(["friends": currentUserFriends], forDocument: currentUserRef)
            transaction.updateData(["friends": friendFriends], forDocument: friendRef)

            return nil
        }
    }

    
    func getFriends() async throws -> [User] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in."])
        }

        let db = Firestore.firestore()
        do {
            // Fetch the current user's document
            let userDoc = try await db.collection("users").document(currentUserId).getDocument()

            guard let data = userDoc.data(),
                  let friendIds = data["friends"] as? [String] else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user's friends list."])
            }

            // Fetch friend details for each friend ID
            var fetchedFriends: [User] = []
            for friendId in friendIds {
                do {
                    let friendDoc = try await db.collection("users").document(friendId).getDocument()
                    guard let friendData = friendDoc.data() else {
                        print("Friend document not found for ID: \(friendId)")
                        continue
                    }

                    // Decode each friend's data manually
                    guard let id = friendDoc.documentID as String?,
                          let name = friendData["name"] as? String,
                          let username = friendData["username"] as? String,
                          let email = friendData["email"] as? String else {
                        print("Failed to decode friend data for ID: \(friendId)")
                        continue
                    }

                    let friends = friendData["friends"] as? [String] ?? []
                    let friendRequests = friendData["friendRequests"] as? [String] ?? []
                    let pendingRequests = friendData["pendingRequests"] as? [String] ?? []
                    let profilePicture = friendData["profilePicture"] as? String

                    let friend = User(
                        id: id,
                        name: name,
                        username: username,
                        email: email,
                        friends: friends,
                        friendRequests: friendRequests,
                        pendingRequests: pendingRequests,
                        posts: [], // Handle posts separately if needed
                        profilePicture: profilePicture,
                        loggedIn: true
                    )
                    fetchedFriends.append(friend)
                } catch {
                    print("Error fetching friend data for ID \(friendId): \(error.localizedDescription)")
                }
            }

            return fetchedFriends
        } catch {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch friends: \(error.localizedDescription)"])
        }
    }
    
    func toggleWishlist(postId: String, userId: String) async throws -> Bool {
        let userRef = Firestore.firestore().collection("users").document(userId)
        let snapshot = try await userRef.getDocument()
        
        guard var wishlistedPosts = snapshot.data()?["wishlist"] as? [String] else {
            try await userRef.setData(["wishlist": [postId]], merge: true)
            return true
        }

        if wishlistedPosts.contains(postId) {
            wishlistedPosts.removeAll { $0 == postId }
        } else {
            wishlistedPosts.append(postId)
        }

        try await userRef.updateData(["wishlist": wishlistedPosts])
        return wishlistedPosts.contains(postId)
    }
    
    func fetchWishlist() async throws -> [(post: Post, userName: String)] {
        let db = Firestore.firestore()
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No user logged in.")
            return []
        }

        print("🔍 Fetching wishlist for userId: \(userId)")

        let userDoc = try await db.collection("users").document(userId).getDocument()
        
        guard let userData = userDoc.data(),
              let wishlistIds = userData["wishlist"] as? [String] else {
            print("⚠️ Wishlist array not found in user document.")
            return []
        }

        if wishlistIds.isEmpty {
            print("⚠️ Wishlist is empty.")
            return []
        } else {
            print("✅ Found \(wishlistIds.count) items in wishlist.")
        }

        var wishlistPosts: [(post: Post, userName: String)] = []

        for postId in wishlistIds {
            print("🔄 Fetching post with postId: \(postId)")

            let postDoc = try await db.collection("posts").document(postId).getDocument()

            if let postData = postDoc.data() {
                let postUserId = postData["userId"] as? String ?? ""

                let userDoc = try await db.collection("users").document(postUserId).getDocument()
                let username = userDoc.data()?["username"] as? String ?? "Unknown"

                let post = Post(
                    _id: postDoc.documentID,
                    userId: postUserId,
                    imageUrls: postData["imageUrls"] as? [String] ?? [],
                    timestamp: postData["timestamp"] as? Timestamp ?? Timestamp(date: Date()),
                    review: postData["review"] as? String ?? "",
                    location: postData["location"] as? String ?? "0.0,0.0",
                    restaurantName: postData["restaurantName"] as? String ?? "",
                    likes: postData["likes"] as? Int ?? 0,
                    likedBy: postData["likedBy"] as? [String] ?? [],
                    starRating: postData["starRating"] as? Int ?? 0,
                    comments: []
                )

                wishlistPosts.append((post, username))
                print("✅ Added post '\(post.restaurantName)' by @\(username) to wishlist.")
            } else {
                print("❌ Post with ID \(postId) not found.")
            }
        }

        print("🏁 Finished fetching wishlist. Total posts: \(wishlistPosts.count)")
        return wishlistPosts
    }

    
    func isPostWishlisted(postId: String, userId: String) async throws -> Bool {
            let userRef = Firestore.firestore().collection("users").document(userId)
            let snapshot = try await userRef.getDocument()
            
            if let data = snapshot.data(), let wishlistedPosts = data["wishlist"] as? [String] {
                return wishlistedPosts.contains(postId)
            }
            return false
        }
        
    func cancelFriendRequest(from fromUserId: String, to toUserId: String) async throws {
        let db = Firestore.firestore()

        // Find the friend request document
        let query = db.collection("friendRequests")
            .whereField("fromUserId", isEqualTo: fromUserId)
            .whereField("toUserId", isEqualTo: toUserId)

        let snapshot = try await query.getDocuments()

        try await db.runTransaction { transaction, _ in
            for doc in snapshot.documents {
                transaction.deleteDocument(doc.reference)
            }

            let fromUserRef = db.collection("users").document(fromUserId)
            let toUserRef = db.collection("users").document(toUserId)

            transaction.updateData([
                "pendingRequests": FieldValue.arrayRemove([toUserId])
            ], forDocument: fromUserRef)

            transaction.updateData([
                "friendRequests": FieldValue.arrayRemove([fromUserId])
            ], forDocument: toUserRef)

            return nil
        }
    }
    func getMutualFriendsCount(with friendId: String) async throws -> Int {
        guard let currentUser = currentUser else {
            print("Debug: No current user logged in")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is logged in."])
        }

        let db = Firestore.firestore()


        let currentUserFriends = currentUser.friends

        do {
            let friendDoc = try await db.collection("users").document(friendId).getDocument()
            guard let friendData = friendDoc.data() else {
                print("Debug: Could not fetch friend document")
                return 0
            }

            let friendFriends = friendData["friends"] as? [String] ?? []

            let mutualFriends = Set(currentUserFriends).intersection(Set(friendFriends))
            
            return mutualFriends.count
        } catch {
            print("Debug: Error fetching friend document: \(error)")
            return 0
        }
    }

    func getMutualFriends(with friendId: String) async throws -> [User] {
        guard let currentUser = currentUser else {
            print("Debug: No current user logged in")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is logged in."])
        }

        let db = Firestore.firestore()

        let currentUserFriends = Set(currentUser.friends)

        do {
            let friendDoc = try await db.collection("users").document(friendId).getDocument()
            guard let friendData = friendDoc.data() else {
                return []
            }

            let friendFriends = friendData["friends"] as? [String] ?? []

            let mutualFriendIds = currentUserFriends.intersection(Set(friendFriends))

            var mutualFriends: [User] = []
            for id in mutualFriendIds {
                do {
                    if let user = try await getUserById(friendId: id) {
                        mutualFriends.append(user)
                    }
                } catch {
                    print("Debug: Error fetching mutual friend with ID \(id): \(error)")
                }
            }

            return mutualFriends
        } catch {
            return []
        }
    }

    func deleteAccount(userId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        Task {
            do {
                let db = Firestore.firestore()
                
                // 1. Get user document
                let userDoc = try await db.collection("users").document(userId).getDocument()
                guard let userData = userDoc.data() else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user data."])
                }
                
                // 2. Get all friends of the user
                let friends = userData["friends"] as? [String] ?? []
                
                // 3. Remove this user from all their friends' friend lists
                for friendId in friends {
                    do {
                        let friendRef = db.collection("users").document(friendId)
                        try await friendRef.updateData([
                            "friends": FieldValue.arrayRemove([userId])
                        ])
                    } catch {
                        print("Error removing user from friend's list \(friendId): \(error.localizedDescription)")
                    }
                }
                
                // 4. Delete all posts if they exist
                if let postIds = userData["posts"] as? [String] {
                    for postId in postIds {
                        do {
                            // Delete post images from Storage
                            let postDoc = try await db.collection("posts").document(postId).getDocument()
                            if let postData = postDoc.data(),
                               let imageUrls = postData["imageUrls"] as? [String] {
                                for imageUrl in imageUrls {
                                    if let url = URL(string: imageUrl) {
                                        let imageRef = Storage.storage().reference(forURL: url.absoluteString)
                                        try await imageRef.delete()
                                    }
                                }
                            }
                            
                            // Delete post document
                            try await db.collection("posts").document(postId).delete()
                        } catch {
                            print("Error deleting post \(postId): \(error.localizedDescription)")
                        }
                    }
                }
                
                // 5. Delete profile picture from Storage if it exists
                if let profilePicture = userData["profilePicture"] as? String,
                   let url = URL(string: profilePicture) {
                    let imageRef = Storage.storage().reference(forURL: url.absoluteString)
                    try await imageRef.delete()
                }
                
                // 6. Delete user document from Firestore
                try await db.collection("users").document(userId).delete()
                
                // 7. Delete authentication account
                try await Auth.auth().currentUser?.delete()
                
                await MainActor.run {
                    self.logout()
                    self.isLoading = false
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to delete account: \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false
                    completion(false)
                }
            }
        }
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

