////
////  FriendProfileView.swift
////  FindMyFood
////
////  Created by Ridhima Morampudi on 1/15/25.
////
//
////3/11
//import SwiftUI
//
//struct FriendProfileView: View {
//    let userId: String // Friend's user ID
//    @StateObject private var viewModel = ProfileViewModel(authViewModel: AuthViewModel())
//    
//    @State private var offset: CGFloat = UIScreen.main.bounds.height * 0.5
//    private let screenHeight = UIScreen.main.bounds.height
//    
//    private let columns = [
//        GridItem(.flexible()),
//        GridItem(.flexible())
//    ]
//    
//    var body: some View {
//        ZStack {
//            // Background Layer
//            Group {
//                if let profilePicture = viewModel.profilePicture, !profilePicture.isEmpty {
//                    AsyncImage(url: URL(string: profilePicture)) { image in
//                        image
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height) // Ensure full-screen coverage
//                            .clipped()
//                    } placeholder: {
//                        Color(.systemBackground)
//                            .ignoresSafeArea()
//                    }
//                } else if let latestPost = viewModel.posts.last, let firstImageUrl = latestPost.imageUrls.first, !firstImageUrl.isEmpty {
//                    AsyncImage(url: URL(string: firstImageUrl)) { image in
//                        image
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height) // Ensure full-screen coverage
//                            .clipped()
//                    } placeholder: {
//                        Color(.systemBackground)
//                            .ignoresSafeArea()
//                    }
//                } else {
//                    Color(.systemBackground)
//                        .ignoresSafeArea()
//                }
//            }
//            .ignoresSafeArea()
//
//            // Foreground Sliding Drawer
//            GeometryReader { geometry in
//                VStack(spacing: 16) {
//                    Capsule()
//                        .frame(width: 40, height: 6)
//                        .foregroundColor(.gray)
//                        .padding(.top, 8)
//
//                    VStack(spacing: 4) {
//                        Text(viewModel.name)
//                            .font(.system(size: 24, weight: .bold))
//                            .foregroundColor(.primary)
//                        
//                        Text("@\(viewModel.username)")
//                            .font(.system(size: 16, weight: .regular))
//                            .foregroundColor(.gray)
//                    }
//
//                    HStack(spacing: 32) {
//                        VStack {
//                            Text("\(viewModel.posts.count)")
//                                .font(.system(size: 18, weight: .bold))
//                                .foregroundColor(.primary)
//                            Text("Posts")
//                                .font(.system(size: 14))
//                                .foregroundColor(.gray)
//                        }
//                        
//                        VStack {
//                            Text("\(viewModel.friendsCount)")
//                                .font(.system(size: 18, weight: .bold))
//                                .foregroundColor(.primary)
//                            Text("Friends")
//                                .font(.system(size: 14))
//                                .foregroundColor(.gray)
//                        }
//                    }
//                    .padding(.bottom, 16)
//                    
//                    ScrollView {
//                        PostGridView(posts: viewModel.posts, columns: columns)
//                            .padding(.horizontal)
//                    }
//                }
//                .frame(maxWidth: .infinity)
//                .background(
//                    Color(.systemBackground)
//                        .opacity(0.95)
//                        .cornerRadius(20)
//                        .shadow(radius: 10)
//                )
//                .offset(y: offset)
//                .gesture(
//                    DragGesture()
//                        .onChanged { gesture in
//                            let newOffset = offset + gesture.translation.height
//                            if newOffset >= 0 && newOffset <= screenHeight * 0.7 {
//                                offset = newOffset
//                            }
//                        }
//                        .onEnded { gesture in
//                            withAnimation(.spring()) {
//                                if gesture.predictedEndTranslation.height < 0 {
//                                    offset = 0
//                                } else {
//                                    offset = screenHeight * 0.5
//                                }
//                            }
//                        }
//                )
//            }
//        }
//        .onAppear {
//            Task {
//                await viewModel.loadFriendProfile(userId: userId)
//            }
//        }
//    }
//}
//
//
import SwiftUI

struct FriendProfileView: View {
    let userId: String
    @StateObject private var viewModel = ProfileViewModel(authViewModel: AuthViewModel())

    @State private var offset: CGFloat = UIScreen.main.bounds.height * 0.5
    private let screenHeight = UIScreen.main.bounds.height
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    @State private var showMutualFriends = false

    var body: some View {
        ZStack {
            profileBackground

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Capsule()
                            .frame(width: 40, height: 5)
                            .foregroundColor(.gray.opacity(0.6))
                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                    VStack(spacing: 24) {
                        HStack(alignment: .center) {
                            profileImageView
                                .padding(.horizontal)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.name)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.primary)

                                Text("@\(viewModel.username)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 8)

                        HStack(spacing: 0) {
                            statsItem(count: viewModel.posts.count, label: "Posts")
                            Divider().frame(height: 30).padding(.horizontal, 15)
                            statsItem(count: viewModel.friendsCount, label: "Friends")
                            Divider().frame(height: 30).padding(.horizontal, 15)

                            Button {
                                if viewModel.mutualFriendsCount > 0 {
                                    showMutualFriends = true
                                }
                            } label: {
                                VStack(spacing: 5) {
                                    Text("\(viewModel.mutualFriendsCount)")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(viewModel.mutualFriendsCount > 0 ? .blue : .secondary)
                                    Text("Mutuals")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .disabled(viewModel.mutualFriendsCount == 0)
                        }
                        .padding(.vertical, 16)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    ScrollView {
                        PostGridView(posts: viewModel.posts, columns: columns)
                            .padding(.horizontal, 8)
                            .padding(.top, 8)
                        Spacer(minLength: 80)
                    }
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
                                let upper = screenHeight * 0.09
                                let lower = screenHeight * 0.5
                                offset = gesture.predictedEndTranslation.height < 0 ? upper : lower
                            }
                        }
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: offset)
            }
        }
        .onAppear {
            Task {
                print("Debug: Loading friend profile for userId: \(userId)")
                await viewModel.loadFriendProfile(userId: userId)
                print("Debug: Mutual Friends Count after loading: \(viewModel.mutualFriendsCount)")
            }
        }
        .sheet(isPresented: $showMutualFriends) {
            MutualFriendsSheet(users: viewModel.mutualFriends)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - UI Helpers

    private var profileBackground: some View {
        Group {
            if let url = URL(string: viewModel.profilePicture ?? ""), !viewModel.profilePicture!.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(.systemGray6)
                }
            } else if let post = viewModel.posts.last, let url = URL(string: post.imageUrls.first ?? "") {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(.systemGray6)
                }
            } else {
                Color(.systemGray6)
            }
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .blur(radius: 20)
        .overlay(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.3), Color.black.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea()
    }

    private var profileImageView: some View {
        Group {
            if let url = URL(string: viewModel.profilePicture ?? ""), !viewModel.profilePicture!.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
            } else {
                Color.gray.opacity(0.2)
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 3))
    }

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
}

struct MutualFriendsSheet: View {
    let users: [User]

    var body: some View {
        NavigationView {
            List(users, id: \.id) { user in
                NavigationLink(destination: FriendProfileView(userId: user.id)) {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: user.profilePicture ?? "")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())

                        VStack(alignment: .leading) {
                            Text(user.name)
                                .font(.body)
                                .fontWeight(.semibold)
                            Text("@\(user.username)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Mutual Friends")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

