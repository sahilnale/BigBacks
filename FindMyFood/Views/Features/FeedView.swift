import SwiftUI

struct FeedView: View {
    @State private var posts: [(post: Post, userName: String)] = [] // The array to hold the fetched posts
    @State private var isLoading: Bool = true // To track loading state
    @State private var errorMessage: String? = nil // To track any error

    var body: some View {
        NavigationView {
            ZStack {
            VStack(alignment: .leading) {

                // Main Content
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
                    List(posts, id: \.post.id) { (post, userName) in
                            RestaurantCard(post: post, userName: userName)
                        }
                    .listStyle(PlainListStyle())
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
        Task {
            do {
                let userId = AuthManager.shared.userId ?? "" // Replace with actual user ID
                let fetchedPosts = try await NetworkManager.shared.userFeed(userId: userId)
                
                var postsWithUserNames: [(post: Post, userName: String)] = []
                    for post in fetchedPosts {
                        if let user = try? await NetworkManager.shared.getUserById(userId: post.userId) {
                            postsWithUserNames.append((post: post, userName: user.username))
                        } else {
                            postsWithUserNames.append((post: post, userName: "Unknown"))
                        }
                    }
                
                DispatchQueue.main.async {
                    self.posts = postsWithUserNames
                    self.isLoading = false
                }
            } catch {
                print("Error fetching feed: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
