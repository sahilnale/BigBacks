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
