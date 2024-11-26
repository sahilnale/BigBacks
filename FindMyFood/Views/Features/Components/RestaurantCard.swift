//import SwiftUI
//
//struct RestaurantCard: View {
//    var body: some View {
//        VStack(alignment: .leading) {
//            Image("placeholder")
//                .resizable()
//                .aspectRatio(contentMode: .fill)
//                .frame(height: 200)
//                .clipped()
//            
//            HStack {
//                Text("Restaurant Name")
//                    .font(.headline)
//                Spacer()
//                HStack {
//                    Image(systemName: "star.fill")
//                        .foregroundColor(.yellow)
//                    Text("4.5")
//                }
//            }
//            .padding(.horizontal)
//            
//            Text("Description of the restaurant or recent review...")
//                .font(.subheadline)
//                .foregroundColor(.gray)
//                .padding(.horizontal)
//                .padding(.bottom)
//        }
//        .background(Color.white)
//        .cornerRadius(10)
//        .shadow(radius: 5)
//    }
//}
//


import SwiftUI

struct RestaurantCard: View {
    let post: Post
    @State private var isLiked: Bool = false
    @State private var likeCount: Int = 0
    @State private var isExpanded: Bool = false // Tracks if the description is expanded

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Dynamic image from post.imageUrl
            AsyncImage(url: URL(string: post.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 300, height: 200)
                    .clipped()
            } placeholder: {
                Color.gray.frame(width: 300, height: 200)
            }
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.accentColor)
                        Text(post.restaurantName) // Dynamic restaurant name
                            .font(.headline)
                            .foregroundColor(Color.primary)
                    }
                    
                    Text(post.review) // Dynamic review text
                        .font(.subheadline)
                        .foregroundColor(Color.secondary)
                        .lineLimit(isExpanded ? nil : 2)
                        .onTapGesture {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(post.starRating)") // Dynamic star rating
                            .font(.subheadline)
                            .foregroundColor(Color.primary)
                    }
                    
                    Button(action: {
                        isLiked.toggle()
                        likeCount += isLiked ? 1 : -1
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .accentColor : .gray)
                            Text("\(likeCount)") // Dynamic like count
                                .foregroundColor(Color.primary)
                                .font(.subheadline)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.primary.opacity(0.1), radius: 5)
        .padding(.horizontal)
        .onAppear {
            // Initialize the like count and status from the post
            likeCount = post.likes
            isLiked = post.likedBy.contains(AuthManager.shared.userId ?? "")
        }
    }
}
