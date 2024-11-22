import SwiftUI

struct MainTabView: View {
    init() {
        UITabBar.appearance().backgroundColor = UIColor { traitCollection in
                    return traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
        }
    }
    @State private var selectedTab: Int = 0
    
    var body: some View {
        NavigationView {
            
            TabView(selection: $selectedTab) {
                ZStack {
                    MainView(selectedTab: $selectedTab)
                }
                .tabItem {
                    Label("Explore", systemImage: "map")
                }.tag(0)
                
                FeedView()
                    .tabItem {
                        Label("Feed", systemImage: "list.bullet")
                    }.tag(1)
                
                FriendsView()
                    .tabItem {
                        Label("Friends", systemImage: "person.2")
                    }.tag(2)
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                    }.tag(3)
            }
            .accentColor(.accentColor)
        }
        .navigationBarBackButtonHidden(true)
    }
}


struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
