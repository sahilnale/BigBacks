import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel(authViewModel: AuthViewModel())
    @State private var showEditProfile = false
    
    // How high the sheet can go from the top (60 = 60pts down from top).
    private let topLimit: CGFloat = 60
    // Sheet can go as low as 90% of the screen height MINUS safe area insets.
    private let bottomLimitFactor: CGFloat = 0.9
    
    // Starting offset for the sheet (40% down the screen).
    @State private var offset: CGFloat = UIScreen.main.bounds.height * 0.4
    
    // Two-column grid with minimal spacing
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                // MARK: - Background
                backgroundView()
                    // Optional overlay for text contrast
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea()
                
                // MARK: - Sliding Sheet
                GeometryReader { geometry in
                    
                    // 1) Safe area–aware bottom limit
                    let safeAreaBottom = geometry.safeAreaInsets.bottom
                    let screenHeight = geometry.size.height
                    let bottomLimit = screenHeight * bottomLimitFactor - safeAreaBottom
                    
                    VStack(spacing: 0) {
                        
                        // Grab handle
                        Capsule()
                            .frame(width: 50, height: 5)
                            .foregroundColor(.gray.opacity(0.8))
                            .padding(.top, 10)
                        
                        // Edit button (top-right)
                        HStack {
                            Spacer()
                            Button(action: { showEditProfile = true }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.customOrange)
                                    .font(.system(size: 20))
                            }
                            .padding(.top, 4)
                            .padding(.trailing, 20)
                        }
                        
                        // MARK: - Profile Info
                        VStack(spacing: 6) {
                            profileAvatarView()
                            
                            Text(viewModel.name)
                                .font(.system(size: 22, weight: .bold))
                            
                            Text("@\(viewModel.username)")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                            
                            // Stats
                            HStack(spacing: 40) {
                                VStack {
                                    Text("\(viewModel.posts.count)")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("Posts")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                VStack {
                                    Text("\(viewModel.friendsCount)")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("Friends")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.top, 4)
                            .padding(.bottom, 10)
                        }
                        .padding(.bottom, 6)
                        
                        // MARK: - 2-Column Grid + Logout
                        ScrollView {
                            VStack(spacing: 0) {
                                // Minimal 2-column grid
                                LazyVGrid(columns: columns, spacing: 2) {
                                    ForEach(viewModel.posts.reversed(), id: \._id) { post in
                                        NavigationLink(destination: PostView(post: post)) {
                                            if let firstImageUrl = post.imageUrls.first, !firstImageUrl.isEmpty {
                                                // Show post image
                                                AsyncImage(url: URL(string: firstImageUrl)) { phase in
                                                    switch phase {
                                                    case .empty:
                                                        ProgressView()
                                                            .frame(maxWidth: .infinity, minHeight: 150)
                                                            .background(Color.gray.opacity(0.3))
                                                    case .success(let image):
                                                        image
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(maxWidth: .infinity, minHeight: 150)
                                                            .clipped()
                                                    case .failure:
                                                        Color.gray
                                                            .frame(maxWidth: .infinity, minHeight: 150)
                                                    @unknown default:
                                                        EmptyView()
                                                    }
                                                }
                                            } else {
                                                // Placeholder if no image
                                                Color.gray
                                                    .frame(maxWidth: .infinity, minHeight: 150)
                                            }
                                        }
                                    }
                                }
                                
                                // Logout at bottom
                                LogoutButton {
                                    authViewModel.logout()
                                }
                                .padding(.top, 16)
                                .padding(.horizontal)
                                .padding(.bottom, 40)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    // Show Edit Profile
                    .sheet(isPresented: $showEditProfile) {
                        EditProfileView()
                    }
                    // Sheet background
                    .background(
                        Color(.systemBackground)
                            .opacity(0.95)
                    )
                    .cornerRadius(20)
                    .shadow(radius: 5)
                    
                    // 2) Apply offset + gesture with clamping
                    .offset(y: offset)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newOffset = offset + gesture.translation.height
                                // Hard clamp so it can’t vanish below bottomLimit or above topLimit
                                offset = max(topLimit, min(newOffset, bottomLimit))
                            }
                            .onEnded { _ in
                                withAnimation(.spring()) {
                                    let midpoint = (topLimit + bottomLimit) / 2
                                    // Snap to top if above midpoint, else bottom
                                    if offset < midpoint {
                                        offset = topLimit
                                    } else {
                                        offset = bottomLimit
                                    }
                                }
                            }
                    )
                    .animation(.easeInOut, value: offset)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadProfile()
                }
            }
        }
    }
    
    // MARK: - Avatar
    @ViewBuilder
    private func profileAvatarView() -> some View {
        if let pic = viewModel.profilePicture, !pic.isEmpty {
            AsyncImage(url: URL(string: pic)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 80, height: 80)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                @unknown default:
                    EmptyView()
                }
            }
            .overlay(Circle().stroke(Color.customOrange, lineWidth: 2))
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .overlay(Circle().stroke(Color.customOrange, lineWidth: 2))
        }
    }
    
    // MARK: - Background
    @ViewBuilder
    private func backgroundView() -> some View {
        if let profilePicture = viewModel.profilePicture, !profilePicture.isEmpty {
            // Show Profile Picture
            AsyncImage(url: URL(string: profilePicture)) { phase in
                switch phase {
                case .empty:
                    Color.gray.opacity(0.3)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Color.gray.opacity(0.3)
                @unknown default:
                    EmptyView()
                }
            }
        } else if let latestPost = viewModel.posts.last,
                  let firstImageUrl = latestPost.imageUrls.first,
                  !firstImageUrl.isEmpty {
            // Show last post image
            AsyncImage(url: URL(string: firstImageUrl)) { phase in
                switch phase {
                case .empty:
                    Color.gray.opacity(0.3)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Color.gray.opacity(0.3)
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            // Fallback background
            Color(.systemBackground)
        }
    }
}





struct PostGridView: View {
    let posts: [Post]
    let columns: [GridItem]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(posts.reversed(), id: \._id) { post in
                NavigationLink(destination: PostView(post: post)) {
                    if let firstImageUrl = post.imageUrls.first, !firstImageUrl.isEmpty {
                        AsyncImage(url: URL(string: firstImageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 177, height: 177)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 177, height: 177)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .clipped()
                            case .failure:
                                Color.red
                                    .frame(width: 177, height: 177)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        // Placeholder for posts without images
                        Color.gray
                            .frame(width: 177, height: 177)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(.bottom)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
}

// MARK: - Image Picker
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

// MARK: - ProfileHeaderView
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

struct PostDetailView: View {
    @ObservedObject private var authViewModel = AuthViewModel.shared
    var post: Post // Pass the entire `Post` object
    @Environment(\.dismiss) var dismiss
    @State private var isDeleting = false
    @State private var showAlert = false
    @State private var errorMessage: String?
    @State private var currentImageIndex: Int = 0 // Track the current image index

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !post.imageUrls.isEmpty { // Ensure there are images to display
                    // Instagram-style image carousel
                    TabView {
                        ForEach(post.imageUrls, id: \.self) { imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(maxWidth: .infinity, minHeight: 300)
                                        .background(Color.gray.opacity(0.3))
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity, minHeight: 300)
                                        .clipped()
                                case .failure:
                                    Text("Failed to load image")
                                        .frame(maxWidth: .infinity, minHeight: 300)
                                        .background(Color.red.opacity(0.3))
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle()) // Enables horizontal swiping
                    .frame(height: 300)
                } else {
                    Text("No images available")
                        .frame(maxWidth: .infinity, minHeight: 300)
                        .background(Color.gray.opacity(0.3))
                }
                
                // Post details (Restaurant name, location, etc.)
                Text(post.restaurantName)
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                    Text(post.location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    ForEach(0..<5) { star in
                        Image(systemName: star < post.starRating ? "star.fill" : "star")
                            .foregroundColor(star < post.starRating ? .yellow : .gray)
                    }
                }
                
                Text("Review")
                    .font(.headline)
                Text(post.review)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("\(post.likes) likes")
                        .font(.subheadline)
                }
                
                if !post.comments.isEmpty {
                    Text("Comments")
                        .font(.headline)
                    
                    ForEach(post.comments, id: \.self) { comment in
                        Text("• \(comment)")
                            .font(.body)
                            .padding(.vertical, 2)
                    }
                } else {
                    Text("No comments yet.")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                
                if authViewModel.currentUser?.id == post.userId {
                    HStack {
                        Spacer()
                        Button(action: {
                            showAlert = true
                        }) {
                            Text("Delete Post")
                                .foregroundColor(.customOrange)
                        }
                        Spacer()
                    }
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Post Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Post", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await deletePost()
                }
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
        
    }


    private func deletePost() async {
        isDeleting = true
        do {
            try await AuthViewModel.shared.deletePost(postId: post.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isDeleting = false
    }
}


struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}



// MARK: - Preview
#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
