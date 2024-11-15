import SwiftUI

struct MainTabView: View {
    init() {
        UITabBar.appearance().backgroundColor = UIColor.white
    }
    
    var body: some View {
        NavigationView {
            
        TabView {
            ZStack {
                MapView()
                
                // Floating buttons in the bottom-right corner
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            // Recenter Button
                            Button(action: {
                                // Action for the "Recenter" button
                            }) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.accentColor)
                                    .padding()
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 10)
                            }
                            .offset(x: 2) // Move the button slightly to the right
                            
                            // "+" Button
                            
                            NavigationLink(destination: CreatePostView()) {
                                Image(systemName: "plus")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.accentColor)
                                    .clipShape(Circle())
                                    .shadow(radius: 10)
                            }
                                    
                        
                                
                            }
                        }
                        .padding(.bottom, 10)
                        .padding(.trailing, 10)
                    }
                }
            }
            .tabItem {
                Label("Explore", systemImage: "map")
            }
            
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "list.bullet")
                }
            
            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "person.2")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .accentColor(.accentColor)
    }
}

// MARK: - Preview
//struct MainTabView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainTabView()
//    }
//}
