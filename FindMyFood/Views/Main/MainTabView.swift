import SwiftUI

struct MainTabView: View {
    init() {
            UITabBar.appearance().backgroundColor = UIColor.white
        }
    var body: some View {
        TabView {
            MapView()
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
        }.accentColor(.accentColor)
    }
}
