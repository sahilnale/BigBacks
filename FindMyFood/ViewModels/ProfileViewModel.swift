//
//  Untitled.swift
//  FindMyFood
//
//  Created by Ridhima Morampudi on 11/24/24.
//

import Foundation

class ProfileViewModel: ObservableObject {
    @Published var name: String = "Loading..."
    @Published var username: String = "Loading..."
    @Published var errorMessage: String? = nil

    func loadProfile() async {
        guard let userId = AuthManager.shared.userId else {
            errorMessage = "User is not logged in."
            return
        }

        do {
            let user = try await NetworkManager.shared.getCurrentUser(userId: userId)
            DispatchQueue.main.async {
                self.name = user.name
                self.username = user.username
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
            }
        }
    }
}
