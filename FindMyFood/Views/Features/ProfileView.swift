import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel(authViewModel: AuthViewModel())
    
    @State private var offset: CGFloat = UIScreen.main.bounds.height * 0.5
    private let screenHeight = UIScreen.main.bounds.height
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Layer
                Group {
                        if let profilePicture = viewModel.profilePicture, !profilePicture.isEmpty {
                            AsyncImage(url: URL(string: profilePicture)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height) // Ensure full-screen coverage
                                    .clipped()
                            } placeholder: {
                                Color(.systemBackground)
                                    .ignoresSafeArea()
                            }
                        } else if let latestPost = viewModel.posts.last, !latestPost.imageUrl.isEmpty {
                            AsyncImage(url: URL(string: latestPost.imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height) // Ensure full-screen coverage
                                    .clipped()
                            } placeholder: {
                                Color(.systemBackground)
                                    .ignoresSafeArea()
                            }
                        } else {
                            Color(.systemBackground)
                                .ignoresSafeArea()
                        }
                    }
                    .ignoresSafeArea() // Ensure the background covers the entire screen
                
                // Foreground Sliding Drawer
                GeometryReader { geometry in
                    VStack(spacing: 16) {
                        Capsule()
                            .frame(width: 40, height: 6)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                        
                        VStack(spacing: 4) {
                            Text(viewModel.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.top, 8)
                            
                            Text("@\(viewModel.username)")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 32) {
                            VStack {
                                Text("\(viewModel.posts.count)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("Posts")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            VStack {
                                Text("\(viewModel.friendsCount)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("Friends")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.bottom, 16)
                        
                        if offset <= geometry.size.height * 0.3 {
                            ScrollView {
                                VStack {
                                    // Posts Grid
                                    PostGridView(posts: viewModel.posts, columns: columns)
                                        .padding(.horizontal)
                                    Spacer()
                                    // Logout button placed after all posts
                                    LogoutButton {
                                        authViewModel.logout()
                                    }
                                    .padding(.top, 16)
                                    .padding(.horizontal)
                                    .padding(.bottom, 80) // Add spacing at the end
                                }
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: geometry.size.height - offset, alignment: .top)
                                .padding(.bottom, 80)
                            }
                            .transition(.opacity)
                        } else {
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        Color(.systemBackground)
                            .opacity(0.9)
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black.opacity(0.1), Color.black.opacity(0.2)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .cornerRadius(20)
                    .shadow(radius: 5)
                    .offset(y: offset)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newOffset = offset + gesture.translation.height
                                            if newOffset >= screenHeight * 0.3 && newOffset <= screenHeight * 0.6 {
                                                offset = newOffset
                                }
                            }
                            .onEnded { gesture in
                                withAnimation(.spring()) {
                                    let upperLimit = screenHeight * 0.08  // Adjust this to control how high it goes
                                    let lowerLimit = screenHeight * 0.08   // Default lower position
                                                    
                                    if gesture.predictedEndTranslation.height < 0 {
                                        offset = upperLimit
                                    } else {
                                        offset = lowerLimit
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
                    print("Profile Picture URL: \(viewModel.profilePicture ?? "No URL")")
                }
            }
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
                    AsyncImage(url: URL(string: post.imageUrl)) { phase in
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

struct PostDetailView: View {
    @ObservedObject private var authViewModel = AuthViewModel.shared
    var post: Post // Pass the entire `Post` object
    @Environment(\.dismiss) var dismiss
    @State private var isDeleting = false
    @State private var showAlert = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: post.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .background(Color.gray.opacity(0.3))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .clipped()
                    case .failure:
                        Text("Failed to load image")
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .background(Color.red.opacity(0.3))
                    @unknown default:
                        EmptyView()
                    }
                }
                
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


// MARK: - Preview
#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
