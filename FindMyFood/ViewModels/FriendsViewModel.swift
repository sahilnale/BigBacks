//
//  FriendsViewModel.swift
//  FindMyFood
//
//  Created by Ridhima Morampudi on 11/26/24.
//

import SwiftUI

class FriendsViewModel: ObservableObject {
    @Published var friends: [User] = [] // To store the friends list
    @Published var isLoading: Bool = false // To show loading state
    @Published var errorMessage: String? // To handle errors

    func loadFriends(for userId: String) async {
        guard let userId = AuthManager.shared.userId else {
            errorMessage = "User is not logged in."
            return
        }

        isLoading = true

        do {
            // Fetch the current user to access their friends (friend IDs)
            let user = try await NetworkManager.shared.getCurrentUser(userId: userId)

            // Fetch data for each friend
            var fetchedFriends: [User] = []
            for friendId in user.friends {
                do {
                    let friend = try await NetworkManager.shared.getUserById(userId: friendId)
                    fetchedFriends.append(friend)
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to load friend with ID \(friendId): \(error.localizedDescription)"
                    }
                }
            }

            // Update the UI on the main thread
            DispatchQueue.main.async {
                self.friends = fetchedFriends
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load user: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}//end


