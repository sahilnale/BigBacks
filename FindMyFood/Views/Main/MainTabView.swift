import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @EnvironmentObject var authViewModel: AuthViewModel // Fetch from environment

    init() {
        UITabBar.appearance().backgroundColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
        }
    }

    var body: some View {
       // NavigationView {
            
//             TabView(selection: $selectedTab) {
//                 ZStack {
//                     MainView(selectedTab: $selectedTab)
//                 }
      //CHECK THIS JUST IN CASE
        TabView(selection: $selectedTab) {
            // Main Map View
            MainView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Explore", systemImage: "map")
                }
                .tag(0)

                FeedView()
                    .tabItem {
                        Label("Feed", systemImage: "list.bullet")
                    }
                    .tag(1)
            

            // Friends View
            FriendsView(authViewModel: authViewModel)
                .tabItem {
                    Label("Friends", systemImage: "person.2")
                }
                .tag(2)

            // Profile View
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(3)
        }
        .accentColor(.customOrange)
       // .navigationBarBackButtonHidden(true)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthViewModel()) // Inject a sample `AuthViewModel` for preview
    }
}
