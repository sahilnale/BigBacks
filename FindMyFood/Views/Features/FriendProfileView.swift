//
//  FriendProfileView.swift
//  FindMyFood
//
//  Created by Ridhima Morampudi on 1/15/25.
//

//import SwiftUI
//
//struct FriendProfileView: View {
//    let userId: String // Friend's user ID
//    @StateObject private var viewModel = ProfileViewModel(authViewModel: AuthViewModel())
//    
//
//    private let columns = [
//        GridItem(.flexible()),
//        GridItem(.flexible()),
//    ]
//
//    var body: some View {
//        ScrollView {
//            VStack {
//                // Profile Image
//                VStack {
//                    if let profilePicture = viewModel.profilePicture, !profilePicture.isEmpty {
//                        AsyncImage(url: URL(string: profilePicture)) { image in
//                            image
//                                .resizable()
//                                .scaledToFill()
//                                .frame(width: 100, height: 100)
//                                .clipShape(Circle())
//                        } placeholder: {
//                            Circle()
//                                .fill(Color.gray.opacity(0.5))
//                                .frame(width: 100, height: 100)
//                        }
//                    } else {
//                        Image(systemName: "person.circle.fill")
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 100, height: 100)
//                            .clipShape(Circle())
//                            .foregroundColor(.customOrange)
//                    }
//
//                }
//                .padding(.top)
//
//                // Profile Header
//                VStack(spacing: 16) {
//                    Text(viewModel.name)
//                        .font(.custom("Lobster-Regular", size: 28))
//                        .foregroundColor(.primary)
//
//                    Text("@\(viewModel.username)")
//                        .font(.custom("Lobster-Regular", size: 18))
//                        .foregroundColor(.gray)
//
//                    // Posts and Friends Count
//                    HStack(spacing: 32) {
//                        VStack {
//                            Text("\(viewModel.posts.count)")
//                                .font(.custom("Lobster-Regular", size: 20))
//                                .foregroundColor(.primary)
//                            Text("Posts")
//                                .font(.system(size: 14, weight: .regular))
//                                .foregroundColor(.gray)
//                        }
//
//                        VStack {
//                            Text("\(viewModel.friendsCount)")
//                                .font(.custom("Lobster-Regular", size: 20))
//                                .foregroundColor(.primary)
//                            Text("Friends")
//                                .font(.system(size: 14, weight: .regular))
//                                .foregroundColor(.gray)
//                        }
//                    }
//                }
//                .padding(.horizontal)
//
//                Divider()
//                    .padding(.vertical, 16)
//
//                // Posts Section
//                if viewModel.isLoading {
//                    ProgressView("Loading posts...")
//                        .padding()
//                } else if viewModel.posts.isEmpty {
//                    Text("No posts yet.")
//                        .font(.custom("Lobster-Regular", size: 16))
//                        .foregroundColor(.gray)
//                        .frame(maxWidth: .infinity, alignment: .center)
//                        .padding()
//                } else {
//                    PostGridView(posts: viewModel.posts, columns: columns)
//                        .padding(.horizontal)
//                }
//            }
//        }
//        
//        .onAppear {
//            Task {
//                await viewModel.loadFriendProfile(userId: userId)
//            }
//        }
//    }
//}


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
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
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
                                    if viewModel.isLoading {
                                        ProgressView("Loading posts...")
                                            .padding()
                                    } else if viewModel.posts.isEmpty {
                                        Text("No posts yet.")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .padding()
                                    } else {
                                        PostGridView(posts: viewModel.posts, columns: columns)
                                            .padding(.horizontal)
                                    }
                                }
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
                                if newOffset >= 0 && newOffset <= screenHeight * 0.6 {
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
                    .animation(.easeInOut, value: offset)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadFriendProfile(userId: userId)
                }
            }
        }
    }
}
