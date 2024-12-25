import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import FirebaseAuth
import FirebaseFirestore

// Firebase App Delegate for initialization
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()

        // Set up Notification Center Delegate
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Failed to request authorization: \(error)")
            } else if granted {
                print("Authorization granted")
            }
        }

        // Register for remote notifications
        application.registerForRemoteNotifications()

        // Set Firebase Messaging delegate
        Messaging.messaging().delegate = self

        return true
    }

    // Called when the app successfully registers for push notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Set the APNs token in Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
    }

    // Firebase Messaging Delegate: Called when a new FCM token is generated
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM Token: \(fcmToken ?? "")")

        // Save the FCM token to Firestore for the current user
        Task {
            await saveFCMTokenToFirestore(fcmToken)
        }
    }

    // Save the FCM token to Firestore
    func saveFCMTokenToFirestore(_ fcmToken: String?) async {
        guard let userId = Auth.auth().currentUser?.uid, let fcmToken = fcmToken else { return }
        let db = Firestore.firestore()
        do {
            try await db.collection("users").document(userId).updateData(["fcmToken": fcmToken])
            print("FCM token updated in Firestore")
        } catch {
            print("Failed to update FCM token in Firestore: \(error)")
        }
    }

    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // Handle when a user taps a notification
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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate // Register the updated AppDelegate
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
