import SwiftUI

struct FeedView: View {
    @State private var posts: [Post] = [] // The array to hold the fetched posts
    @State private var isLoading: Bool = true // To track loading state
    @State private var errorMessage: String? = nil // To track any error

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                // Title at the top
                Text("Feed")
                    .font(.system(size: 34, weight: .bold)) // Apple-like title design
                    .foregroundColor(.primary)
                    .padding(.top)
                    .padding(.leading)

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
                    List(posts) { post in
                        RestaurantCard(post: post) // Use a properly designed `RestaurantCard`
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .padding(.horizontal)
            .background(Color(UIColor.systemBackground)) // Use system background color
            .onAppear {
                loadFeed()
            }
        }
    }

    private func loadFeed() {
        Task {
            do {
                let userId = AuthManager.shared.userId ?? "" // Replace with actual user ID
                let fetchedPosts = try await NetworkManager.shared.userFeed(userId: userId)
                DispatchQueue.main.async {
                    self.posts = fetchedPosts
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
