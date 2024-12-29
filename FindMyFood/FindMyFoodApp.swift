import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import FirebaseAuth
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Failed to request authorization: \(error)")
            } else if granted {
                print("Authorization granted")
            }
        }

        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM Token: \(fcmToken ?? "")")
        Task {
            await updateFCMToken(fcmToken)
        }
    }

    func updateFCMToken(_ fcmToken: String?) async {
        guard let userId = Auth.auth().currentUser?.uid, let fcmToken = fcmToken else {
            print("User not logged in or FCM token is nil.")
            return
        }

        await MainActor.run { // Ensure this runs on the main actor
            do {
                let db = Firestore.firestore()
                try db.collection("users").document(userId).setData(["fcmToken": fcmToken], merge: true)
                print("FCM token updated in Firestore")
            } catch {
                print("Failed to update FCM token in Firestore: \(error)")
                if let error = error as NSError? {
                    print("Firestore Error Code: \(error.code), Domain: \(error.domain), UserInfo: \(error.userInfo)")
                }
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("Notification tapped with payload: \(userInfo)")
        completionHandler()
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
