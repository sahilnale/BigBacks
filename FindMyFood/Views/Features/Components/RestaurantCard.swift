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
    @State private var navigateToProfile = false
    @State private var navigateToPost = false
    @State private var isWishlisted: Bool = false
    @State private var commentText = ""
// ✅ Per-user wishlisting state
    var userName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            // 1) The main image and profile link
            Button(action: {
                navigateToPost = true
            }) {
                if let firstImageUrl = post.imageUrls.first, !firstImageUrl.isEmpty {
                    AsyncImage(url: URL(string: firstImageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 360, height: 350)
                            .contentShape(Rectangle())
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .clipped()
                    } placeholder: {
                        Color.gray.frame(width: 360, height: 350)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                } else {
                    Color.gray.frame(width: 360, height: 350)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .overlay(
                            Text("No Image")
                                .foregroundColor(.white)
                                .font(.headline)
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())
            .background(
                NavigationLink(
                    destination: PostView(post: post),
                    isActive: $navigateToPost
                ) {
                    EmptyView()
                }
                .hidden()
            )
            
            // 2) Username link
            HStack {
                Button(action: {
                    navigateToProfile = true
                }) {
                    Text("@\(userName)")
                        .font(.subheadline.bold())
                        .foregroundColor(.customOrange)
                        .padding(.leading)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(
                NavigationLink(
                    destination: FriendProfileView(userId: post.userId),
                    isActive: $navigateToProfile
                ) {
                    EmptyView()
                }
                .hidden()
            )

            // 3) Restaurant name + star rating on the same row
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.customOrange)
                
                Text(post.restaurantName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color.primary)
                
                Spacer()
                
                // Star rating
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(post.starRating)")
                        .font(.subheadline)
                        .foregroundColor(Color.primary)
                }
            }
            .padding(.horizontal)

            // 4) Review text
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

            // 5) Comments, Likes, and Bookmark on one row
            HStack {
                // Comments button (left)
                Button(action: {
                    withAnimation {
                        showComments.toggle()
                    }
                }) {
                    Text("Comments (\(post.comments.count))")
                        .font(.subheadline)
                        .foregroundColor(.customOrange)
                }

                Spacer()
                
                // Likes button
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
                    HStack(spacing: 4) {  // <-- Adjust spacing here (e.g., 2 or 4)
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                            .font(.subheadline)    // Ensure consistent font size
                            .scaleEffect(isLiked ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.5),
                                       value: isLiked)
                        
                        Text("\(likeCount)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Bookmark button
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
            .padding(.bottom)

            // 6) Show/hide comments section
            // Comments Section
            if showComments {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Comments")
                            .font(.headline)
                            .foregroundColor(.primary.opacity(0.8))
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                showComments.toggle()
                            }
                        }) {
                            Image(systemName: "chevron.up")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if post.comments.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "bubble.middle.bottom")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("No comments yet")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    } else {
                        ForEach(post.comments, id: \.self) { comment in
                            commentView(for: comment)
                        }
                    }
                    
                    // Comment input field
                    HStack {
                        TextField("Add a comment...", text: $commentText)
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(20)
                        
                        Button(action: {
                            // Add comment functionality
                        }) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
            } else {
                Button(action: {
                    withAnimation {
                        showComments.toggle()
                    }
                }) {
                    HStack {
                        Spacer()
                        Text("Show Comments")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.primary.opacity(0.1), radius: 5)
        .padding(.horizontal)
        .onAppear {
            Task {
                let userId = Auth.auth().currentUser?.uid ?? ""
                self.likeCount = post.likes
                self.isLiked = post.likedBy.contains(userId)
                do {
                    self.isWishlisted = try await AuthViewModel.shared
                        .isPostWishlisted(postId: post.id, userId: userId)
                } catch {
                    print("Failed to fetch wishlist status: \(error)")
                }
            }
        }
    }
    
    
    private func fetchUsername(for userId: String) {
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
    
    
    private func commentView(for comment: Comment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String((commenterUsernames[comment.userId] ?? "?").prefix(1)).uppercased())
                            .foregroundColor(.primary)
                            .font(.system(size: 16, weight: .bold))
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("@\(commenterUsernames[comment.userId] ?? "Loading...")")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Text(comment.text)
                        .font(.system(size: 15))
                        .lineSpacing(3)
                }
                .padding(.leading, 4)
                .onAppear {
                    fetchUsername(for: comment.userId)
                }
                
                Spacer()
            }
            
            Divider()
                .padding(.leading, 40)
        }
        .padding(.vertical, 6)
    }

}





func timeAgo(from date: Date) -> String {
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



