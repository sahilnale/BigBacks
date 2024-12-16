import SwiftUI

struct MainView: View {
    private let mapViewModel = MapViewModel() // Create an instance of MapViewModel
    @Binding var selectedTab: Int
    var body: some View {
        ZStack {
            // MapView with the MapViewModel
            MapView(viewModel: mapViewModel)
                .edgesIgnoringSafeArea(.all)
            VStack {
                HStack(spacing: 0) {
                    Image("orangeLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .padding(.leading, 10)
                        .padding(.top, 40)
                    
                    Text("FindMyFood")
                        .font(.system(.title2, design: .serif))
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                        .padding(.top, 40)
                    Spacer()
                }
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
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
                        NavigationLink(destination: CreatePostView(selectedTab: $selectedTab)) {
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

//#Preview {
//    MainView()
//}
