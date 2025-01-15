//
//  FriendProfileView.swift
//  FindMyFood
//
//  Created by Ridhima Morampudi on 1/15/25.
//

import SwiftUI

struct FriendProfileView: View {
    let userId: String // Friend's user ID
    @StateObject private var viewModel = ProfileViewModel(authViewModel: AuthViewModel())
    

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack {
                // Profile Image
                VStack {
                    if let profilePicture = viewModel.profilePicture, !profilePicture.isEmpty {
                        AsyncImage(url: URL(string: profilePicture)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 100, height: 100)
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .foregroundColor(.customOrange)
                    }

                }
                .padding(.top)

                // Profile Header
                VStack(spacing: 16) {
                    Text(viewModel.name)
                        .font(.custom("Lobster-Regular", size: 28))
                        .foregroundColor(.primary)

                    Text("@\(viewModel.username)")
                        .font(.custom("Lobster-Regular", size: 18))
                        .foregroundColor(.gray)

                    // Posts and Friends Count
                    HStack(spacing: 32) {
                        VStack {
                            Text("\(viewModel.posts.count)")
                                .font(.custom("Lobster-Regular", size: 20))
                                .foregroundColor(.primary)
                            Text("Posts")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                        }

                        VStack {
                            Text("\(viewModel.friendsCount)")
                                .font(.custom("Lobster-Regular", size: 20))
                                .foregroundColor(.primary)
                            Text("Friends")
                                .font(.system(size: 14, weight: .regular))
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
            }
        }
        
        .onAppear {
            Task {
                await viewModel.loadFriendProfile(userId: userId)
            }
        }
    }
}
