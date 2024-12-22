import Foundation


import Foundation

struct Post: Codable, Identifiable {
    let id: String // Maps to `_id` in your schema
    let userId: String
    let imageUrl: String?
    let timestamp: Date
    let review: String
    let location: String
    let restaurantName: String
    var likes: Int
    var likedBy: [String]
    var starRating: Int
    var comments: [String]

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case imageUrl
        case timestamp
        case review
        case location
        case restaurantName
        case likes
        case likedBy
        case starRating
        case comments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        imageUrl = try? container.decodeIfPresent(String.self, forKey: .imageUrl)
        let timestampString = try container.decode(String.self, forKey: .timestamp)
        timestamp = ISO8601DateFormatter().date(from: timestampString) ?? Date()
        review = try container.decode(String.self, forKey: .review)
        location = try container.decode(String.self, forKey: .location)
        restaurantName = try container.decode(String.self, forKey: .restaurantName)
        likes = try container.decode(Int.self, forKey: .likes)
        likedBy = try container.decode([String].self, forKey: .likedBy)
        starRating = try container.decode(Int.self, forKey: .starRating)
        comments = try container.decode([String].self, forKey: .comments)
    }
}
