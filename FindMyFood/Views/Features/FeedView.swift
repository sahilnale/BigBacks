import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FeedView: View {
    @State private var posts: [(post: Post, userName: String)] = [] // The array to hold the fetched posts
    @State private var isLoading: Bool = true // To track loading state
    @State private var errorMessage: String? = nil // To track any error

    var body: some View {
        NavigationView {
            ZStack {
                VStack(alignment: .leading) {
                    if isLoading {
                        ProgressView("Loading Feed...")
                            .padding()
                    } else if let errorMessage = errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                    } else if posts.isEmpty {
                        VStack {
                            Spacer()
                            Text("No feed yet")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    } else {
                        List(posts, id: \.post._id) { (post, userName) in
                            RestaurantCard(post: post, userName: userName)
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .padding(.top, 10)
            .padding(.horizontal)
            .background(Color(UIColor.systemBackground)) // Use system background color
            .onAppear {
                loadFeed()
            }
//            VStack {
//                Text("Feed")
//                    .font(.system(.largeTitle, design: .serif))
//                    .fontWeight(.bold)
//                    .padding(.top, 60)
//                    .padding(.bottom, 20)
//                    .frame(maxWidth: .infinity, maxHeight: 90)
//                    .background(Color.customOrange.opacity(0.8))
//                    .foregroundColor(.white)
//                Spacer() // Pushes the main content below
//            }
//            .ignoresSafeArea(edges: .top) // Makes the text extend to the top edge
                
            VStack {
                HStack {
                    Image("transparentLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 65, height: 65) // Adjust the size of the image
                        .padding(.leading, 10) // Add padding to align properly
                    Text("FindMyFood")
                        .font(.system(.largeTitle, design: .serif))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                       // .padding(.leading, 5) // Add padding between image and text
                    Spacer()
                }
                .padding(.top, 65)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, maxHeight: 95)
                .background(Color.customOrange.opacity(0.8))
                .ignoresSafeArea(edges: .top) // Makes the content extend to the top edge
                Spacer() // Pushes the main content below
                }
            }
        }
    }

    private func loadFeed() {
        // Start loading
        isLoading = true
        errorMessage = nil

        let db = Firestore.firestore()

        // Step 1: Fetch current user's ID
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            isLoading = false
            return
        }

        // Step 2: Fetch user's friends list
        db.collection("users").document(currentUserId).getDocument { userDoc, error in
            guard error == nil, let userData = userDoc?.data(),
                  let friendsList = userData["friends"] as? [String], !friendsList.isEmpty else {
                DispatchQueue.main.async {
                    self.posts = [] // Empty posts indicate no feed
                    self.isLoading = false
                }
                return
            }

            // Step 3: Fetch posts for all friends
            db.collection("posts")
                .whereField("userId", in: friendsList)
                .getDocuments { postsQuery, error in
                    guard error == nil, let postDocuments = postsQuery?.documents else {
                        DispatchQueue.main.async {
                            self.errorMessage = "Failed to fetch posts."
                            self.isLoading = false
                        }
                        return
                    }

                    var feed: [(post: Post, userName: String)] = []

                    let group = DispatchGroup()

                    for postDoc in postDocuments {
                        group.enter()

                        let postData = postDoc.data()

                        guard let userId = postData["userId"] as? String else {
                            group.leave()
                            continue
                        }

                        db.collection("users").document(userId).getDocument { userDoc, error in
                            defer { group.leave() }

                            guard error == nil, let userData = userDoc?.data(),
                                  let username = userData["username"] as? String else {
                                return
                            }

                            // Parse post data
                            let likes = postData["likes"] as? Int ?? 0 // Fallback to 0 if missing
                            print("Fetched likes for post \(postDoc.documentID): \(likes)") // Debugging print

                            let timestamp = (postData["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                            let post = Post(
                                _id: postDoc.documentID,
                                userId: userId,
                                imageUrl: postData["imageUrl"] as? String ?? "",
                                timestamp: ISO8601DateFormatter().string(from: timestamp),
                                review: postData["review"] as? String ?? "",
                                location: postData["location"] as? String ?? "",
                                restaurantName: postData["restaurantName"] as? String ?? "",
                                likes: likes,
                                likedBy: postData["likedBy"] as? [String] ?? [],
                                starRating: postData["starRating"] as? Int ?? 0,
                                comments: []
                            )

                            feed.append((post: post, userName: username))
                        }
                    }

                    group.notify(queue: .main) {
                        // Sort feed by timestamp
                        feed.sort { postA, postB in
                            let formatter = ISO8601DateFormatter()
                            let dateA = formatter.date(from: postA.post.timestamp) ?? Date.distantPast
                            let dateB = formatter.date(from: postB.post.timestamp) ?? Date.distantPast
                            return dateA > dateB
                        }

                        self.posts = feed
                        self.isLoading = false
                    }
                }
        }
    }

}
