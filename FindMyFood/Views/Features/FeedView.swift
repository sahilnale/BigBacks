import SwiftUI

import SwiftUI

struct FeedView: View {
    @State private var posts: [Post] = [] // The array to hold the fetched posts
    @State private var isLoading: Bool = true // To track loading state
    @State private var errorMessage: String? = nil // To track any error

    var body: some View {
        NavigationView {
            if isLoading {
                ProgressView("Loading Feed...")
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                List(posts) { post in
                    RestaurantCard(post: post) // Use a properly designed `RestaurantCard`
                }
                .navigationTitle("Feed")
            }
        }
        .onAppear {
            loadFeed()
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

