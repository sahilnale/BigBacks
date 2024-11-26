
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
                NavigationLink(destination: PostDetailView(post: post)) {
                    AsyncImage(url: URL(string: post.imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView() // Show a loading indicator while the image loads
                                .frame(width: 100, height: 100)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .clipped()
                        case .failure:
                            Color.red // Display a red box if the image fails to load
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        @unknown default:
                            EmptyView()
                        }
                    }
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
    var post: Post // Pass the entire `Post` object
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Post Image
                AsyncImage(url: URL(string: post.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView() // Show loading spinner
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .background(Color.gray.opacity(0.3))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .clipped()
                    case .failure:
                        Text("Failed to load image")
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .background(Color.red.opacity(0.3))
                    @unknown default:
                        EmptyView()
                    }
                }

                // Restaurant Name
                Text(post.restaurantName)
                    .font(.title)
                    .fontWeight(.bold)
                
                // Location
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                    Text(post.location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Star Rating
                HStack {
                    ForEach(0..<5) { star in
                        Image(systemName: star < post.starRating ? "star.fill" : "star")
                            .foregroundColor(star < post.starRating ? .yellow : .gray)
                    }
                }
                
                // Review
                Text("Review")
                    .font(.headline)
                Text(post.review)
                    .font(.body)
                    .foregroundColor(.secondary)

                // Likes
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("\(post.likes) likes")
                        .font(.subheadline)
                }
                
                // Comments
                if !post.comments.isEmpty {
                    Text("Comments")
                        .font(.headline)
                    
                    ForEach(post.comments, id: \.self) { comment in
                        Text("• \(comment)")
                            .font(.body)
                            .padding(.vertical, 2)
                    }
                } else {
                    Text("No comments yet.")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
        .navigationTitle("Post Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}


// MARK: - Preview
#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}

