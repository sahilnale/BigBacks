import SwiftUI

struct FriendsView: View {
    @State private var showingFriendRequests = false
    @State private var showingAddFriend = false // New state for add friend sheet
    let currentUserId: String  // Add this property
    
    var body: some View {
        NavigationView {
            VStack {
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
                
                List {
                    ForEach(0..<5) { _ in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                            VStack(alignment: .leading) {
                                Text("Friend Name")
                                    .font(.headline)
                                Text("@username")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .navigationTitle("Friends")
                .navigationBarItems(trailing: Button("Add") {
                    showingAddFriend = true
                })
            }
            .sheet(isPresented: $showingAddFriend) {
                NavigationView {
                    AddFriendView(currentUserId: currentUserId)
                }
            }
        }
    }
}

struct FriendRequestView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            List {
                ForEach(0..<3) { _ in
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("Request Name")
                                .font(.headline)
                            Text("@username")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 15) {
                            Button(action: {
                                // Will implement accept later
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 25))
                            }
                            
                            Button(action: {
                                // Will implement reject later
                            }) {
                                Image(systemName: "x.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 25))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Friend Requests")
        .navigationBarItems(trailing: Button("Done") {
            dismiss()
        })
    }
}

// New AddFriendView
struct AddFriendView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchResults: [User] = []
    @State private var errorMessage: String?
    let currentUserId: String
    
    var body: some View {
        VStack {
            SearchBarView(searchText: $searchText)
            SearchResultsListView(
                isSearching: isSearching,
                searchResults: searchResults,
                searchText: searchText,
                currentUserId: currentUserId,
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
        .onChange(of: searchText) { performSearch($0) }
    }
    
    private func performSearch(_ query: String) {
        Task {
            if !query.isEmpty {
                isSearching = true
                do {
                    print("Searching for user with query: \(query)")
                    let results = try await NetworkManager.shared.searchUsers(query: query)
                    print("Search results: \(results)")
                    searchResults = results
                } catch {
                    print("Search error: \(error)")
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
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search by username...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
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
    let currentUserId: String
    @Binding var errorMessage: String?
    
    var body: some View {
        List {
            if isSearching {
                SearchLoadingView()
            } else if searchResults.isEmpty && !searchText.isEmpty {
                EmptyResultsView()
            } else {
                ForEach(searchResults) { user in
                    UserRowView(user: user, currentUserId: currentUserId, errorMessage: $errorMessage)
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
            
            AddFriendButton(
                user: user,
                currentUserId: currentUserId,
                isRequestPending: user.pendingRequests.contains(currentUserId),
                errorMessage: $errorMessage
            )
        }
        .padding(.vertical, 4)
    }
}

private struct AddFriendButton: View {
    let user: User
    let currentUserId: String
    let isRequestPending: Bool
    @Binding var errorMessage: String?
    
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
        Task {
            do {
                try await NetworkManager.shared.sendFriendRequest(from: currentUserId, to: user.id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    FriendsView(currentUserId: "account123")
}
