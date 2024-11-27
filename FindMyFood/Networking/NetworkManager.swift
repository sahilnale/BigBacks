import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://api.bigbacksapp.com/api/v1"
    
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
    func addPost(
        userId: String,
        imageUrl: String,
        review: String,
        location: String,
        restaurantName: String
    ) async throws -> Post {
        let endpoint = "\(baseURL)/post/upload/\(userId)"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the body with the required fields
        let body: [String: Any] = [
            "imageUrl": imageUrl,
            "review": review,
            "location": location,
            "restaurantName": restaurantName
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("HTTP Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw NetworkError.badRequest("User not found")
            }
            throw NetworkError.error(from: httpResponse.statusCode)
        }
        
        if let dataString = String(data: data, encoding: .utf8) {
            print("Raw Response JSON: \(dataString)")
        }
        
        // Manually parse the JSON response
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let postDict = jsonObject["post"] as? [String: Any] {
                
                let post = Post(
                    _id: postDict["_id"] as? String ?? "",
                    imageUrl: postDict["imageUrl"] as? String ?? "",
                    timestamp: postDict["timestamp"] as? String ?? "",
                    review: postDict["review"] as? String ?? "",
                    location: postDict["location"] as? String ?? "",
                    restaurantName: postDict["restaurantName"] as? String ?? "",
                    likes: postDict["likes"] as? Int ?? 0,
                    likedBy: postDict["likedBy"] as? [String] ?? [],
                    starRating: postDict["starRating"] as? Int ?? 0,
                    comments: postDict["comments"] as? [String] ?? []
                )
                
                print("Manually Parsed Post: \(post)")
                return post
            } else {
                throw NetworkError.decodingError
            }
        } catch {
            print("JSON parsing error: \(error.localizedDescription)")
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
    
    func getAllPostsByUser(userId: String) async throws -> [Post] {
        let endpoint = "\(baseURL)/users/\(userId)/posts" 
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.error(from: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode([Post].self, from: data) // Decodes an array of posts
    }


    
    func fetchPostDetailsFromFeed(userId: String) async throws -> [Post] {
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

        do {
            // Decode the response into an array of Post objects
            let posts = try JSONDecoder().decode([Post].self, from: data)
            print("Successfully fetched post details: \(posts)")
            return posts
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    

    
    
    
    
    

    
    
    
    
    



    
    
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

struct Post: Codable {
    let _id: String
    let imageUrl: String
    let timestamp: String
    let review: String
    let location: String
    let restaurantName: String
    let likes: Int
    let likedBy: [String]
    let starRating: Int
    let comments: [String]
    
}
