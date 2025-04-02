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

    @State private var selectedImageIndex = 0
// ✅ Per-user wishlisting state
    var userName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink(value: post) {
            
            // 1) The main image and profile link
                if !post.imageUrls.isEmpty {
                    TabView(selection: $selectedImageIndex) {
                        ForEach(Array(post.imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 360, height: 350)
                                    .contentShape(Rectangle())
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
                    .clipShape(RoundedRectangle(cornerRadius: 15))
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
//            .navigationDestination(isPresented: $navigateToPost) {
//                            PostView(post: post)
//                        }

            
            // 2) Username link
//            HStack {
//                Button(action: {
//                    navigateToProfile = true
//                }) {
//                    Text("@\(userName)")
//                        .font(.subheadline.bold())
//                        .foregroundColor(.customOrange)
//                        .padding(.leading)
//                }
//                .buttonStyle(PlainButtonStyle())
//            }
//            .navigationDestination(isPresented: $navigateToProfile) {
//                           FriendProfileView(userId: post.userId)
//                       }

            
            HStack {
                NavigationLink(value: post.userId) {
                    Text("@\(userName)")
                        .font(.subheadline.bold())
                        .foregroundColor(.customOrange)
                        .padding(.leading)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
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
                        if showComments {
                            refreshComments()
                        }
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
                                       Task {
                                           let userId = Auth.auth().currentUser?.uid ?? ""

                                           self.likeCount = post.likes // ✅ This will set it from the post
                                           self.isLiked = post.likedBy.contains(userId) // ✅ Check if the user has liked it already

                                           do {
                                               self.isWishlisted = try await AuthViewModel.shared.isPostWishlisted(postId: post.id, userId: userId)
                                           } catch {
                                               print("Failed to fetch wishlist status: \(error)")
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
                                      // Instead of just appending locally, refresh all comments
                                      refreshComments()
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
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
            } else {
                Button(action: {
                    withAnimation {
                        showComments.toggle()
                        if showComments {
                            refreshComments()
                        }
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
    
    // New function to refresh comments
    private func refreshComments() {
        Task {
            do {
                // Fetch the latest post data with updated comments
                if let updatedPost = try await AuthViewModel.shared.fetchPostDetails(postId: post.id) {
                    await MainActor.run {
                        self.post.comments = updatedPost.comments
                    }
                }
            } catch {
                print("Failed to refresh comments: \(error)")
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

