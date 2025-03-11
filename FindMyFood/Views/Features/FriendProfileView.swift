//
//  FriendProfileView.swift
//  FindMyFood
//
//  Created by Ridhima Morampudi on 1/15/25.
//

//3/11
import SwiftUI

struct FriendProfileView: View {
    let userId: String // Friend's user ID
    @StateObject private var viewModel = ProfileViewModel(authViewModel: AuthViewModel())
    
    @State private var offset: CGFloat = UIScreen.main.bounds.height * 0.5
    private let screenHeight = UIScreen.main.bounds.height
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
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
                } else if let latestPost = viewModel.posts.last, let firstImageUrl = latestPost.imageUrls.first, !firstImageUrl.isEmpty {
                    AsyncImage(url: URL(string: firstImageUrl)) { image in
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
            .ignoresSafeArea()

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
                    
                    ScrollView {
                        PostGridView(posts: viewModel.posts, columns: columns)
                            .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(
                    Color(.systemBackground)
                        .opacity(0.95)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                )
                .offset(y: offset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            let newOffset = offset + gesture.translation.height
                            if newOffset >= 0 && newOffset <= screenHeight * 0.7 {
                                offset = newOffset
                            }
                        }
                        .onEnded { gesture in
                            withAnimation(.spring()) {
                                if gesture.predictedEndTranslation.height < 0 {
                                    offset = 0
                                } else {
                                    offset = screenHeight * 0.5
                                }
                            }
                        }
                )
            }
        }
        .onAppear {
            Task {
                await viewModel.loadFriendProfile(userId: userId)
            }
        }
    }
}


