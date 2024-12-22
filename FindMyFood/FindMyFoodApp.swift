import SwiftUI
import FirebaseCore

// Firebase App Delegate for initialization
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct FindMyFoodApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate // Register Firebase AppDelegate
    @StateObject private var authViewModel = AuthViewModel.shared // Use the shared instance
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .tint(Color(red: 240/255, green: 116/255, blue: 84/255))
            }
            .environmentObject(authViewModel)
            .onAppear {
                Task {
                    await authViewModel.loadCurrentUser()
                }
            }
        }
    }
}
