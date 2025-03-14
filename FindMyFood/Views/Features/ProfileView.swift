//
// MARK: - Image Picker Component
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}


// MARK: - Profile Header
struct ProfileHeaderView: View {
    let name: String
    let username: String
    let errorMessage: String?
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 100))
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text(name)
                    .font(.headline)
                    .padding(.top)
                Text("@\(username)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}


// MARK: - Logout Button
struct LogoutButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Logout")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Color.customOrange)
                .cornerRadius(10)
                .padding()
        }
    }
}


import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel(authViewModel: AuthViewModel())
    @State private var showEditProfile = false
    @State private var selectedTab = 0
    
    // Wishlist state
    @State private var wishlistPosts: [(post: Post, userName: String)] = []
    @State private var isLoadingWishlist = true
    
    // Drawer state management
    @State private var offset: CGFloat = UIScreen.main.bounds.height * 0.5
    private let screenHeight = UIScreen.main.bounds.height
    @State private var drawerExpanded = false
    
    // Grid layout
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background with blur and overlay gradient
                profileBackground
                
                // Sliding drawer
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Handle
                        HStack {
                            Spacer()
                            Capsule()
                                .frame(width: 40, height: 5)
                                .foregroundColor(.gray.opacity(0.6))
                            Spacer()
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 16)
                        
                        // Profile info section
                        VStack(spacing: 24) {
                            // Profile header with edit button
                            HStack(alignment: .center) {
                                // Profile image
                                profileImageView
                                    .padding(.horizontal)
                                
                                // Profile info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.name)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Text("@\(viewModel.username)")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Edit button
                                Button(action: {
                                    showEditProfile = true
                                }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.customOrange)
                                        .padding(10)
                                        .background(Color.customOrange.opacity(0.15))
                                        .clipShape(Circle())
                                }
                                .padding(.trailing, 16)
                            }
                            .padding(.horizontal, 8)
                            
                            // Stats bar
                            HStack(spacing: 0) {
                                statsItem(count: viewModel.posts.count, label: "Posts")
                                
                                Divider()
                                    .frame(height: 30)
                                    .padding(.horizontal, 15)
                                

                                
                                statsItem(count: viewModel.friendsCount, label: "Friends")
                            }
                            .padding(.vertical, 16)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 16)
                        
                        // Content section with tab view
                        if offset <= geometry.size.height * 0.4 || drawerExpanded {
                            VStack(spacing: 0) {
                                // Custom tab bar
                                HStack(spacing: 0) {
                                    tabButton(title: "Posts", index: 0)
                                    tabButton(title: "Wishlist", index: 1)
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                                
                                // Tab content
                                TabView(selection: $selectedTab) {
                                    // Posts grid
                                    ScrollView {
                                        VStack {
                                            PostGridView(posts: viewModel.posts, columns: columns)
                                                .padding(.horizontal, 8)
                                                .padding(.top, 8)
                                            
                                            // Logout button under posts
                                            logoutButton
                                                .padding(.top, 20)
                                                .padding(.bottom, 30)
                                        }
                                    }
                                    .tag(0)
                                    
                                    // Wishlist
                                    ScrollView {
                                        VStack {
                                            if isLoadingWishlist {
                                                ProgressView("Loading wishlist...")
                                                    .padding()
                                            } else if wishlistPosts.isEmpty {
                                                emptyStateView(
                                                    icon: "heart.slash",
                                                    message: "Your wishlist is empty!"
                                                )
                                            } else {
                                                LazyVStack(spacing: 16) {
                                                    ForEach(wishlistPosts, id: \.post._id) { (post, userName) in
                                                        RestaurantCard(post: post, userName: userName)
                                                            .padding(.horizontal)
                                                    }
                                                }
                                                .padding(.vertical, 12)
                                            }
                                            
                                            // Logout button under wishlist
                                            logoutButton
                                                .padding(.top, 20)
                                                .padding(.bottom, 30)
                                        }
                                    }
                                    .tag(1)
                                }
                                .tabViewStyle(.page(indexDisplayMode: .never))
                            }
                            .animation(.easeInOut, value: selectedTab)
                            .transition(.opacity)
                        } else {
                            Spacer()
                        }
                    }
                    .sheet(isPresented: $showEditProfile) {
                        EditProfileView(profileViewModel: viewModel)
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        Color(.systemBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: -5)
                    )
                    .offset(y: offset)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newOffset = offset + gesture.translation.height
                                if newOffset >= screenHeight * 0.2 && newOffset <= screenHeight * 0.6 {
                                    offset = newOffset
                                }
                            }
                            .onEnded { gesture in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    let upperLimit = screenHeight * 0.09
                                    let lowerLimit = screenHeight * 0.5
                                    
                                    if gesture.predictedEndTranslation.height < 0 {
                                        offset = upperLimit
                                        drawerExpanded = true
                                    } else {
                                        offset = lowerLimit
                                        drawerExpanded = false
                                    }
                                }
                            }
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: offset)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadProfile()
                    fetchWishlist()
                }
            }
            .onChange(of: selectedTab) { newValue in
                if newValue == 1 && isLoadingWishlist && wishlistPosts.isEmpty {
                    fetchWishlist()
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
    
    // MARK: - Wishlist Tab
    private var wishlistTabView: some View {
        // Replace the entire wishlist tab view with the ScrollView implementation above
        EmptyView()
    }
    
    // MARK: - Background View
    @ViewBuilder
    private var profileBackground: some View {
        if let profilePicture = viewModel.profilePicture, !profilePicture.isEmpty {
            AsyncImage(url: URL(string: profilePicture)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .blur(radius: 20)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.3),
                                Color.black.opacity(0.7)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } placeholder: {
                Color(.systemGray6)
                    .ignoresSafeArea()
            }
        } else if let latestPost = viewModel.posts.last, !latestPost.imageUrls.isEmpty {
            AsyncImage(url: URL(string: latestPost.imageUrls[0])) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .blur(radius: 20)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.3),
                                Color.black.opacity(0.7)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } placeholder: {
                Color(.systemGray6)
                    .ignoresSafeArea()
            }
        } else {
            Color(.systemGray6)
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Profile Image View
    private var profileImageView: some View {
        Group {
            if let profilePicture = viewModel.profilePicture, !profilePicture.isEmpty {
                AsyncImage(url: URL(string: profilePicture)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        )
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    )
            }
        }
    }
    
    // MARK: - Helper Views
    private func statsItem(count: Int, label: String) -> some View {
        VStack(spacing: 5) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: {
            selectedTab = index
        }) {
            VStack(spacing: 10) {
                Text(title)
                    .fontWeight(selectedTab == index ? .semibold : .regular)
                    .foregroundColor(selectedTab == index ? .primary : .secondary)
                
                ZStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 3)
                    
                    if selectedTab == index {
                        Rectangle()
                            .fill(Color.customOrange)
                            .frame(height: 3)
                            .matchedGeometryEffect(id: "TAB", in: namespace)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func emptyStateView(icon: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.7))
            
            Text(message)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: 300)
        .padding()
    }
    
    // MARK: - Fetch Wishlist
    private func fetchWishlist() {
        isLoadingWishlist = true
        Task {
            do {
                wishlistPosts = try await AuthViewModel.shared.fetchWishlist()
                isLoadingWishlist = false
            } catch {
                print("❌ Failed to fetch wishlist: \(error)")
                isLoadingWishlist = false
            }
        }
    }
    
    // MARK: - Logout Button
    private var logoutButton: some View {
        Button(action: {
            authViewModel.logout()
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16))
                Text("Logout")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.customOrange, Color.customOrange.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal, 20)
    }
    
    // Namespace for matched geometry effect
    @Namespace private var namespace
}

// MARK: - Post Grid View
struct PostGridView: View {
    let posts: [Post]
    let columns: [GridItem]
    
    var body: some View {
        if posts.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 50))
                    .foregroundColor(.gray.opacity(0.7))
                
                Text("No posts yet")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: 300)
            .padding()
        } else {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(posts.reversed(), id: \._id) { post in
                    NavigationLink(destination: PostView(post: post)) {
                        AsyncImage(url: URL(string: post.imageUrls[0])) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: (UIScreen.main.bounds.width - 24) / 2, height: (UIScreen.main.bounds.width - 24) / 2)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: (UIScreen.main.bounds.width - 24) / 2, height: (UIScreen.main.bounds.width - 24) / 2)
                                    .cornerRadius(12)
                                    .clipped()
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            case .failure:
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.red)
                                    .frame(width: (UIScreen.main.bounds.width - 24) / 2, height: (UIScreen.main.bounds.width - 24) / 2)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
            }
        }
    }
}

