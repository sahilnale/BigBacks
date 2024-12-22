//
//  ProfileViewModel.swift
//  FindMyFood
//
//  Created by Ridhima Morampudi on 11/24/24.
//

//import Foundation
//
//class ProfileViewModel: ObservableObject {
//    @Published var name: String = "Loading..."
//    @Published var username: String = "Loading..."
//    @Published var errorMessage: String? = nil
//    @Published var posts: [Post] = []
//    @Published var friendsCount: Int = 0
//    @Published var isLoading: Bool = false
//    
//        func loadProfile() async {
//            guard let userId = AuthManager.shared.userId else {
//                errorMessage = "User is not logged in."
//                return
//            }
//
//            isLoading = true
//
//            do {
//                // Fetch the user, which includes their posts
//                let user = try await NetworkManager.shared.getCurrentUser(userId: userId)
//
//                // Update the UI on the main thread
//                DispatchQueue.main.async {
//                    self.name = user.name
//                    self.username = user.username
//                    self.posts = user.posts
//                    self.friendsCount = user.friends.count
//                    self.isLoading = false
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
//                    self.isLoading = false
//                }
//            }
//        }
//    
//
//    
//    
//    
//    
//}//end

import Foundation
import UIKit

class ProfileViewModel: ObservableObject {
    @Published var name: String = "Loading..."
    @Published var username: String = "Loading..."
    @Published var errorMessage: String? = nil
    @Published var posts: [Post] = []
    @Published var friendsCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var profileImage: String? // To store the profile image URL
    @Published var isUploadingImage: Bool = false // New property for upload status
    @Published var selectedImage: UIImage?
    

    func loadProfile() async {
        guard let userId = AuthManager.shared.userId else {
            errorMessage = "User is not logged in."
            return
        }

        isLoading = true

        do {
            let user = try await NetworkManager.shared.getCurrentUser(userId: userId)

            // Fetch all posts for the user
            var postObjects: [Post] = []
            for postId in user.posts {
                let post = try await NetworkManager.shared.fetchPostDetails(postId: postId)
                postObjects.append(post)
            }

            DispatchQueue.main.async {
                self.name = user.name
                self.username = user.username
                self.posts = postObjects // Assign the fetched Post objects
                self.friendsCount = user.friends.count
                self.profileImage = user.profilePicture
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    // New method to upload the profile image
    func uploadProfilePicture(image: UIImage) async {
        guard let userId = AuthManager.shared.userId else {
            DispatchQueue.main.async {
                self.errorMessage = "User is not logged in."
            }
            return
        }

        isUploadingImage = true

        // Safely unwrap selectedImage before using it
        if let unwrappedImage = selectedImage {
            do {
                let uploadedProfilePic = try await NetworkManager.shared.uploadProfilePic(userId: userId, image: unwrappedImage)
                DispatchQueue.main.async {
                    self.profileImage = uploadedProfilePic // Update the profile image with the new URL
                    self.isUploadingImage = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to upload profile picture: \(error.localizedDescription)"
                    self.isUploadingImage = false
                }
            }
        } else {
            DispatchQueue.main.async {
                self.errorMessage = "No image selected."
                self.isUploadingImage = false
            }
        }
    }

    
    
}

