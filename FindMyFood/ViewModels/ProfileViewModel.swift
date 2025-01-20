////
////  ProfileViewModel.swift
////  FindMyFood
////
////  Created by Ridhima Morampudi on 11/24/24.
////
//
////import Foundation
////
////class ProfileViewModel: ObservableObject {
////    @Published var name: String = "Loading..."
////    @Published var username: String = "Loading..."
////    @Published var errorMessage: String? = nil
////    @Published var posts: [Post] = []
////    @Published var friendsCount: Int = 0
////    @Published var isLoading: Bool = false
////    
////        func loadProfile() async {
////            guard let userId = AuthManager.shared.userId else {
////                errorMessage = "User is not logged in."
////                return
////            }
////
////            isLoading = true
////
////            do {
////                // Fetch the user, which includes their posts
////                let user = try await NetworkManager.shared.getCurrentUser(userId: userId)
////
////                // Update the UI on the main thread
////                DispatchQueue.main.async {
////                    self.name = user.name
////                    self.username = user.username
////                    self.posts = user.posts
////                    self.friendsCount = user.friends.count
////                    self.isLoading = false
////                }
////            } catch {
////                DispatchQueue.main.async {
////                    self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
////                    self.isLoading = false
////                }
////            }
////        }
////    
////
////    
////    
////    
////    
////}//end
//
//import Foundation
//import UIKit
//import FirebaseFirestore
//import FirebaseAuth
//
//class ProfileViewModel: ObservableObject {
//    @Published var name: String = ""
//    @Published var username: String = ""
//    @Published var posts: [Post] = []
//    @Published var friendsCount: Int = 0
//    @Published var isLoading: Bool = false
//    @Published var errorMessage: String? = nil
//
//    private let authViewModel: AuthViewModel
//
//    init(authViewModel: AuthViewModel) {
//        self.authViewModel = authViewModel
//    }
//
//    func loadProfile() async {
//        guard let userId = Auth.auth().currentUser?.uid else {
//            errorMessage = "User is not logged in."
//            return
//        }
//
//        isLoading = true
//        do {
//            let db = Firestore.firestore()
//
//            // Fetch user details
//            let userDocument = try await db.collection("users").document(userId).getDocument()
//            guard let userData = userDocument.data() else {
//                errorMessage = "Failed to fetch user data."
//                return
//            }
//
//            // Update user details
//            DispatchQueue.main.async {
//                self.name = userData["name"] as? String ?? "Unknown"
//                self.username = userData["username"] as? String ?? "unknown"
//                self.friendsCount = (userData["friends"] as? [String])?.count ?? 0
//            }
//
//            // Fetch posts
//            let postsQuerySnapshot = try await db.collection("posts")
//                .whereField("userId", isEqualTo: userId)
//                .getDocuments()
//
//            var fetchedPosts = postsQuerySnapshot.documents.compactMap { document -> Post? in
//                let data = document.data()
//                guard let timestamp = data["timestamp"] as? Timestamp else {
//                    return nil
//                }
//
//                return Post(
//                    _id: document.documentID,
//                    userId: data["userId"] as? String ?? "",
//                    imageUrl: data["imageUrl"] as? String ?? "",
//                    timestamp: timestamp,
//                    review: data["review"] as? String ?? "",
//                    location: data["location"] as? String ?? "",
//                    restaurantName: data["restaurantName"] as? String ?? "",
//                    likes: data["likes"] as? Int ?? 0,
//                    likedBy: data["likedBy"] as? [String] ?? [],
//                    starRating: data["starRating"] as? Int ?? 0,
//                    comments: data["comments"] as? [Comment] ?? []
//                )
//            }
//
//            DispatchQueue.main.async {
//                fetchedPosts.sort { $0.date < $1.date }
//                self.posts = fetchedPosts
//                self.isLoading = false
//            }
//        } catch {
//            DispatchQueue.main.async {
//                self.errorMessage = error.localizedDescription
//                self.isLoading = false
//            }
//        }
//    }
//}
//
//


import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth

class ProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var username: String = ""
    @Published var posts: [Post] = []
    @Published var friendsCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var profilePicture: String? = nil
    @Published var profileImageUrl: String = ""

    private let authViewModel: AuthViewModel

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    // Load current user's profile
    func loadProfile() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User is not logged in."
            return
        }

        await loadProfileData(for: userId)
    }

    // Load a friend's profile
    func loadFriendProfile(userId: String) async {
        await loadProfileData(for: userId)
    }

    // Private helper to fetch profile data
    private func loadProfileData(for userId: String) async {
        isLoading = true
        do {
            let db = Firestore.firestore()

            // Fetch user details
            let userDocument = try await db.collection("users").document(userId).getDocument()
            guard let userData = userDocument.data() else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch user data."
                    self.isLoading = false
                }
                return
            }

            // Update user details
            DispatchQueue.main.async {
                self.name = userData["name"] as? String ?? "Unknown"
                self.username = userData["username"] as? String ?? "unknown"
                self.friendsCount = (userData["friends"] as? [String])?.count ?? 0
                self.profilePicture = userData["profilePicture"] as? String ?? "" // Fetch the profile picture
            }

            // Fetch posts
            let postsQuerySnapshot = try await db.collection("posts")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()

            var fetchedPosts = postsQuerySnapshot.documents.compactMap { document -> Post? in
                let data = document.data()
                guard let timestamp = data["timestamp"] as? Timestamp else {
                    return nil
                }

                return Post(
                    _id: document.documentID,
                    userId: data["userId"] as? String ?? "",
                    imageUrl: data["imageUrl"] as? String ?? "",
                    timestamp: timestamp,
                    review: data["review"] as? String ?? "",
                    location: data["location"] as? String ?? "",
                    restaurantName: data["restaurantName"] as? String ?? "",
                    likes: data["likes"] as? Int ?? 0,
                    likedBy: data["likedBy"] as? [String] ?? [],
                    starRating: data["starRating"] as? Int ?? 0,
                    comments: data["comments"] as? [Comment] ?? []
                )
            }

            DispatchQueue.main.async {
                fetchedPosts.sort { $0.date < $1.date }
                self.posts = fetchedPosts
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
