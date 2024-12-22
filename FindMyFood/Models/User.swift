//
//  User.swift
//  FindMyFood
//
//  Created by Sahil Nale on 12/21/24.
//
import Foundation

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let username: String
    let email: String
    var friends: [String]
    var friendRequests: [String]
    var pendingRequests: [String]
    var posts: [String]
    var profilePicture: String?
    var loggedIn: Bool

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "username": username,
            "email": email,
            "friends": friends,
            "friendRequests": friendRequests,
            "pendingRequests": pendingRequests,
            "posts": posts,
            "profilePicture": profilePicture as Any,
            "loggedIn": loggedIn
        ]
    }
}
