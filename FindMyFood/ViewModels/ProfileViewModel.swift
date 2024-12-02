//
//  ProfileViewModel.swift
//  FindMyFood
//
//  Created by Ridhima Morampudi on 11/24/24.
//

import Foundation

class ProfileViewModel: ObservableObject {
    @Published var name: String = "Loading..."
    @Published var username: String = "Loading..."
    @Published var errorMessage: String? = nil
    @Published var posts: [Post] = []
    @Published var friendsCount: Int = 0
    @Published var isLoading: Bool = false
    
        func loadProfile() async {
            guard let userId = AuthManager.shared.userId else {
                errorMessage = "User is not logged in."
                return
            }

            isLoading = true

            do {
                // Fetch the user, which includes their posts
                let user = try await NetworkManager.shared.getCurrentUser(userId: userId)

                // Update the UI on the main thread
                DispatchQueue.main.async {
                    self.name = user.name
                    self.username = user.username
                    self.posts = user.posts
                    self.friendsCount = user.friends.count
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    

    
    
    
    
}//end
