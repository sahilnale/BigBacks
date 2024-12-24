import SwiftUI

class FriendsViewModel: ObservableObject {
    @Published var friends: [User] = [] // To store the friends list
    @Published var isLoading: Bool = false // To show loading state
    @Published var errorMessage: String? // To handle errors

    private let authViewModel: AuthViewModel

    // Dependency injection for `AuthViewModel`
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    func loadFriends() async {
        guard let currentUser = await authViewModel.currentUser else {
            DispatchQueue.main.async {
                self.errorMessage = "User is not logged in."
            }
            return
        }

        isLoading = true

        do {
            var fetchedFriends: [User] = []
            
            // Iterate through friends' IDs and fetch their data
            for friendId in currentUser.friends {
                do {
                    if let friend = try await authViewModel.getUserById(friendId: friendId) {
                        fetchedFriends.append(friend)
                    }
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
                self.errorMessage = "Failed to load friends: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}
