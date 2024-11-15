import SwiftUI

struct MainTabView: View {
    init() {
        UITabBar.appearance().backgroundColor = UIColor.white
    }
    
    var body: some View {
        NavigationView {
            
            TabView {
                ZStack {
                    MainView()
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
}


struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
