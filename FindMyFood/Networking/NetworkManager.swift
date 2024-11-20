import Foundation

// MARK: - Custom URLSession Delegate to Ignore SSL Errors
class SelfSignedDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - Network Manager
class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://34.239.184.207:8080/api/v1" // HTTP URL
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: SelfSignedDelegate(), delegateQueue: nil)
    }

    // MARK: - Login
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

        let (data, response) = try await session.data(for: request)

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

    // MARK: - Get Current User
    func getCurrentUser(userId: String) async throws -> User {
        let endpoint = "\(baseURL)/user/\(userId)"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

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

    // MARK: - Sign Up
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

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 409 {
                throw NetworkError.badRequest("Email or username already exists")
            }
            throw NetworkError.error(from: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(User.self, from: data)
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

