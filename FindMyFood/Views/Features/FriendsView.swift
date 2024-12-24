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
            VStack {
                // Button to View Friend Requests
                Button(action: {
                    showingFriendRequests = true
                }) {
                    Text("View Requests")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
                .sheet(isPresented: $showingFriendRequests) {
                    // Present FriendRequestView in its own NavigationStack
                    NavigationStack {
                        FriendRequestView()
                            .navigationTitle("Friend Requests")
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    
                                }
                            }
                    }
                }

                // Friends List or Loading/Error States
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(viewModel.friends) { friend in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading) {
                                Text(friend.name)
                                    .font(.headline)
                                Text("@\(friend.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadFriends()
                    // Fetch friends on view appearance
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFriend = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddFriend) {
            // Present AddFriendView in its own NavigationStack
            NavigationStack {
                AddFriendView(
                    currentUserId: authViewModel.currentUser?.id ?? "",
                    friends: viewModel.friends.map { $0.id }
                )
                .navigationTitle("Add Friends")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        
                    }
                }
            }
        }
    }
}




import SwiftUI

struct FriendRequestView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var friendRequests: [User] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if friendRequests.isEmpty {
                Text("No friend requests")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach(friendRequests) { requester in
                        FriendRequestRow(
                            requester: requester,
                            onAccept: { acceptRequest(from: requester) },
                            onReject: { rejectRequest(from: requester) }
                        )
                    }
                }
            }
        }
        .navigationTitle("Friend Requests")
        .navigationBarItems(trailing: Button("Done") { dismiss() })
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            await loadFriendRequests()
        }
    }
    
    private func loadFriendRequests() async {
        guard let currentUserId = authViewModel.currentUser?.id else {
            errorMessage = "Not logged in"
            isLoading = false
            return
        }
        
        do {
            friendRequests = try await authViewModel.getFriendRequests(for: currentUserId)
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
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(requester.name)
                    .font(.headline)
                Text("@\(requester.username)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 15) {
                Button(action: onAccept) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 25))
                }.buttonStyle(BorderlessButtonStyle())
                
                Button(action: onReject) {
                    Image(systemName: "x.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 25))
                }.buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
}

//Add friend view
import SwiftUI

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
        VStack {
            SearchBarView(searchText: $searchText) {
                performSearch(searchText)
            }
            SearchResultsListView(
                searchResults: $searchResults,
                isSearching: $isSearching,
                searchText: $searchText,
                errorMessage: $errorMessage,
                friends: friends
            )
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

            TextField("Search by username...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .onSubmit(onSearch)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
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
        List {
            if isSearching {
                SearchLoadingView()
            } else if searchResults.isEmpty && !searchText.isEmpty {
                EmptyResultsView()
            } else {
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
        }
        .listStyle(PlainListStyle())
    }
}



private struct SearchLoadingView: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Spacer()
        }
    }
}

private struct EmptyResultsView: View {
    var body: some View {
        HStack {
            Spacer()
            Text("No users found")
                .foregroundColor(.gray)
                .padding()
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
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.headline)
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isAlreadyRequestedBy {
                Text("Request waiting")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
            else if !isAlreadyFriend {
                AddFriendButton(
                    user: user,
                    currentUserId: currentUserId,
                    isRequestPending: user.friendRequests.contains(currentUserId),
                    errorMessage: $errorMessage
                )
            }
        }
        .padding(.vertical, 4)
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
            Text(isRequestPending ? "Pending" : "Add")
                .foregroundColor(isRequestPending ? .gray : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isRequestPending ? Color(.systemGray5) : Color(.systemBlue).opacity(0.1))
                .cornerRadius(20)
        }
        .disabled(isRequestPending)
    }

    private func sendFriendRequest() {
        guard !isRequestPending else { return }
        
        Task {
            do {
                // Call `sendFriendRequest` from `AuthViewModel`
                try await AuthViewModel.shared.sendFriendRequest(from: currentUserId, to: user.id)
                isRequestPending = true // Update state to show "Pending"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
