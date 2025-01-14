import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import JWTKit
import Foundation

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

    // MARK: - Load Current User
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

//    // MARK: - Get OAuth2 Access Token
//    private func getAccessToken() async throws -> String {
//        // Locate the ServiceAccount.json file in the app bundle
//        guard let filePath = Bundle.main.path(forResource: "ServiceAccount", ofType: "json"),
//              let fileData = FileManager.default.contents(atPath: filePath) else {
//            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service account file not found."])
//        }
//
//        // Decode the service account JSON into a struct
//        let credentials = try JSONDecoder().decode(GoogleServiceAccount.self, from: fileData)
//
//        // Create a signer using the private key from the service account
//        guard let privateKeyData = credentials.privateKey.data(using: .utf8) else {
//            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid private key format."])
//        }
//        let signer = try RSA256.privateKey(privateKeyData)
//
//        // Create the JWT payload
//        let payload = GoogleJWT(
//            iss: credentials.clientEmail,
//            aud: "https://oauth2.googleapis.com/token",
//            exp: Date().addingTimeInterval(3600),
//            iat: Date()
//        )
//
//        // Sign the JWT to get the token
//        let jwtString = try signer.sign(payload: payload)
//
//        // Prepare the URL and request to fetch the OAuth token
//        let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!
//        var request = URLRequest(url: tokenURL)
//        request.httpMethod = "POST"
//        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//        let requestBody = "grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=\(jwtString)"
//        request.httpBody = requestBody.data(using: String.Encoding.utf8)
//
//        // Send the request and decode the response
//        let (data, _) = try await URLSession.shared.data(for: request)
//        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
//
//        // Return the access token
//        return tokenResponse.accessToken
//    }
//
//
//
//
//    // MARK: - Send Notification
//    private func sendNotification(to fcmToken: String, fromUserName: String) async throws {
//        let projectId = "bigbacks" // Replace with your Firebase project ID
//        let url = URL(string: "https://fcm.googleapis.com/v1/projects/\(projectId)/messages:send")!
//        let accessToken = try await getAccessToken()
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        let payload: [String: Any] = [
//            "message": [
//                "token": fcmToken,
//                "notification": [
//                    "title": "New Friend Request",
//                    "body": "\(fromUserName) sent you a friend request.",
//                    "sound": "default"
//                ]
//            ]
//        ]
//
//        let jsonData = try JSONSerialization.data(withJSONObject: payload)
//        request.httpBody = jsonData
//
//        let (data, response) = try await URLSession.shared.data(for: request)
//        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
//            let responseString = String(data: data, encoding: .utf8) ?? "Unknown error"
//            throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseString])
//        }
//    }


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

                // Create the user document in Firestore
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
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in."])
        }

        var users: [User] = []
        let lowercasedPrefix = usernamePrefix.lowercased()
        let endString = lowercasedPrefix + "\u{f8ff}"

        do {
            let querySnapshot = try await db.collection("users")
                .whereField("username", isGreaterThanOrEqualTo: lowercasedPrefix)
                .whereField("username", isLessThanOrEqualTo: endString)
                .getDocuments()

            for document in querySnapshot.documents {
                let data = document.data()
                let userId = document.documentID

                // Exclude the current user
                if userId == currentUserId {
                    continue
                }

                guard let name = data["name"] as? String,
                      let username = data["username"] as? String,
                      let email = data["email"] as? String else {
                    continue
                }

                let friends = data["friends"] as? [String] ?? []
                let friendRequests = data["friendRequests"] as? [String] ?? []
                let pendingRequests = data["pendingRequests"] as? [String] ?? []
                let posts = data["posts"] as? [String] ?? []
                let profilePicture = data["profilePicture"] as? String
                let loggedIn = data["loggedIn"] as? Bool ?? false

                let user = User(
                    id: userId,
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
    
    // MARK: - Send Friend Request
    func sendFriendRequest(from userId: String, to friendId: String, fromUserName: String) async throws {
        let db = Firestore.firestore()

        // Create the friend request document
        let friendRequestData: [String: Any] = [
            "toUserId": friendId,
            "fromUserId": userId,
            "fromUserName": fromUserName
        ]

        // Add the friend request to the friendRequests collection
        try await db.collection("friendRequests").addDocument(data: friendRequestData)

        // Update the sender's pendingRequests list
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "pendingRequests": FieldValue.arrayUnion([friendId])
        ])

        print("Friend request sent from \(fromUserName) to \(friendId)")
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
                if let friendData = friendDoc.data(),
                   let id = friendDoc.documentID as? String,
                   let name = friendData["name"] as? String,
                   let username = friendData["username"] as? String {
                    let user = User(
                        id: id,
                        name: name,
                        username: username,
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

    
    func acceptFriendRequest(currentUserId: String, friendId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()

        // Query the friendRequests collection before starting the transaction
        let friendRequestQuery = db.collection("friendRequests")
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("fromUserId", isEqualTo: friendId)

        // Fetch the matching friend request documents outside the transaction
        Task {
            do {
                let friendRequestSnapshot = try await friendRequestQuery.getDocuments()

                // Run the Firestore transaction
                db.runTransaction({ transaction, errorPointer in
                    do {
                        // References to the current user and friend documents
                        let currentUserRef = db.collection("users").document(currentUserId)
                        let friendRef = db.collection("users").document(friendId)

                        // Get the current user's document
                        let currentUserSnapshot = try transaction.getDocument(currentUserRef)
                        guard var currentUserData = currentUserSnapshot.data(),
                              var currentUserFriends = currentUserData["friends"] as? [String] else {
                            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch current user data."])
                        }

                        // Get the friend's document
                        let friendSnapshot = try transaction.getDocument(friendRef)
                        guard var friendData = friendSnapshot.data(),
                              var friendFriends = friendData["friends"] as? [String] else {
                            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch friend data."])
                        }

                        // Add each other to the friends list
                        currentUserFriends.append(friendId)
                        friendFriends.append(currentUserId)

                        // Update the users' documents in the transaction
                        transaction.updateData(["friends": currentUserFriends], forDocument: currentUserRef)
                        transaction.updateData(["friends": friendFriends], forDocument: friendRef)

                        // Delete the matching friend request documents
                        for doc in friendRequestSnapshot.documents {
                            transaction.deleteDocument(doc.reference)
                        }

                        // Remove the pending request from the sender's document
                        transaction.updateData([
                            "pendingRequests": FieldValue.arrayRemove([currentUserId])
                        ], forDocument: friendRef)
                    } catch {
                        // Set the error in the transaction's error pointer
                        errorPointer?.pointee = error as NSError
                    }
                    return nil
                }) { _, error in
                    // Handle the result of the transaction
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            } catch {
                // Handle any errors that occur outside the transaction
                completion(.failure(error))
            }
        }
    }


    
    func rejectFriendRequest(currentUserId: String, friendId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()

        // Query the friendRequests collection to find the specific request
        let friendRequestQuery = db.collection("friendRequests")
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("fromUserId", isEqualTo: friendId)

        Task {
            do {
                let friendRequestSnapshot = try await friendRequestQuery.getDocuments()

                // Delete all matching friend requests
                for doc in friendRequestSnapshot.documents {
                    try await doc.reference.delete()
                }

                completion(.success(()))
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
            imageUrl: postData["imageUrl"] as? String ?? "",
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
