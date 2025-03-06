import SwiftUI

struct PostView: View {
    @ObservedObject private var authViewModel = AuthViewModel.shared
        @State var post: Post // Ensures UI updates
        @Environment(\.dismiss) var dismiss
        @State private var isDeleting = false
        @State private var showAlert = false
        @State private var commenterUsernames: [String: String] = [:]
        @State private var errorMessage: String?
        @State private var currentImageIndex = 0 // To track the currently displayed image

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !post.imageUrls.isEmpty {
                        // Carousel for multiple images
                        TabView(selection: $currentImageIndex) {
                            ForEach(post.imageUrls.indices, id: \.self) { index in
                                AsyncImage(url: URL(string: post.imageUrls[index])) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
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
                                .tag(index) // Tag each image with its index
                            }
                        }
                        .tabViewStyle(PageTabViewStyle()) // Adds page dots at the bottom
                        .frame(height: 300) // Set the height for the image carousel
                    }

                Text(post.restaurantName)
                    .font(.title)
                    .fontWeight(.bold)

                HStack {
                    Image(systemName: "mappin.and.ellipse")
                    Text(post.location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                HStack {
                    ForEach(0..<5) { star in
                        Image(systemName: star < post.starRating ? "star.fill" : "star")
                            .foregroundColor(star < post.starRating ? .yellow : .gray)
                    }
                }

                Text("Review")
                    .font(.headline)
                Text(post.review)
                    .font(.body)
                    .foregroundColor(.secondary)

                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("\(post.likes) likes")
                        .font(.subheadline)
                }

                // Fetch and display comments in a scrollable section
                if !post.comments.isEmpty {
                    Text("Comments")
                        .font(.headline)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(post.comments, id: \.self) { comment in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("@\(commenterUsernames[comment.userId] ?? "Loading...")")
                                        .foregroundColor(Color.accentColor)
                                        .font(.subheadline)
                                        .onAppear {
                                            fetchUsername(for: comment.userId)
                                        }

                                    Text(comment.text)
                                        .font(.body)
                                        .padding(.vertical, 2)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .frame(maxHeight: 300) // Set max height for the scrollable area
                    }
                } else {
                    Text("No comments yet.")
                        .font(.body)
                        .foregroundColor(.gray)
                }

                // Show delete button if user owns the post
                if authViewModel.currentUser?.id == post.userId {
                    HStack {
                        Spacer()
                        Button(action: {
                            showAlert = true
                        }) {
                            Text("Delete Post")
                                .foregroundColor(.customOrange)
                        }
                        Spacer()
                    }
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Post Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Post", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await deletePost()
                }
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
        .onAppear {
            Task {
                do {
                    let updatedPost = try await AuthViewModel.shared.fetchPostDetails(postId: post.id)
                    await MainActor.run {
                        self.post.comments = updatedPost.comments
                    }
                } catch {
                    print("Failed to fetch updated post details: \(error)")
                }
            }
        }
    }

    private func fetchUsername(for userId: String) {
        // Avoid fetching if already cached
        if commenterUsernames[userId] != nil {
            return
        }

        Task {
            do {
                if let user = try await authViewModel.getUserById(friendId: userId) {
                    await MainActor.run {
                        commenterUsernames[userId] = user.username
                    }
                } else {
                    await MainActor.run {
                        commenterUsernames[userId] = "Unknown User"
                    }
                }
            } catch {
                print("Failed to fetch username for userId \(userId): \(error)")
                await MainActor.run {
                    commenterUsernames[userId] = "Error"
                }
            }
        }
    }

    private func deletePost() async {
        isDeleting = true
        do {
            try await authViewModel.deletePost(postId: post.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isDeleting = false
    }
}

