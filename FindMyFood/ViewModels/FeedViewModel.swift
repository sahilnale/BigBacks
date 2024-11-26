import Foundation

class FeedViewModel: ObservableObject {
    @Published var feed: [Post] = [] // Stores the feed data
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    func fetchFeed(for userId: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let posts = try await NetworkManager.shared.userFeed(userId: userId)
                DispatchQueue.main.async {
                    self.feed = posts
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
