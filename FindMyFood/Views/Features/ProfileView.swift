//import SwiftUI
//
//struct ProfileView: View {
//    @EnvironmentObject var authViewModel: AuthViewModel // Inject the AuthViewModel instance
//    @StateObject private var viewModel = ProfileViewModel()
//    
//    private let columns = [
//        GridItem(.flexible()),
//        GridItem(.flexible()),
//        GridItem(.flexible())
//    ]
//    
//    var body: some View {
//        NavigationView {
//            ScrollView{
//                VStack {
//                    Image(systemName: "person.circle.fill")
//                        .font(.system(size: 100))
////                    Text("Name")
////                        .font(.headline)
////                    Text("@username")
////                        .font(.subheadline)
//                    if let errorMessage = viewModel.errorMessage {
//                        Text(errorMessage)
//                        .foregroundColor(.red)
//                        .padding()
//                    } else {
//                        Text(viewModel.name)
//                        .font(.headline)
//                        Text("@\(viewModel.username)")
//                        .font(.subheadline)
//                    }
//                    
//                    // Light grey rounded box containing the 4x3 grid of posts
//                    // Removed the RoundedRectangle container to avoid the big grey box
//                    // Posts Grid
//                                    if viewModel.isLoading {
//                                        ProgressView("Loading posts...")
//                                            .padding()
//                                    } else if viewModel.posts.isEmpty {
//                                        Text("No posts yet.")
//                                            .foregroundColor(.gray)
//                                            .padding()
//                                    } else {
//                                        ScrollView {
//                                            LazyVGrid(columns: columns, spacing: 8) {
//                                                ForEach(viewModel.posts, id: \._id) { post in
//                                                    // Create a small box for each post
//                                                    NavigationLink(destination: PostDetailView(post: post)) {
//                                                        AsyncImage(url: URL(string: post.imageUrl)) { image in
//                                                            image
//                                                                .resizable()
//                                                                .scaledToFill()
//                                                        } placeholder: {
//                                                            Color.gray.opacity(0.3)
//                                                                .overlay(
//                                                                    ProgressView()
//                                                                )
//                                                        }
//                                                        .frame(width: 100, height: 100)
//                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
//                                                    }
//                                                }
//                                            }
//                                            .padding(.horizontal)
//                                        }
//                                    }
//
//                    .padding()
//                                
//                    .padding()
//                    Spacer()
//                    
//                    // Logout Button
//                    Button(action: {
//                        authViewModel.logout()
//                    }) {
//                        Text("Logout")
//                            .font(.headline)
//                            .foregroundColor(.white)
//                            .frame(minWidth: 40, maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
//                            .background(Color.accentColor)
//                            .cornerRadius(10)
//                            .padding()
//                    }
//                }
//                .navigationTitle("Profile")
//                .navigationBarItems(trailing: NavigationLink(destination: EditProfileView()) {
//                    Image(systemName: "pencil")
//                        .font(.system(size: 20)) // Customize size of the pencil icon
//                })
//            }
//            .onAppear {
//                Task {
//                    await viewModel.loadProfile() // Fetch user details when the view appears
//                }
//            }
//        }
//    }
//}
//
//struct PostDetailView: View {
//    var postId: Int // Use the post ID or any unique identifier for the post
//    
//    var body: some View {
//        VStack {
//            Text("Post \(postId)") // Placeholder for the actual post content
//                .font(.largeTitle)
//            // Display more post details here as needed
//        }
//        .navigationTitle("Post Detail")
//    }
//}
//
//#Preview {
//    ProfileView()
//        .environmentObject(AuthViewModel()) // Ensure the AuthViewModel is passed to the view
//}
//


import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ProfileHeaderView(
                        name: viewModel.name,
                        username: viewModel.username,
                        errorMessage: viewModel.errorMessage
                    )
                    .padding()

                    if viewModel.isLoading {
                        ProgressView("Loading posts...")
                            .padding()
                    } else if viewModel.posts.isEmpty {
                        Text("No posts yet.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        PostGridView(posts: viewModel.posts, columns: columns)
                            .padding(.horizontal)
                    }

                    LogoutButton {
                        authViewModel.logout()
                    }
                }
                .navigationTitle("Profile")
                .navigationBarItems(trailing: NavigationLink(destination: EditProfileView()) {
                    Image(systemName: "pencil")
                        .font(.system(size: 20))
                })
            }
            .onAppear {
                Task {
                    await viewModel.loadProfile()
                    //await viewModel.loadProfilePosts()
                }
                
            }
        }
    }
}

// MARK: - Profile Header
struct ProfileHeaderView: View {
    let name: String
    let username: String
    let errorMessage: String?
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 100))
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text(name)
                    .font(.headline)
                Text("@\(username)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Post Grid View
struct PostGridView: View {
    let posts: [Post]
    let columns: [GridItem]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(posts, id: \._id) { post in
                NavigationLink(destination: PostDetailView(postId: post._id)) {
                    // Placeholder grey box
                    Color.gray
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}


// MARK: - Logout Button
struct LogoutButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Logout")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Color.accentColor)
                .cornerRadius(10)
                .padding()
        }
    }
}

// MARK: - Post Detail View
struct PostDetailView: View {
    var postId: String // Updated to use String for MongoDB ObjectId compatibility
    
    var body: some View {
        VStack {
            Text("Post ID: \(postId)") // Placeholder for actual post details
                .font(.largeTitle)
        }
        .navigationTitle("Post Detail")
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}

