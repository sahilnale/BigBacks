
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
    @State private var isExpanded: Bool = false // Tracks if the description is expanded
    @State private var newCommentText: String = ""
    @State private var showComments: Bool = false
    var userName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Dynamic image from post.imageUrl
            AsyncImage(url: URL(string: post.imageUrl)) { image in
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
            
            NavigationLink(destination: FriendProfileView(userId: post.userId)) {
                Text("@\(userName)")
                    .font(.subheadline.bold())
                    .foregroundColor(.customOrange)
                    .padding(.leading)
            }
            .buttonStyle(PlainButtonStyle()) // Removes the default button appearance
            .contentShape(Rectangle())       // Limits the tap area to the text

            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.customOrange)
                        Text(post.restaurantName)
                            //.font(.headline)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color.primary)
                    }
                    
                    Text(post.review)
                        //.font(.subheadline)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
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
                    
                    
                    
                    VStack {
                        Button(action: {
                            // Toggle the like/dislike functionality
                            Task {
                                do {
                                    // Persist the state with the backend
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
                            HStack {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .foregroundColor(isLiked ? .red : .gray)
                                    .scaleEffect(isLiked ? 1.2 : 1.0) // Scaling animation for like action
                                    .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.5), value: isLiked)
                                    
                                
                                Text("\(likeCount) likes")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                        .disabled(isLiked && !isLiked) // Disable like if already liked
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    
                    
    

                    
                    
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
                        .foregroundColor(.customOrange)
                }
            }
            .buttonStyle(PlainButtonStyle()) // Keeps button behavior simple
            .padding(.leading)
            .padding(.bottom)
            
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
                                    .frame(width: 25, height: 25) // Placeholder for missing profile photo
                                    .padding(.leading)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                // Display the fetched username or show a placeholder
                                Text("@\(commenterUsernames[comment.userId] ?? "Loading...")")
                                    .foregroundColor(Color.accentColor)
                                    .font(.subheadline)
                                    .onAppear {
                                        // Fetch the username if not already cached
                                        if commenterUsernames[comment.userId] == nil {
                                            Task {
                                                do {
                                                    if let commenter = try await AuthViewModel.shared.getUserById(friendId: comment.userId) {
                                                        await MainActor.run {
                                                            commenterUsernames[comment.userId] = commenter.username
                                                        }
                                                    } else {
                                                        await MainActor.run {
                                                            commenterUsernames[comment.userId] = "Unknown user"
                                                        }
                                                    }
                                                } catch {
                                                    print("Failed to fetch commenter: \(error)")
                                                    await MainActor.run {
                                                        commenterUsernames[comment.userId] = "Error"
                                                    }
                                                }
                                            }
                                        }
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

                                    print("Comment added successfully.")
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
                .padding(.bottom)
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.primary.opacity(0.1), radius: 5)
        .padding(.horizontal)
        //       .onAppear {
        //            likeCount = post.likes
        //            isLiked = post.likedBy.contains(AuthManager.shared.userId ?? "")
        
        //        }
        
        .onAppear {
            Task {
                do {
                    let updatedPost = try await AuthViewModel.shared.fetchPostDetails(postId: post.id)
                    await MainActor.run {
                        self.likeCount = updatedPost.likes
                        self.isLiked = updatedPost.likedBy.contains(Auth.auth().currentUser?.uid ?? "")
                        self.post.comments = updatedPost.comments
                    }
                } catch {
                    print("Failed to fetch post details: \(error)")
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











