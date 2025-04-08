import Foundation
import FirebaseCore
import UIKit

import FirebaseStorage






    
    //THIS DOESNT WORK DO NOT USE
//    func getAllPostsByUser(userId: String) async throws -> [Post] {
//        let endpoint = "\(baseURL)/users/\(userId)/posts"
//        guard let url = URL(string: endpoint) else {
//            throw NetworkError.invalidURL
//        }
//        
//        let (data, response) = try await URLSession.shared.data(from: url)
//        
//        guard let httpResponse = response as? HTTPURLResponse else {
//            throw NetworkError.invalidResponse
//        }
//        
//        guard (200...299).contains(httpResponse.statusCode) else {
//            throw NetworkError.error(from: httpResponse.statusCode)
//        }
//        
//        return try JSONDecoder().decode([Post].self, from: data) // Decodes an array of posts
//    }


    


extension NSNotification.Name {
    static let postAdded = NSNotification.Name("postAdded")
    static let postDeleted = NSNotification.Name("postDeleted")
}

// MARK: - Models
struct User: Codable, Identifiable {
    let id: String
    let name: String
    let username: String
    let email: String
    let friends: [String]
    let friendRequests: [String]
    let pendingRequests: [String]
    let posts: [Post]
    let profilePicture: String?
    var loggedIn: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case username
        case email
        case friends
        case friendRequests
        case pendingRequests
        case posts
        case profilePicture
        case loggedIn
    }
}

struct Post: Codable, Identifiable, Hashable {
    let _id: String
    var id: String { _id }
    let userId: String
    let imageUrls: [String]
    let timestamp: Timestamp
    let review: String
    let location: String
    let restaurantName: String
    var likes: Int
    var likedBy: [String]
    let starRating: Int
    var comments: [Comment]

    var date: Date {
        return timestamp.dateValue() // Helper to convert Timestamp to Date
    }
}

struct LikeResponse: Decodable {
    let likes: Int
    let liked: Bool
    let likedBy: [User]
}

