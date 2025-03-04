import SwiftUI
import Photos
import AVFoundation

struct WelcomeView: View {
    @State private var textScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0.0
    var body: some View {
        NavigationView {
            VStack(spacing:10) {
                
                HStack(spacing: 0) {
                    Image("transparentLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                    
                    Text("FindMyFood")
                        .font(.system(.largeTitle, design: .serif))
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                }
                    .scaleEffect(textScale) // Scale effect for animation
                    .opacity(textOpacity)   // Opacity for fade-in effect
                    .onAppear {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.5, blendDuration: 1)) {
                            textScale = 1.0
                        }
                        withAnimation(.easeIn(duration: 1)) {
                            textOpacity = 1.0
                        }
                        requestPermissions()
                    }
                
                NavigationLink(destination: LoginView()) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(Color.customOrange)
                        .cornerRadius(10)
                }
                
                NavigationLink(destination: SignUpView()) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.clear)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 1)
                        )
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.customOrange)
            .navigationBarHidden(true)
        }
    }
    
    private func requestPermissions() {
           PHPhotoLibrary.requestAuthorization { status in
               switch status {
               case .authorized:
                   print("Photo Library access granted.")
               case .denied, .restricted, .notDetermined:
                   print("Photo Library access not granted.")
               case .limited:
                   print("Photo Library access is limited. Only selected photos are accessible.")
                       // Optionally, show an alert to suggest enabling full access
                       DispatchQueue.main.async {
                           showLimitedAccessAlert()
                       }
               @unknown default:
                   print("Unknown Photo Library status.")
               }
           }
        
           AVCaptureDevice.requestAccess(for: .video) { granted in
               if granted {
                   print("Camera access granted.")
               } else {
                   print("Camera access denied.")
               }
           }
       }
    private func showLimitedAccessAlert() {
        let alert = UIAlertController(
            title: "Limited Access",
            message: "You have granted limited access to your photo library. To use all features, please allow full access in Settings.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Find the topmost view controller in iOS 15+
        if let topController = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController {
            
            // Present the alert from the topmost view controller
            var currentController = topController
            while let presented = currentController.presentedViewController {
                currentController = presented
            }
            currentController.present(alert, animated: true)
        }
    }

}

//Preview Provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
