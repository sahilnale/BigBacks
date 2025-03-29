import SwiftUI
import MapKit

struct PostView: View {
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @State var post: Post
    @Environment(\.dismiss) var dismiss
    @State private var isDeleting = false
    @State private var showAlert = false
    @State private var commenterUsernames: [String: String] = [:]
    @State private var errorMessage: String?
    @State private var currentImageIndex = 0
    @State private var showComments = false
    @State private var commentText = ""
    @State private var userLocation: CLLocation?

    
    private let spacing: CGFloat = 20
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing) {
                // Image Carousel
                if !post.imageUrls.isEmpty {
                    imageCarousel
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                
                // Restaurant Info Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(post.restaurantName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                       // Text(post.location)
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
                        
                        if let userLocation = userLocation {
                            let parts = post.location.split(separator: ",")
                            if parts.count == 2,
                               let lat = Double(parts[0]),
                               let lon = Double(parts[1]) {
                                let postLocation = CLLocation(latitude: lat, longitude: lon)
                                let distanceInMeters = userLocation.distance(from: postLocation)
                                let distanceInMiles = distanceInMeters / 1609.34
                                
                                Text(String(format: "%.1f miles away", distanceInMiles))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            } else {
                                Text("Invalid location format")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        } else {
                            Text("Locating...")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                    }
                    
                    // Star Rating
                    HStack(spacing: 4) {
                        ForEach(0..<5) { star in
                            Image(systemName: star < post.starRating ? "star.fill" : "star")
                                .foregroundColor(star < post.starRating ? .yellow : .gray.opacity(0.3))
                                .font(.system(size: 18))
                        }
                        
                        Text("\(post.starRating).0")
                            .font(.headline)
                            .foregroundColor(.yellow)
                            .padding(.leading, 4)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Review Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Review")
                        .font(.headline)
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Text(post.review)
                        .font(.body)
                        .lineSpacing(6)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    
                    // Social Stats
                    HStack(spacing: 16) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("\(post.likes)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(20)
                        
                        HStack {
                            Image(systemName: "bubble.left.fill")
                                .foregroundColor(.blue)
                            Text("\(post.comments.count)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                        .onTapGesture {
                            withAnimation {
                                showComments.toggle()
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Comments Section
                if showComments {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Comments")
                                .font(.headline)
                                .foregroundColor(.primary.opacity(0.8))
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    showComments.toggle()
                                }
                            }) {
                                Image(systemName: "chevron.up")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if post.comments.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    Image(systemName: "bubble.middle.bottom")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text("No comments yet")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 20)
                        } else {
                            ForEach(post.comments, id: \.self) { comment in
                                commentView(for: comment)
                            }
                        }
                        
                        // Comment input field
                        HStack {
                            TextField("Add a comment...", text: $commentText)
                                .padding(10)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(20)
                            
                            Button(action: {
                                // Add comment functionality
                            }) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                } else {
                    Button(action: {
                        withAnimation {
                            showComments.toggle()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Show Comments")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            Image(systemName: "chevron.down")
                                .foregroundColor(.blue)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Delete Post Button (if owner)
                if authViewModel.currentUser?.id == post.userId {
                    VStack {
                        Button(action: {
                            showAlert = true
                        }) {
                            HStack {
                                Spacer()
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete Post")
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                Spacer()
                            }
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
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
        .onAppear {
            Task {
                do {
                    let updatedPost = try await AuthViewModel.shared.fetchPostDetails(postId: post.id)
                    await MainActor.run {
                        self.post.comments = updatedPost.comments
                    }
                } catch {
                    print("Failed to fetch updated post details: \(error)")
                }
                
                LocationManager.shared.startUpdatingLocation { location in
                           userLocation = location
                }
            }
        }
        .overlay(
            Group {
                if isDeleting {
                    ZStack {
                        Color.black.opacity(0.4)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                    .ignoresSafeArea()
                }
            }
        )
    }
    
    // MARK: - Helper Views
    
    private var imageCarousel: some View {
        TabView(selection: $currentImageIndex) {
            ForEach(post.imageUrls.indices, id: \.self) { index in
                AsyncImage(url: URL(string: post.imageUrls[index])) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.2)
                            ProgressView()
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        ZStack {
                            Color.gray.opacity(0.2)
                            VStack(spacing: 8) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("Failed to load image")
                                    .foregroundColor(.gray)
                            }
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .frame(height: 350)
    }
    
    private func commentView(for comment: Comment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String((commenterUsernames[comment.userId] ?? "?").prefix(1)).uppercased())
                            .foregroundColor(.primary)
                            .font(.system(size: 16, weight: .bold))
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("@\(commenterUsernames[comment.userId] ?? "Loading...")")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Text(comment.text)
                        .font(.system(size: 15))
                        .lineSpacing(3)
                }
                .padding(.leading, 4)
                .onAppear {
                    fetchUsername(for: comment.userId)
                }
                
                Spacer()
            }
            
            Divider()
                .padding(.leading, 40)
        }
        .padding(.vertical, 6)
    }
    
    // MARK: - Helper Methods
    
    private func fetchUsername(for userId: String) {
        if commenterUsernames[userId] != nil {
            return
        }

        Task {
            do {
                if let user = try await authViewModel.getUserById(friendId: userId) {
                    await MainActor.run {
                        commenterUsernames[userId] = user.username
                    }
                } else {
                    await MainActor.run {
                        commenterUsernames[userId] = "Unknown User"
                    }
                }
            } catch {
                print("Failed to fetch username for userId \(userId): \(error)")
                await MainActor.run {
                    commenterUsernames[userId] = "Error"
                }
            }
        }
    }

    private func deletePost() async {
        isDeleting = true
        do {
            try await authViewModel.deletePost(postId: post.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isDeleting = false
    }
}
