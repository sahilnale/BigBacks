import SwiftUI

struct MainView: View {
    var body: some View {
        ZStack {
            // Background: Your existing MapView
            MapView()
                .edgesIgnoringSafeArea(.all)
            
            // Overlay UI Elements
            VStack {
                Spacer() // Push buttons to the bottom
                
                HStack {
                    Spacer()
                    
                    VStack(spacing: 15) {
                        // Recenter Button
                        Button(action: {
                            // Action to trigger recentering (to be implemented)
                            print("Recenter button tapped")
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        
                        // Add Button
                        Button(action: {
                            print("Add button tapped")
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 30))
                                .foregroundColor(.accentColor)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

