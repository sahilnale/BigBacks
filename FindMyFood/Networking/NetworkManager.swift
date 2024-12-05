import Foundation
import UIKit

import FirebaseStorage

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://api.bigbacksapp.com/api/v1"
//    private let baseURL = "http://localhost.8080/api/v1"
    
    private var idNumber: String? {
        get {
            return AuthManager.shared.userId
        }
        set {
            if let newValue = newValue {
                AuthManager.shared.setUserId(newValue)
            } else {
                AuthManager.shared.clearUserId()
            }
        }
    }
    
    private init() {}
    
    func login(username: String, password: String) async throws -> User {
        let endpoint = "\(baseURL)/user/login"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "username": username,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        let loginResponse = try JSONDecoder().decode([String: String].self, from: data)
        guard let currId = loginResponse["userId"] else {
            throw NetworkError.badRequest("User ID not found in response")
        }
        idNumber = currId  // This will now persist in Keychain
        return try await getCurrentUser(userId: currId)
    }

    func getCurrentUser(userId: String) async throws -> User {
        let endpoint = "\(baseURL)/user/\(userId)"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw NetworkError.badRequest("User not found")
            }
            throw NetworkError.error(from: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    func logout() {
        idNumber = nil
    }
    
    //gets the user by id
    func getUserById(userId: String) async throws -> User {
        let endpoint = "\(baseURL)/user/\(userId)"  // Adjust the endpoint based on your backend structure
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw NetworkError.badRequest("User not found")
            }
            throw NetworkError.error(from: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(User.self, from: data)
    }

    
    
    // MARK: - Authentication
    func signUp(name: String, username: String, email: String, password: String) async throws -> User {
        let endpoint = "\(baseURL)/user/"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "name": name,
            "username": username,
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 409 {
                throw NetworkError.badRequest("Email or username already exists")
            }
            throw NetworkError.error(from: httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(User.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw NetworkError.decodingError
        }
        
    }
    
    func searchUsers(query: String) async throws -> [User] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/user/getByUsername/\(encodedQuery)") else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                return [] // Return an empty array if no users found
            }
            throw NetworkError.error(from: httpResponse.statusCode)
        }
        
        // Manually parse the JSON data
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                // Map the JSON objects into User objects
                let users = jsonArray.compactMap { json -> User? in
                    guard let id = json["_id"] as? String,
                          let name = json["name"] as? String,
                          let username = json["username"] as? String else {
                        return nil
                    }
                    let friends = json["friends"] as? [String] ?? []
                    let friendRequests = json["friendRequests"] as? [String] ?? []
                    let pendingRequests = json["pendingRequests"] as? [String] ?? []
                    let posts = json["posts"] as? [Post] ?? []
                    let profilePicture = json["profilePicture"] as? String
                    let loggedIn = json["loggedIn"] as? Bool ?? false
                    
                    return User(
                        id: id,
                        name: name,
                        username: username,
                        email: json["email"] as? String ?? "",
                        friends: friends,
                        friendRequests: friendRequests,
                        pendingRequests: pendingRequests,
                        posts: posts,
                        profilePicture: profilePicture,
                        loggedIn: loggedIn
                    )
                }
                return users
            } else {
                throw NetworkError.decodingError
            }
        } catch {
            print("Manual JSON parsing error: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    func sendFriendRequest(from currentUserId: String, to friendId: String) async throws {
           guard idNumber != friendId else {
               throw NetworkError.badRequest("Cannot send a friend request to yourself")
           }
           guard let currentId = idNumber else {
               throw NetworkError.badRequest("Not logged in")
           }
        
           let endpoint = "\(baseURL)/user/\(friendId)/friendRequest/\(currentId)"
           guard let url = URL(string: endpoint) else {
               throw NetworkError.invalidURL
           }
           var request = URLRequest(url: url)
           request.httpMethod = "POST"
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")

           do {
               let (data, response) = try await URLSession.shared.data(for: request)
               if let httpResponse = response as? HTTPURLResponse {
                   print("HTTP Status: \(httpResponse.statusCode)")
                   print("Response Body: \(String(data: data, encoding: .utf8) ?? "No body")")
                   if !(200...299).contains(httpResponse.statusCode) {
                       throw NetworkError.serverError("\(httpResponse.statusCode): \(String(data: data, encoding: .utf8) ?? "No response body")")
                   }
               }
           } catch {
               print("Error during send FriendRequest: \(error.localizedDescription)")
               throw error
           }
       }
    
    func acceptFriendRequest(userId: String, friendId: String) async throws {
        let endpoint = "\(baseURL)/user/\(userId)/acceptFriend/\(friendId)"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.error(from: httpResponse.statusCode)
        }
    }

    func rejectFriendRequest(userId: String, friendId: String) async throws {
        let endpoint = "\(baseURL)/user/\(userId)/rejectFriend/\(friendId)"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            if let responseBody = String(data: data, encoding: .utf8) {
                print("Response Body: \(responseBody)")
            }

            if httpResponse.statusCode == 400 {
                throw NetworkError.badRequest("Invalid friend request")
            } else if httpResponse.statusCode == 404 {
                throw NetworkError.badRequest("User not found")
            } else if !(200...299).contains(httpResponse.statusCode) {
                throw NetworkError.serverError("\(httpResponse.statusCode): \(String(data: data, encoding: .utf8) ?? "No response body")")
            }
        } catch {
            print("Error during reject Friend Request: \(error.localizedDescription)")
            throw error
        }
    }

    func getFriendRequests(userId: String) async throws -> [User] {
        // First get the current user to access their friend requests
        let user = try await getCurrentUser(userId: userId)
        
        // Then fetch full user details for each friend request ID
        var requesters: [User] = []
        for requesterId in user.friendRequests {
            let requester = try await getUserById(userId: requesterId)
            requesters.append(requester)
        }
        
        return requesters
    }
    
    
    func addPost(
        userId: String,
        imageData: Data,
        review: String,
        location: String,
        restaurantName: String,
        starRating: Int
    ) async throws -> Post {
        let endpoint = "\(baseURL)/post/upload/\(userId)"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Create a multipart form-data boundary
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build multipart form-data body
        var body = Data()
        let lineBreak = "\r\n"

        // Add the image as a file
        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append(imageData)
        body.append(lineBreak.data(using: .utf8)!)
        
        

        // Add additional fields
        let fields: [String: Any] = [
            "review": review,
            "location": location,
            "restaurantName": restaurantName,
            "starRating": starRating
        ]
        
        for (key, value) in fields {
            body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)".data(using: .utf8)!)
            body.append("\(value)\(lineBreak)".data(using: .utf8)!)
        }

        // Close the body
        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        print("HTTP Status Code: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            if let responseBody = String(data: data, encoding: .utf8) {
                print("Server Error Response: \(responseBody)")
            }
            throw NetworkError.error(from: httpResponse.statusCode)
        }

        // Manually parse the JSON response
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let postDict = jsonObject["post"] as? [String: Any] {
                
                let post = Post(
                    _id: postDict["_id"] as? String ?? "",
                    userId: postDict["userId"] as? String ?? "",
                    imageUrl: postDict["imageUrl"] as? String ?? "",
                    timestamp: postDict["timestamp"] as? String ?? "",
                    review: postDict["review"] as? String ?? "",
                    location: postDict["location"] as? String ?? "",
                    restaurantName: postDict["restaurantName"] as? String ?? "",
                    likes: postDict["likes"] as? Int ?? 0,
                    likedBy: postDict["likedBy"] as? [String] ?? [],
                    starRating: postDict["starRating"] as? Int ?? 0,
                    comments: postDict["comments"] as? [Comment] ?? []
                )
                
                print("Manually Parsed Post: \(post)")
                
                // Post a notification to trigger addAnnotation in MapView
                
                
                print("getting post rn")
                
                
                
                return post
            } else {
                throw NetworkError.decodingError
            }
        } catch {
            print("JSON parsing error: \(error.localizedDescription)")
            throw NetworkError.decodingError
        }
    }
    
    func userFeed(userId: String) async throws -> [Post] {
        let endpoint = "\(baseURL)/user/getFeed/\(userId)"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse // Provide a custom error for invalid responses
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.error(from: httpResponse.statusCode)
        }

        if let rawJSON = String(data: data, encoding: .utf8) {
            print("Raw JSON Response from /getFeed: \(rawJSON)")
        }

        do {
            // Decode the array of posts directly
            let posts = try JSONDecoder().decode([Post].self, from: data)
            print("Decoded Posts: \(posts)")
            return posts
        } catch {
            print("Error decoding posts: \(error)")
            throw NetworkError.decodingError
        }
    }




    // Helper function to fetch a single post by ID
    func fetchPostDetails(postId: String) async throws -> Post {
        let endpoint = "\(baseURL)/post/\(postId)"
        guard let url = URL(string: endpoint) else {
            print("Invalid URL for post ID: \(postId)")
            throw NetworkError.invalidURL
        }

        print("Fetching details for post ID: \(postId)") // Log start of fetch

        let (data, response) = try await URLSession.shared.data(from: url)

        // Properly extract the HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            print("No HTTP response for post ID: \(postId)")
            throw NetworkError.invalidResponse
        }

        // Validate the HTTP response status
        guard (200...299).contains(httpResponse.statusCode) else {
            print("Failed to fetch details for post ID: \(postId). HTTP Status: \(httpResponse.statusCode)")
            throw NetworkError.error(from: httpResponse.statusCode)
        }

        do {
            let post = try JSONDecoder().decode(Post.self, from: data)
            print("Successfully fetched details for post ID: \(postId) -> \(post)")
            return post
        } catch {
            print("Decoding error for post ID \(postId): \(error.localizedDescription)")
            throw NetworkError.decodingError
        }
    }

      
    func getPostById(postId: String) async throws -> Post {
        let endpoint = "\(baseURL)/posts/\(postId)"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw NetworkError.badRequest("Post not found")
            }
            throw NetworkError.error(from: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(Post.self, from: data)
    }
    


    
    
    
    func fetchPostDetailsFromFeed(userId: String) async throws -> [(Post, User)] {
        let endpoint = "\(baseURL)/user/getPostDetailsFromFeed/\(userId)"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }

        print("Fetching post details from feed for user ID: \(userId)")
        
        
        print("Fetching from URL: \(url)")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.error(from: httpResponse.statusCode)
        }
        
        print("Yay1")

        do {
            // Decode the response into an array of Post objects
            print(try JSONDecoder().decode([Post].self, from: data))
            let posts = try JSONDecoder().decode([Post].self, from: data)
            
            print("Successfully fetched post details: \(posts)")

            // Fetch user details for each post
            var postUserPairs: [(Post, User)] = []
            print("Yay2")

            try await withThrowingTaskGroup(of: (Post, User)?.self) { group in
                for post in posts {
                    group.addTask {
                        do {
                            let user = try await self.getCurrentUser(userId: post.userId)
                            return (post, user)
                        } catch {
                            print("Failed to fetch user for post ID: \(post.id) - Error: \(error)")
                            return nil
                        }
                    }
                }

                for try await pair in group {
                    if let pair = pair {
                        postUserPairs.append(pair)
                    }
                }
            }
            print("Yay3")
            return postUserPairs
            
        } catch {
            throw NetworkError.decodingError
        }
    }


    func likeThePost(postId: String, likerId: String) async throws -> Post {
        let endpoint = "\(baseURL)/posts/\(postId)/like/\(likerId)"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST" // Ensure the method matches the backend route
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw NetworkError.badRequest("Post not found")
            }
            throw NetworkError.error(from: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(Post.self, from: data)
    }
    
    func deletePost(postId: String) async throws {
            let endpoint = "\(baseURL)/post/\(postId)"
            guard let url = URL(string: endpoint) else {
                throw NetworkError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.error(from: httpResponse.statusCode)
            }
        }


    // Upload Profile Image
    struct UploadResponse: Decodable {
        let message: String
        let profilePicture: String
    }

    func uploadProfilePic(userId: String, image: UIImage) async throws -> String {
        let endpoint = "\(baseURL)/user/\(userId)/profile-pic/"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let imageData = image.jpegData(compressionQuality: 0.8)
        guard let imageData = imageData else {
            throw NetworkError.invalidRequest("Invalid image data")
        }

        let httpBody = createMultipartBody(with: imageData, boundary: boundary, fieldName: "image", fileName: "profile-pic.jpg")
        request.httpBody = httpBody

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw NetworkError.badRequest("User not found")
            }
            throw NetworkError.error(from: httpResponse.statusCode)
        }

        // Decode the response and extract the profilePicture URL
        let responseDecoded = try JSONDecoder().decode(UploadResponse.self, from: data)
        return responseDecoded.profilePicture
    }

    // Helper function to create multipart body
    private func createMultipartBody(with data: Data, boundary: String, fieldName: String, fileName: String) -> Data {
        var body = Data()
        let lineBreak = "\r\n"
        
        // Add boundary
        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append(data)
        body.append("\(lineBreak)--\(boundary)--\(lineBreak)".data(using: .utf8)!)
        
        return body
    }



    
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


    
}

extension NSNotification.Name {
    static let postAdded = NSNotification.Name("postAdded")
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
    let loggedIn: Bool
    
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

struct Post: Codable, Identifiable {
    let _id: String
    var id: String { _id }
    let userId: String
    let imageUrl: String
    let timestamp: String // ISO 8601 string
    let review: String
    let location: String
    let restaurantName: String
    var likes: Int
    var likedBy: [String]
    let starRating: Int
    var comments: [Comment]
    var date: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: timestamp)
    }
}



