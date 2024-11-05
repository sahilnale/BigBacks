import Foundation

struct Review: Identifiable {
    let id = UUID()
    let userName: String
    let rating: Int
    let text: String
    let image: String
}
