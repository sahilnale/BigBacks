import SwiftUI

struct RestaurantCard: View {
    @State var post: Post
    @State private var isLiked: Bool = false
    @State private var likeCount: Int = 0
    @State private var isExpanded: Bool = false // Tracks if the description is expanded
    @State private var newCommentText: String = ""
    @State private var showComments: Bool = false
<<<<<<< Updated upstream
    
=======
    var userName: String

>>>>>>> Stashed changes
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Dynamic image from post.imageUrl
            AsyncImage(url: URL(string: post.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 300, height: 200)
                    .clipped()
            } placeholder: {
                Color.gray.frame(width: 300, height: 200)
            }
<<<<<<< Updated upstream
            
=======

            Text("@\(userName)")
                .font(.subheadline.bold())
                .foregroundColor(.accentColor)
                .padding(.leading)

>>>>>>> Stashed changes
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.accentColor)
                        Text(post.restaurantName)
                            .font(.headline)
                            .foregroundColor(Color.primary)
                    }

                    Text(post.review)
                        .font(.subheadline)
                        .foregroundColor(Color.secondary)
                        .lineLimit(isExpanded ? nil : 2)
                        .onTapGesture {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(post.starRating)")
                            .font(.subheadline)
                            .foregroundColor(Color.primary)
                    }

                    Button(action: {
                        // Provide immediate feedback
                        isLiked.toggle()
                        likeCount += isLiked ? 1 : -1

                        // Call the backend to persist the state
                        NetworkManager.shared.toggleLike(postId: post.id, currentLikeCount: likeCount, isLiked: isLiked) { newLikeCount, newIsLiked in
                            // Sync state with backend in case of conflict
                            DispatchQueue.main.async {
                                self.likeCount = newLikeCount
                                self.isLiked = newIsLiked
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .red : .gray)
                                .scaleEffect(isLiked ? 1.2 : 1.0) // Add scaling animation
                                .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.5), value: isLiked)

                            Text("\(likeCount) likes")
                                .font(.subheadline)
                        }
                    }
                    .buttonStyle(PlainButtonStyle()) // Ensure no additional styles
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Button(action: {
                withAnimation {
                    showComments.toggle()
                }
            }) {
                HStack {
                    Text("Comments (\(post.comments.count))")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.leading)
            .padding(.bottom)

            if showComments {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(post.comments, id: \ .self) { comment in
                        Text("• \(comment)")
                            .font(.body)
                            .padding(.vertical, 2)
                    }

                    HStack {
                        TextField("Add a comment...", text: $newCommentText)
                            .textFieldStyle(DefaultTextFieldStyle())

                        Button(action: {
                            guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                            // Add the comment locally
                            post.comments.append(newCommentText)
                            newCommentText = ""

                            // Optionally, persist the comment to the backend here
                        }) {
                            Text("Post")
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.primary.opacity(0.1), radius: 5)
        .padding(.horizontal)
        .onAppear {
            // Load initial like count and liked status
            self.likeCount = post.likes
            self.isLiked = post.likedBy.contains(AuthManager.shared.userId ?? "")
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



