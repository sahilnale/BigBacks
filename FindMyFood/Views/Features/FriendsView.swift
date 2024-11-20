import SwiftUI

struct FriendsView: View {
    @State private var showingFriendRequests = false
    @State private var showingAddFriend = false // New state for add friend sheet
    
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
                    AddFriendView()
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
    @State private var searchResults: [UserProfile] = []
    
    // Model for user profile data
    struct UserProfile: Identifiable {
        let id: String
        let username: String
        let displayName: String
        var isRequestSent: Bool
    }
    
    var body: some View {
        VStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search by username...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: searchText) { newValue in
                        // MARK: - Backend Implementation
                        // Implement your search logic here
                        // 1. Debounce the search input
                        // 2. Make API call to search users
                        // 3. Update searchResults array
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchResults = []
                    }) {
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
            
            // Search results list
            List {
                if isSearching {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    HStack {
                        Spacer()
                        Text("No users found")
                            .foregroundColor(.gray)
                            .padding()
                        Spacer()
                    }
                } else {
                    ForEach(searchResults) { user in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text(user.displayName)
                                    .font(.headline)
                                Text("@\(user.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // MARK: - Backend Implementation
                                // Implement send friend request logic here
                                // 1. Make API call to send friend request
                                // 2. Update UI to show pending state
                            }) {
                                Text(user.isRequestSent ? "Pending" : "Add")
                                    .foregroundColor(user.isRequestSent ? .gray : .blue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(user.isRequestSent ? Color(.systemGray5) : Color(.systemBlue).opacity(0.1))
                                    .cornerRadius(20)
                            }
                            .disabled(user.isRequestSent)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("Add Friends")
        .navigationBarItems(trailing: Button("Done") {
            dismiss()
        })
    }
}

#Preview {
    FriendsView()
}
