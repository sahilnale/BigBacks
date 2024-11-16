import SwiftUI

struct MainView: View {
    private let mapViewModel = MapViewModel() // Create an instance of MapViewModel
    
    var body: some View {
        ZStack {
            // MapView with the MapViewModel
            MapView(viewModel: mapViewModel)
                .edgesIgnoringSafeArea(.all)
            
            // Overlay UI
            VStack {
                Spacer() // Push buttons to the bottom
                
                HStack {
                    Spacer()
                    
                    VStack(spacing: 15) {
                        // Recenter Button
                        Button(action: {
                            // Call the recenterMap method on the MapViewModel
                            mapViewModel.recenterMap()
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
                        NavigationLink(destination: CreatePostView()) {
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
