import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

struct FeedView: View {
    @State private var selectedTab: Tab = .feed
    @State private var posts: [(post: Post, userName: String)] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var sortOption: SortOption = .mostRecent {
        didSet {
            if sortOption == .distance {
                fetchUserLocation() // Ensure location is fetched when sorting by distance
            } else {
                loadFeed()
            }
        }
    }
    @State private var userLocation: CLLocation? = nil
    
    enum Tab: String, CaseIterable {
        case feed = "Feed"
        case wishlist = "Wishlist"
        case search = "Search"
    }
    
    enum SortOption: String, CaseIterable {
        case mostRecent = "Most Recent"
        case distance = "Distance"
        case rating = "Rating"
        case popularity = "Popularity"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header - adding more padding for better visibility
                    HStack {
                        Image("transparentLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .padding(.leading, 10)
                        Text("FindMyFood")
                            .font(.system(.largeTitle, design: .serif))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.top, 40) // Increased top padding
                    .padding(.bottom, 10) // Added bottom padding
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor.opacity(0.8))
                    
                    // Tab Selector - Adding padding and zIndex to ensure it receives touches
                    Picker("Select", selection: $selectedTab) {
                        ForEach(Tab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.top, 12) // Increased padding
                    .padding(.horizontal)
                    .padding(.bottom, 8) // Added bottom padding
                    .background(Color.white) // White background
                    .zIndex(2) // Higher zIndex to ensure it receives taps
                    
                    // Sort Options - Adding padding and zIndex to ensure it receives touches
                    HStack {
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: { sortOption = option }) {
                                    Text(option.rawValue)
                                }
                            }
                        } label: {
                            HStack {
                                Text(sortOption.rawValue)
                                    .font(.headline)
                                    .foregroundColor(.customOrange)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.customOrange)
                            }
                            .padding()
                        }
                        Spacer()
                    }
                    .padding(.leading)
                    .padding(.bottom, 8) // Added bottom padding
                    .background(Color.white) // White background
                    .zIndex(1) // Higher zIndex to ensure it receives taps
                    
                    // Spacer to separate controls from content
                    Color.gray.opacity(0.1)
                        .frame(height: 4)
                    
                    // Content based on selected tab
                    VStack(spacing: 0) {
                        switch selectedTab {
                        case .feed:
                            feedContentView()
                        case .wishlist:
                            WishlistView()
                        case .search:
                            SearchView()
                        }
                    }
                    .background(Color.white) // Ensure consistent background
                    .zIndex(0) // Lower zIndex for content
                }
            }
            .edgesIgnoringSafeArea(.top) // Extend to top of screen
            .onAppear {
                if posts.isEmpty {
                    loadFeed()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensure proper navigation style
    }
    
    private func fetchUserLocation() {
        LocationManager.shared.startUpdatingLocation { location in
            self.userLocation = location
            loadFeed()
        }
    }
    
    private func feedContentView() -> some View {
        VStack(spacing: 0) {
            if isLoading && posts.isEmpty {
                ProgressView("Loading Feed...")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else if posts.isEmpty {
                Text("No feed yet")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
                    .padding()
            } else {
                // Use LazyVStack instead of List for better integration with ScrollView
                LazyVStack(spacing: 0) {
                    ForEach(posts, id: \.post._id) { (post, userName) in
                        RestaurantCard(post: post, userName: userName)
                            .padding(.vertical, 4)
                            .contentShape(Rectangle()) // Ensure tap area is limited to this view
                    }
                }
                .padding(.top, 12) // Increased top padding
            }
        }
    }
    
    private func loadFeed() {
        // Keeping your existing loadFeed implementation
        isLoading = true
        errorMessage = nil
        let db = Firestore.firestore()
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            isLoading = false
            return
        }
        
        db.collection("users").document(currentUserId).getDocument { userDoc, error in
            guard let userData = userDoc?.data(),
                  let friendsList = userData["friends"] as? [String], !friendsList.isEmpty else {
                self.posts = []
                self.isLoading = false
                return
            }
            
            db.collection("posts")
                .whereField("userId", in: friendsList)
                .getDocuments { postsQuery, error in
                    guard let postDocuments = postsQuery?.documents else {
                        self.errorMessage = "Failed to fetch posts."
                        self.isLoading = false
                        return
                    }
                    
                    var feed: [(post: Post, userName: String)] = []
                    let group = DispatchGroup()
                    
                    for postDoc in postDocuments {
                        group.enter()
                        let postData = postDoc.data()
                        
                        guard let userId = postData["userId"] as? String else {
                            group.leave() // ✅ Always leave if userId is missing
                            continue
                        }
                        
                        db.collection("users").document(userId).getDocument { userDoc, error in
                            defer { group.leave() } // ✅ Ensures `leave()` is always called
                            
                            guard let userData = userDoc?.data(),
                                  let username = userData["username"] as? String else { return }
                            
                            let likes = postData["likes"] as? Int ?? 0
                            let timestamp = postData["timestamp"] as? Timestamp ?? Timestamp(date: Date())
                            let imageUrls = postData["imageUrls"] as? [String] ?? []
                            let locationString = postData["location"] as? String ?? "0.0,0.0"
                            
                            let post = Post(
                                _id: postDoc.documentID,
                                userId: userId,
                                imageUrls: imageUrls,
                                timestamp: timestamp,
                                review: postData["review"] as? String ?? "",
                                location: locationString,
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
                        feed.sort {
                            switch sortOption {
                            case .mostRecent:
                                return $0.post.timestamp.dateValue() > $1.post.timestamp.dateValue()
                            case .distance:
                                guard let userLocation = userLocation else {
                                    print("❌ No user location available!") // Debugging
                                    return false
                                }
                                let coordinates1 = $0.post.location.split(separator: ",").compactMap { Double($0) }
                                let coordinates2 = $1.post.location.split(separator: ",").compactMap { Double($0) }
                                
                                if coordinates1.count == 2, coordinates2.count == 2 {
                                    let location1 = CLLocation(latitude: coordinates1[0], longitude: coordinates1[1])
                                    let location2 = CLLocation(latitude: coordinates2[0], longitude: coordinates2[1])
                                    return location1.distance(from: userLocation) < location2.distance(from: userLocation)
                                }
                                return false
                            case .rating:
                                return $0.post.starRating > $1.post.starRating
                            case .popularity:
                                return $0.post.likes > $1.post.likes
                            }
                        }
                        self.posts = feed
                        self.isLoading = false
                    }
                }
        }
    }
}

struct WishlistView: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("Wishlist Page")
                .font(.title)
                .foregroundColor(.gray)
                .padding()
            
            Spacer()
        }
        .frame(minHeight: 300) // Give it a minimum height to prevent collapsing
    }
}

struct SearchView: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("AI Search Page")
                .font(.title)
                .foregroundColor(.gray)
                .padding()
            
            Spacer()
        }
        .frame(minHeight: 300) // Give it a minimum height to prevent collapsing
    }
}
