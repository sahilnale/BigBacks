import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel(authViewModel: AuthViewModel())
    @State private var showEditProfile = false

    @State private var offset: CGFloat = UIScreen.main.bounds.height * 0.5
    private let screenHeight = UIScreen.main.bounds.height
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                profileBackground
                
                // Foreground Sliding Drawer
                GeometryReader { geometry in
                    VStack(spacing: 16) {
                        Capsule()
                            .frame(width: 40, height: 6)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                showEditProfile = true
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.customOrange)
                                    .font(.system(size: 20))
                            }
                            .padding(.top, 8)
                            .padding(.trailing, 20)
                        }
                        
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
                                    PostGridView(posts: viewModel.posts, columns: columns)
                                        .padding(.horizontal)
                                    
                                    Spacer()
                                    
                                    LogoutButton {
                                        authViewModel.logout()
                                    }
                                    .padding(.top, 16)
                                    .padding(.horizontal)
                                    .padding(.bottom, 80)
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
                    .sheet(isPresented: $showEditProfile) {
                        EditProfileView(profileViewModel: viewModel)
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
                                    let upperLimit = screenHeight * 0.08
                                    let lowerLimit = screenHeight * 0.08
                                    
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
    
    // MARK: - Background View
    @ViewBuilder
    private var profileBackground: some View {
        if let profilePicture = viewModel.profilePicture, !profilePicture.isEmpty {
            AsyncImage(url: URL(string: profilePicture)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .clipped()
            } placeholder: {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
        } else if let latestPost = viewModel.posts.last, !latestPost.imageUrls.isEmpty {
            AsyncImage(url: URL(string: latestPost.imageUrls[0])) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
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
}






struct PostGridView: View {
    let posts: [Post]
    let columns: [GridItem]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(posts.reversed(), id: \._id) { post in
                NavigationLink(destination: PostView(post: post)) {
                    AsyncImage(url: URL(string: post.imageUrls[0])) { phase in
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



//import SwiftUI
//
//struct PostDetailView: View {
//    @ObservedObject private var authViewModel = AuthViewModel.shared
//    var post: Post
//    @Environment(\.dismiss) var dismiss
//    @State private var isDeleting = false
//    @State private var showAlert = false
//    @State private var errorMessage: String?
//
//    var body: some View {
//        ScrollView {
//            
//
//            VStack(spacing: 16) {
//                // Image Section
//                ZStack(alignment: .topTrailing) {
//                    Text("Updated View!") // Add this temporarily
//                    AsyncImage(url: URL(string: post.imageUrls[0])) { phase in
//                        switch phase {
//                        case .empty:
//                            ProgressView()
//                                .frame(height: 280)
//                                .frame(maxWidth: .infinity)
//                                .background(Color.gray.opacity(0.3))
//                                .cornerRadius(12)
//                        case .success(let image):
//                            image
//                                .resizable()
//                                .scaledToFill()
//                                .frame(height: 280)
//                                .frame(maxWidth: .infinity)
//                                .clipped()
//                                .cornerRadius(12)
//                        case .failure:
//                            Color.red.opacity(0.3)
//                                .frame(height: 280)
//                                .frame(maxWidth: .infinity)
//                                .cornerRadius(12)
//                        @unknown default:
//                            EmptyView()
//                        }
//                    }
//                }
//                .padding(.horizontal)
//
//                // Restaurant Name & Location
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(post.restaurantName)
//                        .font(.title2)
//                        .fontWeight(.bold)
//                    
//                    HStack {
//                        Image(systemName: "mappin.and.ellipse")
//                            .foregroundColor(.blue)
//                        Text(post.location)
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//                    }
//                }
//                .padding(.horizontal)
//
//                // Rating Section
//                HStack {
//                    ForEach(0..<5) { star in
//                        Image(systemName: star < post.starRating ? "star.fill" : "star")
//                            .foregroundColor(star < post.starRating ? .yellow : .gray.opacity(0.5))
//                            .font(.system(size: 18))
//                    }
//                }
//                .padding(.horizontal)
//
//                // Review Section
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Review")
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    Text(post.review)
//                        .font(.body)
//                        .foregroundColor(.secondary)
//                        .multilineTextAlignment(.leading)
//                        .padding(.top, 2)
//                }
//                .padding()
//                .background(Color(UIColor.systemBackground))
//                .cornerRadius(12)
//                .shadow(radius: 3)
//                .padding(.horizontal)
//
//                // Likes Section
//                HStack {
//                    Image(systemName: "heart.fill")
//                        .foregroundColor(.red)
//                    Text("\(post.likes) likes")
//                        .font(.subheadline)
//                        .foregroundColor(.gray)
//                }
//                .padding(.horizontal)
//
//                // Comments Section
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("HELLOOSss")
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    if post.comments.isEmpty {
//                        Text("No comments yet.")
//                            .font(.body)
//                            .foregroundColor(.gray)
//                    } else {
//                        ForEach(post.comments, id: \.self) { comment in
//                            HStack {
//                                Image(systemName: "bubble.right.fill")
//                                    .foregroundColor(.gray)
//                                Text(comment.text) // Assuming `text` is the correct property
//                                    .font(.body)
//                                    .foregroundColor(.secondary)
//                            }
//                            .padding(.vertical, 4)
//                        }
//                    }
//                }
//                .padding()
//                .background(Color(UIColor.systemBackground))
//                .cornerRadius(12)
//                .shadow(radius: 3)
//                .padding(.horizontal)
//
//                // Delete Post Button (if user is owner)
//                if authViewModel.currentUser?.id == post.userId {
//                    Button(action: {
//                        showAlert = true
//                    }) {
//                        HStack {
//                            Image(systemName: "trash.fill")
//                                .foregroundColor(.white)
//                            Text("Delete IT NOWWW")
//                                .fontWeight(.bold)
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.red)
//                        .foregroundColor(.white)
//                        .cornerRadius(12)
//                        .shadow(radius: 3)
//                    }
//                    .padding(.horizontal)
//                    .padding(.top, 10)
//                }
//            }
//            .padding(.top)
//            
//        }
//        .navigationTitle("Post Details")
//        .navigationBarTitleDisplayMode(.inline)
//        .alert("Delete ITTT NOWW", isPresented: $showAlert) {
//            Button("Cancel", role: .cancel) {}
//            Button("Delete", role: .destructive) {
//                Task {
//                    await deletePost()
//                }
//            }
//        } message: {
//            Text("Are you sure you want to delete this post? This action cannot be undone.")
//        }
//    }
//
//    private func deletePost() async {
//        isDeleting = true
//        do {
//            try await AuthViewModel.shared.deletePost(postId: post.id)
//            dismiss()
//        } catch {
//            errorMessage = error.localizedDescription
//        }
//        isDeleting = false
//    }
//}

import SwiftUI

struct PostDetailView: View {
    @ObservedObject private var authViewModel = AuthViewModel.shared
    var post: Post
    @Environment(\.dismiss) var dismiss
    @State private var isDeleting = false
    @State private var showAlert = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image Section
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: post.imageUrls.first ?? "")) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 300)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(15)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 300)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .cornerRadius(15)
                        case .failure:
                            Color.red.opacity(0.3)
                                .frame(height: 300)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(15)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                .padding(.horizontal)

                // Restaurant Name & Location
                VStack(alignment: .leading, spacing: 6) {
                    Text(post.restaurantName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.blue)
                        Text(post.location)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)

                // Rating Section
                HStack {
                    ForEach(0..<5) { star in
                        Image(systemName: star < post.starRating ? "star.fill" : "star")
                            .foregroundColor(star < post.starRating ? .yellow : .gray.opacity(0.4))
                            .font(.system(size: 20))
                    }
                }
                .padding(.horizontal)

                // Review Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Review")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(post.review)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 2)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(15)
                .shadow(radius: 3)
                .padding(.horizontal)

                // Likes Section
                HStack(spacing: 5) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("\(post.likes) likes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)

                // Comments Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Comments")
                        .font(.headline)
                        .foregroundColor(.primary)

                    if post.comments.isEmpty {
                        Text("No comments yet.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(post.comments, id: \.self) { comment in
                            HStack(alignment: .top) {
                                Image(systemName: "bubble.right.fill")
                                    .foregroundColor(.gray)
                                    .padding(.top, 2)
                                VStack(alignment: .leading) {
                                    Text(comment.text) // Assuming `text` is the correct property
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .padding(8)
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(15)
                .shadow(radius: 3)
                .padding(.horizontal)

                // Delete Post Button (if user is owner)
                if authViewModel.currentUser?.id == post.userId {
                    Button(action: {
                        showAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete THAT Post")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
            }
            .padding(.top)
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



