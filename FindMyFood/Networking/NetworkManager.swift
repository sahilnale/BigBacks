import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "http://localhost:8080/api/v1/user"
    
    private init() {}
    
    func login(username: String, password: String) async throws -> User {
        let endpoint = "\(baseURL)/login"
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
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            }
            throw NetworkError.error(from: httpResponse.statusCode)
        }
        
        let loginResponse = try JSONDecoder().decode([String: String].self, from: data)
            guard let userId = loginResponse["userId"] else {
                throw NetworkError.badRequest("User ID not found in response")
            }
        
        return try await getCurrentUser(userId: userId)
    }
    
    func getCurrentUser(userId: String) async throws -> User {
        let endpoint = "\(baseURL)/\(userId)"
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
        let endpoint = "\(baseURL)/"
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
    
}


// MARK: - Models
struct User: Codable, Identifiable {
    let id: String
    let name: String
    let username: String
    let email: String
    //let profilePicture: String?
    let friends: [String]
    let friendRequests: [String]
    let pendingRequests: [String]
    let posts: [Post]
    let loggedIn: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"  // Map _id to id
        case name
        case username
        case email
        case friends
        case friendRequests
        case pendingRequests
        case posts
        case loggedIn
    }
}


struct Post: Codable, Identifiable {
    let id: String
    let imageUrl: String
    let timestamp: Date
    let review: String
    let location: String
    let restaurantName: String
}
