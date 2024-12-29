import SwiftUI

class FriendsViewModel: ObservableObject {
    @Published var friends: [User] = []
    @Published var friendRequests: [User] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasNewRequests: Bool {
        didSet {
            UserDefaults.standard.set(hasNewRequests, forKey: "hasNewRequests")
        }
    }

    private let authViewModel: AuthViewModel

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        self.hasNewRequests = UserDefaults.standard.bool(forKey: "hasNewRequests") // Load from UserDefaults
    }

    func loadFriends() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let fetchedFriends = try await authViewModel.getFriends()
            DispatchQueue.main.async {
                self.friends = fetchedFriends
                print("Friends Loaded: \(self.friends.count)") // Debugging
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load friends: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    func loadFriendRequests() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            guard let currentUserId = await authViewModel.currentUser?.id else {
                throw NSError(domain: "No user logged in", code: 1)
            }

            let fetchedRequests = try await authViewModel.getFriendRequests(for: currentUserId)
            DispatchQueue.main.async {
                self.friendRequests = fetchedRequests
                self.hasNewRequests = !fetchedRequests.isEmpty
                print("Friend Requests Updated: \(self.friendRequests.count)") // Debugging
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load friend requests: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    func markRequestsAsViewed() {
        DispatchQueue.main.async {
            self.hasNewRequests = false
        }
    }
}
