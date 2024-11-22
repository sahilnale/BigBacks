import SwiftUI

struct WelcomeView: View {
    @State private var textScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0.0
    var body: some View {
        NavigationView {
            VStack(spacing:10) {
                Text("FindMyFood")
                    .font(.system(.largeTitle, design: .serif))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .scaleEffect(textScale) // Scale effect for animation
                    .opacity(textOpacity)   // Opacity for fade-in effect
                    .onAppear {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.5, blendDuration: 1)) {
                            textScale = 1.0
                        }
                        withAnimation(.easeIn(duration: 1)) {
                            textOpacity = 1.0
                        }
                    }
                    .padding()
                
                NavigationLink(destination: LoginView()) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(Color.accentColor)
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
            .background(Color.accentColor)
            .navigationBarHidden(true)
        }
    }
}

// Preview Provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
