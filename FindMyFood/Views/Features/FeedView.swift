import SwiftUI

struct FeedView: View {
    var body: some View {
        NavigationView {
            List {
                ForEach(0..<10) { _ in
                    RestaurantCard()
                }
            }
            .navigationTitle("Feed")
            .navigationBarItems(trailing: Button(action: {
                // Implement search
            }) {
                Image(systemName: "magnifyingglass")
            })
            
        }
        
    }
}
