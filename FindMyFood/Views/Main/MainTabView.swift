import SwiftUI

struct MainTabView: View {
    init() {
        UITabBar.appearance().backgroundColor = UIColor { traitCollection in
                    return traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
        }
    }
    @State private var selectedTab: Int = 0
    
    var body: some View {
       // NavigationView {
            
            TabView(selection: $selectedTab) {
                ZStack {
                    MainView(selectedTab: $selectedTab)
                }
                .tabItem {
                    Label("Explore", systemImage: "map")
                }.tag(0)
                
                if let userId = AuthManager.shared.userId {
                    FeedView()
                        .tabItem {
                            Label("Feed", systemImage: "list.bullet")
                        }.tag(1)
                } else {
                    Text("Please log in to view your feed.")
                        .tabItem {
                            Label("Feed", systemImage: "list.bullet")
                        }.tag(1)
                }

                
                FriendsView(currentUserId: "account123") //should this be userId??
                    .tabItem {
                        Label("Friends", systemImage: "person.2")
                    }.tag(2)
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                    }.tag(3)
            }
            .accentColor(.customOrange)
       // }
       // .navigationBarBackButtonHidden(true)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
