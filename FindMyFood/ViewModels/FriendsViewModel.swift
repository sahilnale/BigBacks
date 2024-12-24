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
        isLoading = true
        errorMessage = nil

        do {
            // Use the new `getFriends` function from `AuthViewModel`
            let fetchedFriends = try await authViewModel.getFriends()
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

    func acceptFriendRequest(from friend: User) async {
        guard let currentUser = await authViewModel.currentUser else {
            self.errorMessage = "User is not logged in."
            return
        }

        do {
            // Call the main actor-isolated `acceptFriendRequest` method using `await`
            try await withCheckedThrowingContinuation { continuation in
                Task { @MainActor in
                    authViewModel.acceptFriendRequest(currentUserId: currentUser.id, friendId: friend.id) { result in
                        switch result {
                        case .success:
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }

            // Reload the friends list from the database
            await loadFriends()
        } catch {
            self.errorMessage = "Failed to accept friend request: \(error.localizedDescription)"
        }
    }

    
    func rejectFriendRequest(from friend: User) async {
        guard let currentUser = await authViewModel.currentUser else {
            self.errorMessage = "User is not logged in."
            return
        }

        do {
            // Call the main actor-isolated `rejectFriendRequest` method using `await`
            try await withCheckedThrowingContinuation { continuation in
                Task { @MainActor in
                    authViewModel.rejectFriendRequest(currentUserId: currentUser.id, friendId: friend.id) { result in
                        switch result {
                        case .success:
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }

            // Reload the friends list from the database
            await loadFriends()
        } catch {
            self.errorMessage = "Failed to reject friend request: \(error.localizedDescription)"
        }
    }


}
