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
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 350, height: 350)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .clipped()
                    } placeholder: {
                        Color.gray.frame(width: 350, height: 350)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                } else {
                    Color.gray.frame(width: 350, height: 350)
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
            if showComments {
                VStack(alignment: .leading, spacing: 8) {
                    // ... your existing comment list code ...
                    // ... including the TextField for adding a comment ...
                }
                .padding(.bottom)
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











