import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

struct FeedView: View {
    @State private var selectedTab: Tab = .feed
    @State private var posts: [(post: Post, userName: String)] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var sortOption: SortOption = .mostRecent
    @State private var userLocation: CLLocation? = nil

    enum Tab: String, CaseIterable {
        case feed = "Feed"
        case wishlist = "Wishlist"
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
                    headerView()
                    
                    tabPicker()
                        .padding(.bottom, 12)
                    
                    if selectedTab == .feed {
                        sortMenu()
                            .padding(.bottom, 12)
                    }
                    
                    Color.gray.opacity(0.1)
                        .frame(height: 6)
                    
                    VStack(spacing: 0) {
                        switch selectedTab {
                        case .feed:
                            feedContentView()
                                .padding(.top, 12)
                        case .wishlist:
                            WishlistView()
                                .padding(.top, 12)
                        }
                    }
                    // Use system background so dark mode is supported.
                    .background(Color(.systemBackground))
                }
            }
            .edgesIgnoringSafeArea(.top)
            .onAppear {
                if posts.isEmpty { loadFeed() }
            }
            // Dynamic re-sorting when sortOption changes:
            .onChange(of: sortOption) { newOption in
                if newOption == .distance {
                    if let userLocation = userLocation {
                        self.posts.sort { (a, b) in
                            let coordsA = a.post.location.split(separator: ",").compactMap { Double($0) }
                            let coordsB = b.post.location.split(separator: ",").compactMap { Double($0) }
                            guard coordsA.count == 2, coordsB.count == 2 else { return false }
                            let locationA = CLLocation(latitude: coordsA[0], longitude: coordsA[1])
                            let locationB = CLLocation(latitude: coordsB[0], longitude: coordsB[1])
                            return locationA.distance(from: userLocation) < locationB.distance(from: userLocation)
                        }
                    } else {
                        fetchUserLocation()
                    }
                } else {
                    self.posts.sort { (a, b) in
                        switch newOption {
                        case .mostRecent:
                            return a.post.timestamp.dateValue() > b.post.timestamp.dateValue()
                        case .rating:
                            return a.post.starRating > b.post.starRating
                        case .popularity:
                            return a.post.likes > b.post.likes
                        default:
                            return true
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Header View
    private func headerView() -> some View {
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
        .padding(.top, 50)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(0.8))
    }

    // MARK: - Tab Picker
    private func tabPicker() -> some View {
        Picker("Select", selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.top, 12)
        .padding(.horizontal)
        .padding(.bottom, 8)
        // Use system background for dark mode
        .background(Color(.systemBackground))
    }

    // MARK: - Sort Menu
    private func sortMenu() -> some View {
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
        .padding(.bottom, 8)
        // Use system background for dark mode
        .background(Color(.systemBackground))
    }

    // MARK: - Fetch User Location
    private func fetchUserLocation() {
        LocationManager.shared.startUpdatingLocation { location in
            self.userLocation = location
            loadFeed()
        }
    }

    // MARK: - Feed Content
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
                LazyVStack(spacing: 0) {
                    ForEach(posts, id: \.post._id) { (post, userName) in
                        RestaurantCard(post: post, userName: userName)
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.top, 12)
            }
        }
    }

    // MARK: - Load Feed
    private func loadFeed() {
        isLoading = true
        errorMessage = nil
        let db = Firestore.firestore()

        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            isLoading = false
            return
        }

        db.collection("users").document(currentUserId).getDocument(source: .server) { userDoc, _ in
            guard let userData = userDoc?.data(),
                  let friendsList = userData["friends"] as? [String], !friendsList.isEmpty else {
                self.posts = []
                self.isLoading = false
                return
            }

            db.collection("posts")
                .whereField("userId", in: friendsList)
                .getDocuments(source: .server) { postsQuery, _ in
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
                            group.leave()
                            continue
                        }

                        db.collection("users").document(userId).getDocument(source: .server) { userDoc, _ in
                            defer { group.leave() }
                            guard let userData = userDoc?.data(),
                                  let username = userData["username"] as? String else { return }

                            let post = Post(
                                _id: postDoc.documentID,
                                userId: userId,
                                imageUrls: postData["imageUrls"] as? [String] ?? [],
                                timestamp: postData["timestamp"] as? Timestamp ?? Timestamp(date: Date()),
                                review: postData["review"] as? String ?? "",
                                location: postData["location"] as? String ?? "0.0,0.0",
                                restaurantName: postData["restaurantName"] as? String ?? "",
                                likes: postData["likes"] as? Int ?? 0,
                                likedBy: postData["likedBy"] as? [String] ?? [],
                                starRating: postData["starRating"] as? Int ?? 0,
                                comments: []
                            )

                            feed.append((post: post, userName: username))
                        }
                    }

                    group.notify(queue: .main) {
                        self.posts = feed.sorted { (a: (post: Post, userName: String), b: (post: Post, userName: String)) in
                            switch sortOption {
                            case .mostRecent:
                                return a.post.timestamp.dateValue() > b.post.timestamp.dateValue()
                            case .distance:
                                guard let userLocation = userLocation else { return false }
                                
                                let coordsA = a.post.location.split(separator: ",").compactMap { Double($0) }
                                let coordsB = b.post.location.split(separator: ",").compactMap { Double($0) }
                                
                                guard coordsA.count == 2, coordsB.count == 2 else { return false }
                                
                                let locationA = CLLocation(latitude: coordsA[0], longitude: coordsA[1])
                                let locationB = CLLocation(latitude: coordsB[0], longitude: coordsB[1])
                                
                                let distanceA = locationA.distance(from: userLocation)
                                let distanceB = locationB.distance(from: userLocation)
                                
                                return distanceA < distanceB
                                
                            case .rating:
                                return a.post.starRating > b.post.starRating
                            case .popularity:
                                return a.post.likes > b.post.likes
                            }
                        }
                        self.isLoading = false
                    }
                }
        }
    }
}




struct WishlistView: View {
    @State private var wishlistPosts: [(post: Post, userName: String)] = []
    @State private var isLoading = true

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading Wishlist...")
            } else if wishlistPosts.isEmpty {
                Text("Your wishlist is empty!")
                    .font(.title)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(wishlistPosts, id: \.post._id) { (post, userName) in
                            RestaurantCard(post: post, userName: userName)
                        }
                    }
                }
            }
        }
        .onAppear {
            if wishlistPosts.isEmpty {
                fetchWishlist()
            }
        }
    }

    private func fetchWishlist() {
        Task {
            do {
                wishlistPosts = try await AuthViewModel.shared.fetchWishlist()
                isLoading = false
            } catch {
                print("❌ Failed to fetch wishlist: \(error)")
                isLoading = false
            }
        }
    }
}



extension Notification.Name {
    static let reloadWishlist = Notification.Name("reloadWishlist")
}

