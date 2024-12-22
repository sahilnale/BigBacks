import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel(authViewModel: AuthViewModel())
    
    
    
    @State private var isPickerPresented = false // State to control picker presentation
    @State private var selectedImage: UIImage? // Store the selected image

    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    // Profile Image Placeholder
                    VStack {
                         Image(systemName: "person.circle.fill")
                             .resizable()
                             .scaledToFill()
                             .frame(width: 100, height: 100)
                             .clipShape(Circle())
                             .foregroundColor(.accentColor)
                     }
                     .padding(.top)
                    
                    // Profile Header
                    VStack(spacing: 16) {
                        // Name and Username Section
                        VStack(spacing: 4) {
                            Text(viewModel.name)
                                .font(.custom("Lobster-Regular", size: 28)) // Creative, bold, and eye-catching
                                .foregroundColor(.primary)
                            
                            Text("@\(viewModel.username)")
                                .font(.custom("Lobster-Regular", size: 18)) // Stylish and complementary
                                .foregroundColor(.gray)
                        }
                        .padding(.top)
                        
                        // Profile Image
//                        Image(systemName: "person.circle.fill")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 100, height: 100)
//                            .clipShape(Circle())
//                            .foregroundColor(Color.accentColor)
//                            .padding(.bottom, 8)
                        
                        
                        
                        // Posts and Friends Count
                        HStack(spacing: 32) {
                            VStack {
                                Text("\(viewModel.posts.count)")
                                    .font(.custom("Lobster-Regular", size: 20)) // Consistent and stylish
                                    .foregroundColor(.primary)
                                Text("Posts")
                                    .font(.system(size: 14, weight: .regular)) // Keep labels clean for balance
                                    .foregroundColor(.gray)
                            }
                            
                            VStack {
                                Text("\(viewModel.friendsCount)")
                                    .font(.custom("Lobster-Regular", size: 20)) // Consistent and stylish
                                    .foregroundColor(.primary)
                                Text("Friends")
                                    .font(.system(size: 14, weight: .regular)) // Keep labels clean for balance
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical, 16)
                    
                    // Posts Section
                    if viewModel.isLoading {
                        ProgressView("Loading posts...")
                            .padding()
                    } else if viewModel.posts.isEmpty {
                        Text("No posts yet.")
                            .font(.custom("Lobster-Regular", size: 16))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        PostGridView(posts: viewModel.posts, columns: columns)
                            .padding(.horizontal)
                    }
                    
                    // Logout Button
                    LogoutButton {
                        authViewModel.logout()
                    }
                }
            }
//            .navigationBarItems(trailing: NavigationLink(destination: EditProfileView()) {
//                Image(systemName: "pencil")
//                    .font(.system(size: 20))
//            })
            .onAppear {
                Task {
                    await viewModel.loadProfile()
                }
            }
            // Attach image picker
            
        }
    }
}



// MARK: - Image Picker Component
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
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
                Text("@\(username)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Post Grid View
struct PostGridView: View {
    let posts: [Post]
    let columns: [GridItem]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(posts.reversed(), id: \._id) { post in
                NavigationLink(destination: PostDetailView(post: post)) {
                    AsyncImage(url: URL(string: post.imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView() // Show a loading indicator while the image loads
                                .frame(width: 100, height: 100)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .clipped()
                        case .failure:
                            Color.red // Display a red box if the image fails to load
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
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
                .background(Color.accentColor)
                .cornerRadius(10)
                .padding()
        }
    }
}

// MARK: - Post Detail View
struct PostDetailView: View {
    var post: Post // Pass the entire `Post` object
    @Environment(\.dismiss) var dismiss
    @State private var isDeleting = false
    @State private var showAlert = false
    @State private var errorMessage: String?

    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Post Image
                AsyncImage(url: URL(string: post.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView() // Show loading spinner
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

                // Restaurant Name
                Text(post.restaurantName)
                    .font(.title)
                    .fontWeight(.bold)
                
                // Location
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                    Text(post.location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Star Rating
                HStack {
                    ForEach(0..<5) { star in
                        Image(systemName: star < post.starRating ? "star.fill" : "star")
                            .foregroundColor(star < post.starRating ? .yellow : .gray)
                    }
                }
                
                // Review
                Text("Review")
                    .font(.headline)
                Text(post.review)
                    .font(.body)
                    .foregroundColor(.secondary)

                // Likes
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("\(post.likes) likes")
                        .font(.subheadline)
                }
                
                // Comments
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
                HStack {
                   Spacer()
                   Button(action: {
                       showAlert = true
                   }) {
                       Text("Delete Post")
                           .foregroundColor(.accentColor)
                   }
                   Spacer()
               }
               .padding()
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
        print("Starting deletePost function")
        isDeleting = true
        do {
            print("Attempting to delete post with ID: \(post.id)")
            try await NetworkManager.shared.deletePost(postId: post.id)
            print("Post deletion successful")
            DispatchQueue.main.async {
                print("Attempting to dismiss the view")
                dismiss()
            }
        } catch {
            print("Error deleting post: \(error)")
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

