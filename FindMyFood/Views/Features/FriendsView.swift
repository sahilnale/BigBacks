import SwiftUI

struct FriendsView: View {
    @State private var showingFriendRequests = false
    @State private var showingAddFriend = false

    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: FriendsViewModel

    init(authViewModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: FriendsViewModel(authViewModel: authViewModel))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Friend Requests Button
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                    
                    Button(action: {
                        showingFriendRequests = true
                        viewModel.markRequestsAsViewed()
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.accentColor)
                            
                            Text("Friend Requests (\(viewModel.friendRequests.count))")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Indicator for new requests
                            if viewModel.hasNewRequests {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 18, height: 18)
                                    
                                    Text("\(min(viewModel.friendRequests.count, 9))")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                    }
                }
                .frame(height: 60)
                .padding(.horizontal)
                .padding(.top)

                // Friends List or Loading/Error States
                if viewModel.isLoading {
                    Spacer()
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                        
                        Text("Loading your friends...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.top, 12)
                    }
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("Error: \(errorMessage)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            Task {
                                await viewModel.loadFriends()
                                await viewModel.loadFriendRequests()
                            }
                        }) {
                            Text("Retry")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.accentColor)
                                .cornerRadius(8)
                        }
                    }
                    Spacer()
                } else if viewModel.friends.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No Friends Yet")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Add friends to connect with them")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            showingAddFriend = true
                        }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Find Friends")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .cornerRadius(10)
                        }
                        .padding(.top, 8)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.friends) { friend in
                            NavigationLink(destination: FriendProfileView(userId: friend.id)) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(.systemGray5))
                                            .frame(width: 50, height: 50)
                                        
                                        Text(String(friend.name.prefix(1)))
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.accentColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(friend.name)
                                            .font(.system(size: 17, weight: .semibold))
                                        
                                        Text("@\(friend.username)")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
//                                    Image(systemName: "chevron.right")
//                                        .font(.system(size: 14, weight: .semibold))
//                                        .foregroundColor(Color(.systemGray4))
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        .onDelete(perform: removeFriend)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadFriends()
                    await viewModel.loadFriendRequests()
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFriend = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingFriendRequests) {
            NavigationStack {
                FriendRequestView()
                    .environmentObject(authViewModel)
                    .navigationTitle("Friend Requests")
            }
        }
        .sheet(isPresented: $showingAddFriend) {
            NavigationStack {
                AddFriendView(
                    currentUserId: authViewModel.currentUser?.id ?? "",
                    friends: viewModel.friends.map { $0.id }
                )
                .navigationTitle("Add Friends")
                .environmentObject(authViewModel)
            }
        }
    }

    private func removeFriend(at offsets: IndexSet) {
        for index in offsets {
            let friend = viewModel.friends[index]
            Task {
                await viewModel.deleteFriend(friend)
            }
        }
    }
}

// Friend Requests View
struct FriendRequestView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var friendRequests: [User] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading requests...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .padding()
            } else if !friendRequests.isEmpty {
                List {
                    ForEach(friendRequests) { requester in
                        FriendRequestRow(
                            requester: requester,
                            onAccept: { acceptRequest(from: requester) },
                            onReject: { rejectRequest(from: requester) }
                        )
                    }
                }
                .listStyle(PlainListStyle())
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .font(.system(size: 60))
                        .foregroundColor(Color(.systemGray4))
                    
                    Text("No Friend Requests")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("When someone sends you a friend request, it will appear here")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
        }
        .navigationTitle("Friend Requests")
        .onAppear {
            Task {
                await loadFriendRequests()
            }
        }
    }
    
    private func loadFriendRequests() async {
        guard let currentUserId = authViewModel.currentUser?.id else {
            errorMessage = "Not logged in"
            isLoading = false
            return
        }
        
        do {
            let fetchedRequests = try await authViewModel.getFriendRequests(for: currentUserId)
            
            // Extract only the User objects from the tuples
            friendRequests = fetchedRequests.map { $0.0 }
            
            print("Friend Requests Fetched: \(friendRequests)") // Debugging output
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private func acceptRequest(from user: User) {
        guard let currentUserId = authViewModel.currentUser?.id else {
            errorMessage = "Not logged in"
            return
        }

        authViewModel.acceptFriendRequest(currentUserId: currentUserId, friendId: user.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Remove the accepted request from the list
                    friendRequests.removeAll { $0.id == user.id }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func rejectRequest(from user: User) {
        guard let currentUserId = authViewModel.currentUser?.id else {
            errorMessage = "Not logged in"
            return
        }

        authViewModel.rejectFriendRequest(currentUserId: currentUserId, friendId: user.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Remove the rejected request from the list
                    friendRequests.removeAll { $0.id == user.id }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct FriendRequestRow: View {
    let requester: User
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 50, height: 50)
                
                Text(String(requester.name.prefix(1)))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(requester.name)
                    .font(.system(size: 17, weight: .semibold))
                
                Text("@\(requester.username)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: onAccept) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Button(action: onReject) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 6)
    }
}

// Add Friend view
struct AddFriendView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchResults: [User] = []
    @State private var errorMessage: String?
    let currentUserId: String
    let friends: [String] // Pass the list of friend IDs
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBarView(searchText: $searchText) {
                performSearch(searchText)
            }
            .padding(.top, 8)
            
            if searchText.isEmpty {
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(Color(.systemGray3))
                    
                    Text("Search for friends")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text("Find friends by their username")
                        .font(.system(size: 16))
                        .foregroundColor(Color(.systemGray))
                    
                    Spacer()
                }
            } else {
                SearchResultsListView(
                    searchResults: $searchResults,
                    isSearching: $isSearching,
                    searchText: $searchText,
                    errorMessage: $errorMessage,
                    friends: friends
                )
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .navigationTitle("Add Friends")
        .navigationBarItems(trailing: Button("Done") { dismiss() })
    }
    
    private func performSearch(_ query: String) {
        Task {
            if !query.isEmpty {
                isSearching = true
                do {
                    let results = try await authViewModel.searchUsers(by: query)
                    DispatchQueue.main.async {
                        searchResults = results
                    }
                } catch {
                    DispatchQueue.main.async {
                        errorMessage = error.localizedDescription
                    }
                }
                isSearching = false
            } else {
                searchResults = []
            }
        }
    }
}

// MARK: - Supporting Views
// MARK: - Search Bar View
private struct SearchBarView: View {
    @Binding var searchText: String
    var onSearch: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16, weight: .medium))

            TextField("Search by username...", text: $searchText)
                .font(.system(size: 16))
                .padding(.vertical, 12)
                .onSubmit(onSearch)
                .onChange(of: searchText) { _ in
                    onSearch()
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    onSearch()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(.systemGray3))
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

// MARK: - Search Results List View
private struct SearchResultsListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // Access from environment
    @Binding var searchResults: [User]
    @Binding var isSearching: Bool
    @Binding var searchText: String
    @Binding var errorMessage: String?
    let friends: [String]

    var body: some View {
        if isSearching {
            SearchLoadingView()
        } else if searchResults.isEmpty && !searchText.isEmpty {
            EmptyResultsView()
        } else {
            List {
                ForEach(searchResults) { user in
                    UserRowView(
                        user: user,
                        currentUserId: authViewModel.currentUser?.id ?? "",
                        errorMessage: $errorMessage,
                        isAlreadyFriend: friends.contains(user.id),
                        isAlreadyRequestedBy: user.pendingRequests.contains(authViewModel.currentUser?.id ?? "")
                    )
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

private struct SearchLoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Searching...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .padding(.top, 12)
            
            Spacer()
        }
    }
}

private struct EmptyResultsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.slash")
                .font(.system(size: 50))
                .foregroundColor(Color(.systemGray3))
            
            Text("No users found")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.gray)
            
            Text("Try a different username")
                .font(.system(size: 16))
                .foregroundColor(Color(.systemGray))
            
            Spacer()
        }
    }
}

private struct UserRowView: View {
    let user: User
    let currentUserId: String
    @Binding var errorMessage: String?
    let isAlreadyFriend: Bool // Check if the user is already a friend
    let isAlreadyRequestedBy: Bool
    @State private var requestHandled = false
    @State private var requestAccepted = false

    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 50, height: 50)
                
                Text(String(user.name.prefix(1)))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.system(size: 17, weight: .semibold))
                
                Text("@\(user.username)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isAlreadyFriend {
                Text("Friend")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(16)
            } else if isAlreadyRequestedBy && !requestHandled {
                HStack(spacing: 8) {
                    Button(action: {
                        acceptRequest(from: user)
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())

                    Button(action: {
                        rejectRequest(from: user)
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "xmark")
                                .foregroundColor(.red)
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            } else if requestAccepted || isAlreadyFriend {
                Text("Friend")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(16)
            }
            else {
                AddFriendButton(
                    user: user,
                    currentUserId: currentUserId,
                    isRequestPending: user.friendRequests.contains(currentUserId),
                    errorMessage: $errorMessage
                )
            }
        }
        .padding(.vertical, 6)
    }
    private func acceptRequest(from user: User) {
        AuthViewModel.shared.acceptFriendRequest(currentUserId: currentUserId, friendId: user.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    requestHandled = true
                    requestAccepted = true
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func rejectRequest(from user: User) {
        AuthViewModel.shared.rejectFriendRequest(currentUserId: currentUserId, friendId: user.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    requestHandled = true
                    requestAccepted = false
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

private struct AddFriendButton: View {
    let user: User
    let currentUserId: String
    @State private var isRequestPending: Bool
    @Binding var errorMessage: String?

    init(user: User, currentUserId: String, isRequestPending: Bool, errorMessage: Binding<String?>) {
        self.user = user
        self.currentUserId = currentUserId
        self._isRequestPending = State(initialValue: isRequestPending)
        self._errorMessage = errorMessage
    }

    var body: some View {
        Button(action: sendFriendRequest) {
            HStack(spacing: 4) {
                if !isRequestPending {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 12, weight: .semibold))
                }
                
                Text(isRequestPending ? "Pending" : "Add Friend")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isRequestPending ? .gray : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isRequestPending ? Color(.systemGray5) : Color.accentColor)
            .cornerRadius(18)
        }
        .disabled(isRequestPending) // Prevent clicking when pending
    }

    private func sendFriendRequest() {
        guard !isRequestPending else { return }
        
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
