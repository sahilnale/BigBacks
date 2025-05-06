import SwiftUI
import FirebaseAuth

struct VerifyEmailView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var name: String
    var username: String
    var email: String
    var password: String
    var profileImageData: Data? // Pass the image data

    @State private var isEmailVerified = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var shouldNavigateToApp = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Verify Your Email")
                    .font(.system(.largeTitle, design: .serif))
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)

                Text("We’ve sent a verification email to \(email). Please verify your account to continue.")
                    .multilineTextAlignment(.center)
                    .padding()

                if isLoading {
                    ProgressView("Verifying...")
                } else if isEmailVerified {
                    Text("Email verified! You can now proceed.")
                        .foregroundColor(.green)
                        .font(.headline)
                }

                Spacer()

                Button("Resend Verification Email") {
                    resendVerificationEmail()
                }
                .font(.headline)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)

            }
            .padding()
            .onAppear {
                createUserAndSendVerification()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func createUserAndSendVerification() {
        isLoading = true // Start loading
        authViewModel.createUser(
            name: name,
            username: username,
            email: email,
            password: password
        ) { success, error in
            isLoading = false // Stop loading
            if let error = error {
                showError = true
                errorMessage = error.localizedDescription
            } else if success {
                checkEmailVerification()
            }
        }
    }

    private func resendVerificationEmail() {
        Task {
            do {
                try await Auth.auth().currentUser?.sendEmailVerification()
                print("Verification email resent successfully.")
            } catch {
                showError = true
                errorMessage = error.localizedDescription
                print("Failed to resend verification email: \(error.localizedDescription)")
            }
        }
    }

    private func checkEmailVerification() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
            Auth.auth().currentUser?.reload { error in
                if let error = error {
                    // Log reload error to Xcode console
                    print("Reload Error: \(error.localizedDescription)")
                    showError = true
                    errorMessage = "Error reloading user: \(error.localizedDescription)"
                    return
                }

                // Check if the email is verified
                if Auth.auth().currentUser?.isEmailVerified == true {
                    isEmailVerified = true
                    timer.invalidate() // Stop checking once verified
                    print("Email verified successfully.")

                    guard let userId = Auth.auth().currentUser?.uid else {
                        showError = true
                        errorMessage = "Authentication failed. User ID is nil."
                        print("Error: Authenticated User ID is nil.")
                        return
                    }
                    print("Authenticated User ID: \(userId)")

                    // Save user details in Firestore
                    authViewModel.updateFirestoreUser(
                        userId: userId,
                        name: name,
                        username: username,
                        email: email,
                        profileImageData: profileImageData
                    ) { success in
                        if success {
                            print("User successfully updated in Firestore.")
                            DispatchQueue.main.async {
                                // Navigate to the main app view
                                shouldNavigateToApp = true
                            }
                        } else {
                            showError = true
                            errorMessage = "Failed to update user in Firestore. Please try again."
                            print("Firestore Update Error: \(authViewModel.error ?? "Unknown error")")
                        }
                    }
                } else {
                    // Log that email verification is still pending
                    print("Email is not yet verified. Waiting for user to verify.")
                }
            }
        }
    }
}



//struct VerifyEmailView_Previews: PreviewProvider {
//    static var previews: some View {
//        VerifyEmailView(name: <#String#>, username: <#String#>, email: <#String#>, password: <#String#>)
//            .environmentObject(AuthViewModel()) // Provide required environment object
//            .previewLayout(.device) // Preview on a device layout
//            .padding()
//            .background(Color.black.edgesIgnoringSafeArea(.all)) // Dark background for better contrast
//    }
//}

import SwiftUI

struct SpinnerView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Outer Rotating Ring
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.red.opacity(0.6),
                            Color.accentColor.opacity(0.4),
                            Color.red.opacity(0.6)
                        ]),
                        center: .center
                    ),
                    lineWidth: 5
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 2.0)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )

            // Middle Rotating Ring
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.red.opacity(0.8),
                            Color.accentColor,
                            Color.red.opacity(0.8)
                        ]),
                        center: .center
                    ),
                    lineWidth: 6
                )
                .frame(width: 110, height: 110)
                .rotationEffect(.degrees(isAnimating ? -360 : 0)) // Opposite direction
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )

            // Inner Rotating Ring
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.accentColor,
                            Color.red,
                            Color.accentColor
                        ]),
                        center: .center
                    ),
                    lineWidth: 8
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1.0)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )

            // Inner Glowing Core
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.accentColor.opacity(0.8),
                            Color.red.opacity(0.3)
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 50
                    )
                )
                .frame(width: 50, height: 50)
                .shadow(color: Color.red.opacity(0.7), radius: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it stays centered
        .onAppear {
            isAnimating = true
        }
    }
}

