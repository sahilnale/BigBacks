import Foundation

class FeedViewModel: ObservableObject {
    @Published var feed: [Post] = [] // Stores the feed data
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    
}
