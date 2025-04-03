import SwiftUI
import FirebaseAuth

struct Comment: Encodable, Decodable, Identifiable, Hashable {
    let id: String
    let commentId: String
    let userId: String
    let profilePhotoUrl: String
    let text: String
    let timestamp: Date
}

struct RestaurantCard: View {
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @State var post: Post
    @State private var commenterUsernames: [String: String] = [:]
    @State private var isLiked: Bool = false
    @State private var likeCount: Int = 0
    @State private var isExpanded: Bool = false
    @State private var newCommentText: String = ""
    @State private var showComments: Bool = false
    @State private var isWishlisted: Bool = false
    @State private var selectedImageIndex = 0

    var userName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image carousel
            NavigationLink(value: post) {
                if !post.imageUrls.isEmpty {
                    TabView(selection: $selectedImageIndex) {
                        ForEach(Array(post.imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 360, height: 350)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .clipped()
                            } placeholder: {
                                Color.gray
                                    .frame(width: 360, height: 350)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: post.imageUrls.count > 1 ? .automatic : .never))
                    .frame(width: 360, height: 350)
                } else {
                    Color.gray.frame(width: 360, height: 350)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .overlay(Text("No Image").foregroundColor(.white).font(.headline))
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Username
            HStack {
                NavigationLink(value: post.userId) {
                    Text("@\(userName)")
                        .font(.subheadline.bold())
                        .foregroundColor(.customOrange)
                        .padding(.leading)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Restaurant name + rating
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.customOrange)

                Text(post.restaurantName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color.primary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(post.starRating)")
                        .font(.subheadline)
                        .foregroundColor(Color.primary)
                }
            }
            .padding(.horizontal)

            // Review
            Text(post.review)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(Color.secondary)
                .lineLimit(isExpanded ? nil : 2)
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

            // Likes + Bookmark row
            HStack {
                Spacer()

                // Likes
                Button(action: {
                    Task {
                        do {
                            let result = try await AuthViewModel.shared.toggleLike(
                                postId: post.id,
                                userId: Auth.auth().currentUser?.uid ?? "",
                                isCurrentlyLiked: isLiked
                            )
                            await MainActor.run {
                                self.likeCount = result.newLikeCount
                                self.isLiked = result.isLiked
                            }
                        } catch {
                            print("Failed to toggle like: \(error)")
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                        Text("\(likeCount)")
                            .foregroundColor(.primary)
                    }
                }

                // Bookmark
                Button(action: {
                    Task {
                        do {
                            let userId = Auth.auth().currentUser?.uid ?? ""
                            let newStatus = try await AuthViewModel.shared.toggleWishlist(
                                postId: post.id,
                                userId: userId
                            )
                            await MainActor.run {
                                self.isWishlisted = newStatus
                            }
                        } catch {
                            print("Failed to update wishlist: \(error)")
                        }
                    }
                }) {
                    Image(systemName: isWishlisted ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isWishlisted ? .accentColor : .gray)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)

            // Toggle show/hide comments
            Button(action: {
                withAnimation {
                    showComments.toggle()
                }
            }) {
                HStack {
                    Spacer()
                    Text(
                        showComments
                        ? "Hide Comments"
                        : (post.comments.isEmpty ? "No Comments" : "Show Comments (\(post.comments.count))")
                    )
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Image(systemName: showComments ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                    Spacer()
                }
            }
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 12)

            // Comments Section
            if showComments {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(post.comments) { comment in
                        HStack(alignment: .top) {
                            AsyncImage(url: URL(string: comment.profilePhotoUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 25, height: 25)
                                    .clipShape(Circle())
                                    .padding(.leading)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 25, height: 25)
                                    .padding(.leading)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("@\(commenterUsernames[comment.userId] ?? "Loading...")")
                                    .foregroundColor(Color.accentColor)
                                    .font(.subheadline)
                                    .onAppear {
                                        fetchUsername(for: comment.userId)
                                    }

                                Text(comment.text)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)

                                Text("\(timeAgo(from: comment.timestamp))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    // Comment input
                    HStack {
                        TextField("Add a comment...", text: $newCommentText)
                            .textFieldStyle(DefaultTextFieldStyle())

                        Button(action: {
                            guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                            Task {
                                do {
                                    let comment = Comment(
                                        id: UUID().uuidString,
                                        commentId: UUID().uuidString,
                                        userId: Auth.auth().currentUser?.uid ?? "",
                                        profilePhotoUrl: AuthViewModel.shared.currentUser?.profilePicture ?? "placeholder",
                                        text: newCommentText.trimmingCharacters(in: .whitespacesAndNewlines),
                                        timestamp: Date()
                                    )

                                    let newComment = try await AuthViewModel.shared.addComment(to: post.id, comment: comment)

                                    await MainActor.run {
                                        post.comments.append(newComment)
                                        newCommentText = ""
                                    }
                                } catch {
                                    print("Failed to add comment: \(error)")
                                }
                            }
                        }) {
                            Text("Post")
                                .font(.subheadline)
                                .foregroundColor(.customOrange)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.primary.opacity(0.1), radius: 5)
        .padding(.horizontal)
        .onAppear {
            Task {
                let userId = Auth.auth().currentUser?.uid ?? ""

                do {
                    let updatedPost = try await AuthViewModel.shared.fetchPostDetails(postId: post.id)
                    await MainActor.run {
                        self.post = updatedPost
                        self.likeCount = updatedPost.likes
                        self.isLiked = updatedPost.likedBy.contains(userId)
                    }
                    self.isWishlisted = try await AuthViewModel.shared.isPostWishlisted(postId: post.id, userId: userId)
                } catch {
                    print("Failed to fetch post details: \(error)")
                }
            }
        }
    }

    private func fetchUsername(for userId: String) {
        if commenterUsernames[userId] != nil { return }

        Task {
            do {
                if let user = try await authViewModel.getUserById(friendId: userId) {
                    await MainActor.run {
                        commenterUsernames[userId] = user.username
                    }
                } else {
                    await MainActor.run {
                        commenterUsernames[userId] = "Unknown"
                    }
                }
            } catch {
                print("Error fetching username for \(userId): \(error)")
                await MainActor.run {
                    commenterUsernames[userId] = "Error"
                }
            }
        }
    }

    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day {
            if daysAgo < 7 {
                return daysAgo == 1 ? "1 day ago" : "\(daysAgo) days ago"
            }
            let weeksAgo = daysAgo / 7
            return weeksAgo == 1 ? "1 week ago" : "\(weeksAgo) weeks ago"
        }

        return "Just now"
    }
}
