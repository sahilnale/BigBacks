import SwiftUI
import Firebase

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
    private var listener: ListenerRegistration?

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        self.hasNewRequests = UserDefaults.standard.bool(forKey: "hasNewRequests")

        Task { @MainActor in
            self.observeFriendRequests()
        }
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
            let users = fetchedRequests.map { $0.0 }

            DispatchQueue.main.async {
                self.friendRequests = users
                self.hasNewRequests = !users.isEmpty
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

    func deleteFriend(_ friend: User) async {
        guard let currentUserId = await authViewModel.currentUser?.id else { return }

        do {
            try await authViewModel.removeFriend(currentUserId: currentUserId, friendId: friend.id)
            DispatchQueue.main.async {
                self.friends.removeAll { $0.id == friend.id }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to remove friend: \(error.localizedDescription)"
            }
        }
    }

    @MainActor func observeFriendRequests() {
        guard let userId = authViewModel.currentUser?.id else { return }

        listener = Firestore.firestore().collection("users").document(userId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error listening to friend requests: \(error)")
                    return
                }

                if let data = documentSnapshot?.data(),
                   let friendRequestIds = data["friendRequests"] as? [String] {
                    Task {
                        do {
                            var users: [User] = []
                            for id in friendRequestIds {
                                if let user = try await self.authViewModel.getUserById(friendId: id) {
                                    users.append(user)
                                }
                            }
                            DispatchQueue.main.async {
                                self.friendRequests = users
                                self.hasNewRequests = !users.isEmpty
                            }
                        } catch {
                            print("Failed to fetch friend request users: \(error)")
                        }
                    }
                }
            }
    }

    deinit {
        listener?.remove()
    }
}
