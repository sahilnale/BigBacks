// Firebase-powered replacements for NetworkManager and AuthViewModel

import Firebase
import FirebaseAuth
import FirebaseFirestore
import UIKit
import SwiftUI
import FirebaseStorage


class NetworkManager {
    static let shared = NetworkManager()
    private let db = Firestore.firestore()

    private init() {}

    private var idNumber: String? {
        get {
            return AuthManager.shared.userId
        }
        set {
            if let newValue = newValue {
                AuthManager.shared.setUserId(newValue)
            } else {
                AuthManager.shared.clearUserId()
            }
        }
    }

    // MARK: - Authentication
    func login(username: String, password: String) async throws -> User {
        do {
            let result = try await Auth.auth().signIn(withEmail: username, password: password)
            idNumber = result.user.uid
            return try await getCurrentUser(userId: result.user.uid)
        } catch {
            throw error
        }
    }

    func signUp(name: String, username: String, email: String, password: String) async throws -> User {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = User(id: result.user.uid, name: name, username: username, email: email, friends: [], friendRequests: [], pendingRequests: [], posts: [], profilePicture: nil, loggedIn: true)
            try await saveUser(user)
            idNumber = result.user.uid
            return user
        } catch {
            throw error
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            idNumber = nil
        } catch {
            print("Error logging out: \(error.localizedDescription)")
        }
    }

    func getCurrentUser(userId: String) async throws -> User {
        let doc = try await db.collection("users").document(userId).getDocument()
        guard let data = doc.data(), let user = try? User(from: data as! Decoder) else {
            throw NSError(domain: "User not found", code: 404, userInfo: nil)
        }
        return user
    }

    func saveUser(_ user: User) async throws {
        try await db.collection("users").document(user.id).setData(user.toDictionary())
    }

    func searchUsers(query: String) async throws -> [User] {
        let snapshot = try await db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: query)
            .whereField("username", isLessThanOrEqualTo: query + "\u{f8ff}") // Correct Unicode escape
            .getDocuments()
        return snapshot.documents.compactMap { try? User(from: $0.data() as! Decoder) }
    }

    func sendFriendRequest(from currentUserId: String, to friendId: String) async throws {
        let currentUserRef = db.collection("users").document(currentUserId)
        let friendRef = db.collection("users").document(friendId)

        try await db.runTransaction { transaction, errorPointer in
            do {
                let currentUserDoc = try transaction.getDocument(currentUserRef)
                let friendDoc = try transaction.getDocument(friendRef)

                guard let currentUserData = currentUserDoc.data(),
                      let friendData = friendDoc.data() else {
                    throw NSError(domain: "User not found", code: 404, userInfo: nil)
                }

                var currentUser = try User(from: currentUserData as! Decoder)
                var friend = try User(from: friendData as! Decoder)

                if !friend.friendRequests.contains(currentUserId) {
                    friend.friendRequests.append(currentUserId)
                    transaction.updateData(["friendRequests": friend.friendRequests], forDocument: friendRef)
                }

                if !currentUser.pendingRequests.contains(friendId) {
                    currentUser.pendingRequests.append(friendId)
                    transaction.updateData(["pendingRequests": currentUser.pendingRequests], forDocument: currentUserRef)
                }
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            return nil
        }
    }
    
    func userFeed(userId: String) async throws -> [Post] {
            let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let userData = userDoc.data(), let user = try? User(from: userData as! Decoder) else {
                throw NSError(domain: "User not found", code: 404, userInfo: nil)
            }

            var feed: [Post] = []
            for friendId in user.friends {
                let friendDoc = try await db.collection("users").document(friendId).getDocument()
                guard let friendData = friendDoc.data(), let friend = try? User(from: friendData as! Decoder) else { continue }

                for postId in friend.posts {
                    let postDoc = try await db.collection("posts").document(postId).getDocument()
                    guard let postData = postDoc.data() else { continue }
                    
                    // Manually map Firestore data to the Post struct
                    let post = try Post(from: postData as! Decoder)
                    feed.append(post)
                }
            }

            feed.sort { $0.timestamp > $1.timestamp }
            return feed
        }
    func getUserById(userId: String) async throws -> User {
            return try await getCurrentUser(userId: userId)
        }
    
    func uploadProfilePic(userId: String, image: UIImage) async throws -> String {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw NSError(domain: "Invalid image data", code: 400, userInfo: nil)
            }

            let storageRef = Storage.storage().reference().child("profilePictures/\(userId).jpg")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

            let uploadTask = try await storageRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await storageRef.downloadURL()
            return downloadURL.absoluteString
        }
    
    func fetchPostDetails(postId: String) async throws -> Post {
            let postDoc = try await db.collection("posts").document(postId).getDocument()
        guard let postData = postDoc.data(), let post = try? Post(from: postData as! Decoder) else {
                throw NSError(domain: "Post not found", code: 404, userInfo: nil)
            }
            return post
        }
    
    func toggleLike(postId: String, currentLikeCount: Int, isLiked: Bool, completion: @escaping (Int, Bool) -> Void) {
        guard let userId = AuthManager.shared.userId else {
            print("Error: User not logged in.")
            completion(currentLikeCount, isLiked)
            return
        }

        let postRef = Firestore.firestore().collection("posts").document(postId)

        Firestore.firestore().runTransaction { (transaction, errorPointer) -> Any? in
            do {
                let postSnapshot = try transaction.getDocument(postRef)
                guard var postData = postSnapshot.data() else {
                    throw NSError(domain: "Post not found", code: 404, userInfo: nil)
                }

                var updatedLikes = currentLikeCount
                var updatedLikedBy = postData["likedBy"] as? [String] ?? []

                if isLiked {
                    // Unlike
                    updatedLikes -= 1
                    updatedLikedBy.removeAll { $0 == userId }
                } else {
                    // Like
                    updatedLikes += 1
                    updatedLikedBy.append(userId)
                }

                // Update post data
                postData["likes"] = updatedLikes
                postData["likedBy"] = updatedLikedBy
                transaction.updateData(postData, forDocument: postRef)

                return (updatedLikes, !isLiked)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        } completion: { result, error in
            if let result = result as? (Int, Bool) {
                completion(result.0, result.1)
            } else if let error = error {
                print("Transaction failed: \(error)")
                completion(currentLikeCount, isLiked)
            }
        }
    }


    
    func fetchPostDetailsFromFeed(userId: String) async throws -> [(Post, User)] {
        let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let userData = userDoc.data(), let user = try? User(from: userData as! Decoder) else {
            throw NSError(domain: "User not found", code: 404, userInfo: nil)
        }

        var feed: [(Post, User)] = []
        
        for friendId in user.friends {
            let friendDoc = try await db.collection("users").document(friendId).getDocument()
            guard let friendData = friendDoc.data(), let friend = try? User(from: friendData as! Decoder) else { continue }

            for postId in friend.posts {
                let postDoc = try await db.collection("posts").document(postId).getDocument()
                guard let postData = postDoc.data(), let post = try? Post(from: postData as! Decoder) else { continue }
                feed.append((post, friend))
            }
        }

        feed.sort { $0.0.timestamp > $1.0.timestamp }
        return feed
    }
    
    func getFriendRequests(userId: String) async throws -> [User] {
        // Fetch the current user's document
        let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let userData = userDoc.data(), let user = try? User(from: userData as! Decoder) else {
            throw NSError(domain: "User not found", code: 404, userInfo: nil)
        }

        var friendRequests: [User] = []

        // Iterate through friend request IDs
        for requestId in user.friendRequests {
            let requestDoc = try await db.collection("users").document(requestId).getDocument()
            guard let requestData = requestDoc.data(), let requestUser = try? User(from: requestData as! Decoder) else {
                continue
            }
            friendRequests.append(requestUser)
        }

        return friendRequests
    }
    
    func acceptFriendRequest(userId: String, friendId: String) async throws {
        let userRef = db.collection("users").document(userId)
        let friendRef = db.collection("users").document(friendId)

        try await db.runTransaction { transaction, errorPointer -> Any? in
            // Fetch user's document
            let userDoc: DocumentSnapshot
            let friendDoc: DocumentSnapshot

            do {
                userDoc = try transaction.getDocument(userRef)
                friendDoc = try transaction.getDocument(friendRef)
            } catch let error {
                errorPointer?.pointee = error as NSError
                return nil
            }

            guard var userData = userDoc.data(), var friendData = friendDoc.data() else {
                errorPointer?.pointee = NSError(domain: "Document not found", code: 404, userInfo: nil)
                return nil
            }

            // Update the user's data: Add friendId to friends and remove from friendRequests
            var userFriends = userData["friends"] as? [String] ?? []
            var userFriendRequests = userData["friendRequests"] as? [String] ?? []

            if !userFriends.contains(friendId) {
                userFriends.append(friendId)
            }
            userFriendRequests.removeAll { $0 == friendId }

            userData["friends"] = userFriends
            userData["friendRequests"] = userFriendRequests
            transaction.setData(userData, forDocument: userRef)

            // Update the friend's data: Add userId to their friends and remove from their pendingRequests
            var friendFriends = friendData["friends"] as? [String] ?? []
            var friendPendingRequests = friendData["pendingRequests"] as? [String] ?? []

            if !friendFriends.contains(userId) {
                friendFriends.append(userId)
            }
            friendPendingRequests.removeAll { $0 == userId }

            friendData["friends"] = friendFriends
            friendData["pendingRequests"] = friendPendingRequests
            transaction.setData(friendData, forDocument: friendRef)

            return nil
        }
    }

    
    func rejectFriendRequest(userId: String, friendId: String) async throws {
        let userRef = db.collection("users").document(userId)
        let friendRef = db.collection("users").document(friendId)

        try await db.runTransaction { transaction, errorPointer -> Any? in
            // Fetch user's document
            guard let userDoc = try? transaction.getDocument(userRef),
                  var userData = userDoc.data() else {
                errorPointer?.pointee = NSError(domain: "User not found", code: 404, userInfo: nil)
                return nil
            }

            // Fetch friend's document
            guard let friendDoc = try? transaction.getDocument(friendRef),
                  var friendData = friendDoc.data() else {
                errorPointer?.pointee = NSError(domain: "Friend not found", code: 404, userInfo: nil)
                return nil
            }

            // Update user's data: Remove friendId from friendRequests
            var userFriendRequests = userData["friendRequests"] as? [String] ?? []
            userFriendRequests.removeAll { $0 == friendId }
            userData["friendRequests"] = userFriendRequests
            transaction.setData(userData, forDocument: userRef)

            // Update friend's data: Remove userId from their pendingRequests
            var friendPendingRequests = friendData["pendingRequests"] as? [String] ?? []
            friendPendingRequests.removeAll { $0 == userId }
            friendData["pendingRequests"] = friendPendingRequests
            transaction.setData(friendData, forDocument: friendRef)

            return nil
        }
    }
    
    func addPost(
        userId: String,
        imageData: Data,
        review: String,
        location: String,
        restaurantName: String,
        starRating: Int
    ) async throws -> Post {
        let postId = UUID().uuidString // Generate a unique ID for the post
        let imagePath = "posts/\(postId).jpg"
        let storageRef = Storage.storage().reference().child(imagePath)
        
        // Upload the image to Firebase Storage
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let imageUrl = try await storageRef.downloadURL().absoluteString
        
        // Create a post dictionary
        let timestampString = ISO8601DateFormatter().string(from: Date())
        let postDict: [String: Any] = [
            "_id": postId,
            "userId": userId,
            "imageUrl": imageUrl,
            "timestamp": timestampString,
            "review": review,
            "location": location,
            "restaurantName": restaurantName,
            "likes": 0,
            "likedBy": [],
            "starRating": starRating,
            "comments": []
        ]
        
        // Add the post to Firestore
        try await db.collection("posts").document(postId).setData(postDict)
        
        // Add the post ID to the user's document
        let userRef = db.collection("users").document(userId)
        try await db.runTransaction { transaction, errorPointer in
            do {
                let userDoc = try transaction.getDocument(userRef)
                guard var userPosts = userDoc.data()?["posts"] as? [String] else {
                    throw NSError(domain: "User posts not found", code: 404, userInfo: nil)
                }
                userPosts.append(postId)
                transaction.updateData(["posts": userPosts], forDocument: userRef)
            } catch {
                // Handle the error without throwing
                errorPointer?.pointee = error as NSError
                return nil
            }
            return nil
        }
        
        // Create a Post object and return it
        return try Post(from: postDict as! Decoder)
    }
    
    func deletePost(postId: String, userId: String) async throws {
        let postRef = db.collection("posts").document(postId)
        let userRef = db.collection("users").document(userId)

        try await db.runTransaction { transaction, errorPointer in
            do {
                // Fetch the user document
                let userDoc = try transaction.getDocument(userRef)
                guard var userPosts = userDoc.data()?["posts"] as? [String] else {
                    throw NSError(domain: "User posts not found", code: 404, userInfo: nil)
                }

                // Remove the post ID from the user's posts array
                if let index = userPosts.firstIndex(of: postId) {
                    userPosts.remove(at: index)
                    transaction.updateData(["posts": userPosts], forDocument: userRef)
                } else {
                    throw NSError(domain: "Post not found in user's posts", code: 404, userInfo: nil)
                }

                // Delete the post document
                transaction.deleteDocument(postRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            return nil
        }
    }






    
    






    // Additional user management and post functionalities would follow similar patterns
}
