import SwiftUI

struct FriendsView: View {
    @State private var showingFriendRequests = false
    @State private var showingAddFriend = false // New state for add friend sheet
    let currentUserId: String  // Add this property
    @StateObject private var viewModel = FriendsViewModel() // Initialize the view model
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 10) {
                    HStack(spacing: 20) {
                        Button(action: {
                            showingFriendRequests = true
                        }) {
                            Text("View Requests")
                                .font(.headline)
                        }
                        .foregroundColor(.accentColor)
                        .sheet(isPresented: $showingFriendRequests) {
                            NavigationView {
                                FriendRequestView()
                            }
                        }
                        Button(action: {
                            showingAddFriend = true
                        }) {
                            Text("Add Friends").font(.headline)
                        }.foregroundColor(.accentColor)
                    }.padding(.top, 40)
                    
                    // Display friends in the List view
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
                    // Wrap async function call in a Task to support concurrency
                    Task {
                        await viewModel.loadFriends(for: currentUserId) // Fetch friends when the view appears
                    }
                }
//                .navigationTitle("Friends")
//                .navigationBarItems(trailing: Button("Add") {
//                    showingAddFriend = true
//                })
                
                VStack {
                    HStack {
                        Image("transparentLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 65, height: 65) // Adjust the size of the image
                            .padding(.leading, 10) // Add padding to align properly
                        Text("FindMyFood")
                            .font(.system(.largeTitle, design: .serif))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                           // .padding(.leading, 5) // Add padding between image and text
                        Spacer()
                    }
                    .padding(.top, 65)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity, maxHeight: 95)
                    .background(Color.accentColor.opacity(0.8))
                    .ignoresSafeArea(edges: .top) // Makes the content extend to the top edge
                    Spacer() // Pushes the main content below
                }
            }
        }
       // .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showingAddFriend) {
            NavigationView {
                AddFriendView(
                    currentUserId: currentUserId,
                    friends: viewModel.friends.map { $0.id } // Extract friend IDs
                )
            }
        }
    }
}

struct FriendRequestView: View {
    @Environment(\.dismiss) var dismiss
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
        guard let currentUserId = AuthManager.shared.userId else {
            errorMessage = "Not logged in"
            isLoading = false
            return
        }
        
        do {
            friendRequests = try await NetworkManager.shared.getFriendRequests(userId: currentUserId)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private func acceptRequest(from user: User) {
        guard let currentUserId = AuthManager.shared.userId else {
            errorMessage = "Not logged in"
            return
        }
        
        Task {
            do {
                try await NetworkManager.shared.acceptFriendRequest(userId: currentUserId, friendId: user.id)
                // Remove the accepted request from the list
                friendRequests.removeAll { $0.id == user.id }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func rejectRequest(from user: User) {
        guard let currentUserId = AuthManager.shared.userId, !currentUserId.isEmpty else {
            errorMessage = "Not logged in"
            return
        }
        
        guard !user.id.isEmpty else {
            errorMessage = "Invalid friend ID"
            return
        }
        
        Task {
            do {
                try await NetworkManager.shared.rejectFriendRequest(userId: currentUserId, friendId: user.id)
                friendRequests.removeAll { $0.id == user.id }
            } catch let networkError as NetworkError {
                switch networkError {
                case .invalidURL:
                    errorMessage = "Invalid URL"
                case .invalidResponse:
                    errorMessage = "Invalid response from server"
                case .badRequest(let message):
                    errorMessage = "Bad request: \(message)"
                default:
                    errorMessage = "Unknown error occurred"
                }
                print("Error rejecting friend request: \(errorMessage ?? "Unknown error")")
            } catch {
                errorMessage = error.localizedDescription
                print("Unexpected error: \(error.localizedDescription)")
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
struct AddFriendView: View {
    @Environment(\.dismiss) var dismiss
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
                isSearching: isSearching,
                searchResults: searchResults,
                searchText: searchText,
                friends: friends,
                errorMessage: $errorMessage
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
                    let results = try await NetworkManager.shared.searchUsers(query: query)
                    searchResults = results
                } catch {
                    errorMessage = error.localizedDescription
                }
                isSearching = false
            } else {
                searchResults = []
            }
        }
    }
}

// MARK: - Supporting Views
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

private struct SearchResultsListView: View {
    let isSearching: Bool
    let searchResults: [User]
    let searchText: String
    @State private var currentUserId: String?
    let friends: [String] // Pass friends list here
    @Binding var errorMessage: String?
    
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
                        currentUserId: currentUserId ?? " ",
                        errorMessage: $errorMessage,
                        isAlreadyFriend: friends.contains(user.id), // Check if user is a friend
                        isAlreadyRequestedBy: user.pendingRequests.contains(currentUserId ?? " ")
                    )
                }
            }
        }
        .listStyle(PlainListStyle())
        .onAppear {
                    loadCurrentUserId()
        }
    }

private func loadCurrentUserId() {
        guard let id = AuthManager.shared.userId else {
            errorMessage = "Not logged in"
            return
        }
        currentUserId = id
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
                try await NetworkManager.shared.sendFriendRequest(from: currentUserId, to: user.id)
                isRequestPending = true // Update state to show "Pending"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
