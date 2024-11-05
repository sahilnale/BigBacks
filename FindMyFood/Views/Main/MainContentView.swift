import SwiftUI

struct MainContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        if authViewModel.isLoggedIn {
            MainTabView()
        } else {
            WelcomeView()
                .environmentObject(authViewModel)
        }
    }
}
