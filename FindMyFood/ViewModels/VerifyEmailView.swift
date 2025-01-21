import SwiftUI
import FirebaseAuth

struct VerifyEmailView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 40) {
            // Title
            Text("Verify Your Email")
                .font(.system(.largeTitle, design: .serif))
                .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                    .shadow(color: .accentColor.opacity(0.5), radius: 5, x: 0, y: 2)

            // Instructions
            Text("We’ve sent a verification email to your inbox. Please check your email and verify your account to continue.")
                .multilineTextAlignment(.center)
                .padding()

            // Loading Spinner
            SpinnerView()
            
            Spacer()

            // Resend Email Button
            Button("Resend Verification Email") {
                Task {
                    try? await Auth.auth().currentUser?.sendEmailVerification()
                }
            }
            .font(.system(.headline, design: .serif))
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(25) // Capsule shape
            .shadow(color: .accentColor.opacity(0.5), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 40)
            .padding(.bottom, 50)


            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}
struct VerifyEmailView_Previews: PreviewProvider {
    static var previews: some View {
        VerifyEmailView()
            .environmentObject(AuthViewModel()) // Provide required environment object
            .previewLayout(.device) // Preview on a device layout
            .padding()
            .background(Color.black.edgesIgnoringSafeArea(.all)) // Dark background for better contrast
    }
}

import SwiftUI

struct SpinnerView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Outer Pulsing Ring 3
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
                .scaleEffect(isAnimating ? 1.5 : 1.2)
                .opacity(isAnimating ? 0 : 1)
                .animation(
                    Animation.easeOut(duration: 1.5)
                        .repeatForever(autoreverses: false)
                        .delay(0.6), // Sync delay for outermost ring
                    value: isAnimating
                )

            // Outer Pulsing Ring 2
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
                .scaleEffect(isAnimating ? 1.3 : 1.0)
                .opacity(isAnimating ? 0 : 1)
                .animation(
                    Animation.easeOut(duration: 1.5)
                        .repeatForever(autoreverses: false)
                        .delay(0.3), // Sync delay for this ring
                    value: isAnimating
                )

            // Inner Pulsing Ring 1
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
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .opacity(isAnimating ? 0 : 1)
                .animation(
                    Animation.easeOut(duration: 1.5)
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
        .onAppear {
            isAnimating = true
        }
    }
}

