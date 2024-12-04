import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case invalidResponse
    case invalidRequest(String)
    case serverError(String)
    case unauthorized
    case badRequest(String)
    case noInternet
    case invalidCredentials
    case userNotFound
    case emailAlreadyExists
    case usernameAlreadyExists
    case weakPassword
    case invalidEmail
    
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL. Please try again."
        case .invalidRequest(let message):
            return "Invalid Request. Please try again."
        case .noData:
            return "No data received from the server"
        case .decodingError:
            return "Error processing server response"
        case .invalidResponse:
            return "Invalid response from the server"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unauthorized:
            return "Please log in to continue"
        case .badRequest(let message):
            return "Error: \(message)"
        case .noInternet:
            return "No internet connection. Please check your connection and try again."
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .usernameAlreadyExists:
            return "This username is already taken"
        case .weakPassword:
            return "Password is too weak. Please use at least 8 characters with a mix of letters, numbers, and symbols."
        case .invalidEmail:
            return "Please enter a valid email address"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .serverError(let message):
            return message
        case .badRequest(let message):
            return message
        case .weakPassword:
            return "Password requirements not met"
        case .invalidEmail:
            return "Email format is invalid"
        default:
            return nil
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noInternet:
            return "Check your internet connection and try again"
        case .unauthorized:
            return "Please log in again"
        case .invalidCredentials:
            return "Double-check your email and password"
        case .weakPassword:
            return "Use at least 8 characters, including uppercase, lowercase, numbers, and special characters"
        case .emailAlreadyExists:
            return "Try logging in instead, or use a different email"
        case .usernameAlreadyExists:
            return "Please choose a different username"
        default:
            return nil
        }
    }
    
    static func error(from statusCode: Int, message: String? = nil) -> NetworkError {
        switch statusCode {
        case 400:
            return .badRequest(message ?? "Invalid request")
        case 401:
            return .invalidCredentials
        case 403:
            return .unauthorized
        case 404:
            return .userNotFound
        case 409:
            if message?.contains("email") ?? false {
                return .emailAlreadyExists
            } else if message?.contains("username") ?? false {
                return .usernameAlreadyExists
            }
            return .badRequest(message ?? "Resource already exists")
        case 422:
            if message?.contains("password") ?? false {
                return .weakPassword
            } else if message?.contains("email") ?? false {
                return .invalidEmail
            }
            return .badRequest(message ?? "Validation failed")
        case 500...599:
            return .serverError(message ?? "Server error occurred")
        default:
            return .serverError(message ?? "Unknown error occurred")
        }
    }
}

// MARK: - Error Handling Extension
extension NetworkError {
    static func handle(_ error: Error) -> NetworkError {
        switch error {
        case is URLError:
            let urlError = error as! URLError
            switch urlError.code {
            case .notConnectedToInternet:
                return .noInternet
            case .timedOut:
                return .serverError("Request timed out")
            default:
                return .serverError(urlError.localizedDescription)
            }
        case is DecodingError:
            return .decodingError
        case let networkError as NetworkError:
            return networkError
        default:
            return .serverError(error.localizedDescription)
        }
    }
}
