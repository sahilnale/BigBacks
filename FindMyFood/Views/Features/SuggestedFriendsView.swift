import SwiftUI

struct SuggestedFriendsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: SuggestedFriendsViewModel
    
    init(authViewModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: SuggestedFriendsViewModel(authViewModel: authViewModel))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Finding friends...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .padding()
                } else if viewModel.suggestedFriends.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 60))
                            .foregroundColor(Color(.systemGray4))
                        
                        Text("No Suggested Friends")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("We'll show you people you might know here")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(viewModel.suggestedFriends) { user in
                            SuggestedFriendRow(user: user)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Suggested Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadSuggestedFriends()
            }
        }
    }
}

struct SuggestedFriendRow: View {
    let user: User
    @State private var isRequestPending = false
    @State private var errorMessage: String?
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            if let profilePicture = user.profilePicture {
                AsyncImage(url: URL(string: profilePicture)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.system(size: 16, weight: .semibold))
                Text("@\(user.username)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Add Friend Button
            Button(action: {
                sendFriendRequest()
            }) {
                Text(isRequestPending ? "Requested" : "Add Friend")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isRequestPending ? .gray : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isRequestPending ? Color(.systemGray5) : Color.accentColor2)
                    .cornerRadius(16)
            }
            .disabled(isRequestPending)
        }
        .padding(.vertical, 8)
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func sendFriendRequest() {
        guard let currentUserId = AuthViewModel.shared.currentUser?.id else { return }
        
        Task {
            do {
                let currentUser = AuthViewModel.shared.currentUser
                let fromUserName = currentUser?.username ?? "Unknown"
                
                try await AuthViewModel.shared.sendFriendRequest(
                    from: currentUserId,
                    to: user.id,
                    fromUserName: fromUserName
                )
                isRequestPending = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

class SuggestedFriendsViewModel: ObservableObject {
    @Published var suggestedFriends: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    @MainActor
    func loadSuggestedFriends() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let currentUserId = authViewModel.currentUser?.id else {
                throw NSError(domain: "No user logged in", code: 1)
            }
            
            // Get current user's friends
            let currentUserFriends = try await authViewModel.getFriends()
            let currentUserFriendIds = Set(currentUserFriends.map { $0.id })
            
            // Get all users
            let allUsers = try await authViewModel.searchUsers(by: "")
            
            // Filter out current user, current friends, and users who have pending requests
            let suggestedUsers = allUsers.filter { user in
                user.id != currentUserId && // Not current user
                !currentUserFriendIds.contains(user.id) && // Not already a friend
                !user.friendRequests.contains(currentUserId) && // No pending request from current user
                !user.pendingRequests.contains(currentUserId) // No pending request to current user
            }
            
            // Calculate mutual friends count for each suggested user
            var usersWithMutualCount: [(user: User, mutualCount: Int)] = []
            
            for user in suggestedUsers {
                let mutualCount = try await authViewModel.getMutualFriendsCount(with: user.id)
                usersWithMutualCount.append((user: user, mutualCount: mutualCount))
            }
            
            // Sort by mutual friends count (descending) and take top 10
            suggestedFriends = usersWithMutualCount
                .sorted { $0.mutualCount > $1.mutualCount }
                .prefix(5)
                .map { $0.user }
            
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
