//
//  ProfileViewModel.swift
//  FindMyFood
//
//  Created by Ridhima Morampudi on 11/24/24.
//
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
    @Published var mutualFriendsCount: Int = 0
    @Published var mutualFriends: [User] = []

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

        await loadProfileData(for: userId, isFriendProfile: false)
    }

    // Load a friend's profile
    func loadFriendProfile(userId: String) async {
           await loadProfileData(for: userId, isFriendProfile: true)
       }

    // Shared logic
    private func loadProfileData(for userId: String, isFriendProfile: Bool) async {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        do {
            let db = Firestore.firestore()

            // Fetch user document
            let userDocument = try await db.collection("users").document(userId).getDocument()
            guard let userData = userDocument.data() else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch user data."
                    self.isLoading = false
                }
                return
            }

            DispatchQueue.main.async {
                self.name = userData["name"] as? String ?? "Unknown"
                self.username = userData["username"] as? String ?? "unknown"
                self.friendsCount = (userData["friends"] as? [String])?.count ?? 0
                self.profilePicture = userData["profilePicture"] as? String
            }

            // Fetch posts
            let postsQuerySnapshot = try await db.collection("posts")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()

            var fetchedPosts = postsQuerySnapshot.documents.compactMap { document -> Post? in
                let data = document.data()
                guard let timestamp = data["timestamp"] as? Timestamp else { return nil }

                let imageUrls = data["imageUrls"] as? [String] ?? {
                    let singleImageUrl = data["imageUrl"] as? String
                    return singleImageUrl != nil ? [singleImageUrl!] : []
                }()

                return Post(
                    _id: document.documentID,
                    userId: data["userId"] as? String ?? "",
                    imageUrls: imageUrls,
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
                fetchedPosts.sort { $0.timestamp.dateValue() < $1.timestamp.dateValue() }
                self.posts = fetchedPosts
            }

            // Fetch mutual friends only if this is a friend's profile
            if isFriendProfile {
               let mutualFriendsList = try await authViewModel.getMutualFriends(with: userId)
               DispatchQueue.main.async {
                   self.mutualFriends = mutualFriendsList
                   self.mutualFriendsCount = mutualFriendsList.count
               }
           }

            DispatchQueue.main.async {
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
