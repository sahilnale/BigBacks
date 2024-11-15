import SwiftUI

@main
struct FindMyFoodApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
            .environmentObject(authViewModel)
        }
    }
}
