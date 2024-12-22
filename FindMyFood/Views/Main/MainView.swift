import SwiftUI


struct MainView: View {
    private let mapViewModel = MapViewModel()
    @Binding var selectedTab: Int
    @State private var showCreatePost = false // Tracks whether to show CreatePostView

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
                        Button(action: {
                            showCreatePost = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 30))
                                .foregroundColor(.accentColor)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .sheet(isPresented: $showCreatePost) {
                            NavigationStack {
                                CreatePostView(selectedTab: $selectedTab)
                                
                            }
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}
