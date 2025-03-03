import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    if let error = error {
                        print("Failed to request authorization: \(error)")
                    } else if granted {
                        print("Authorization granted")
                         DispatchQueue.main.async {
                            application.registerForRemoteNotifications()
                        }
                    }
                }
            } else {
                print("Notification permissions already determined.")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }

        // Set the Messaging delegate
        Messaging.messaging().delegate = self

        // Force token refresh at app startup
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM token: \(error)")
            } else if let token = token {
                print("Fetched initial FCM token: \(token)")
                Task {
                    await self.updateFCMToken(token)
                }
            }
        }

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        #if DEBUG
        Messaging.messaging().setAPNSToken(deviceToken, type: .sandbox)
        #else
        Messaging.messaging().setAPNSToken(deviceToken, type: .prod)
        #endif
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

        do {
            let db = Firestore.firestore()
            let userDoc = try await db.collection("users").document(userId).getDocument()

            if userDoc.exists {
                if let existingToken = userDoc.get("fcmToken") as? String, existingToken == fcmToken {
                    print("FCM token is already up-to-date.")
                } else {
                    try await db.collection("users").document(userId).setData(["fcmToken": fcmToken], merge: true)
                    print("FCM token updated in Firestore for user: \(userId)")
                }
            } else {
                // Create the document if it doesn't exist
                try await db.collection("users").document(userId).setData(["fcmToken": fcmToken], merge: true)
                print("FCM token document created for user: \(userId)")
            }
        } catch {
            print("Failed to update FCM token in Firestore for user: \(userId) - Error: \(error.localizedDescription)")
        }
    }

    // Handle when notifications are received while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // Handle when a notification is tapped
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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel.shared

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
