import SwiftUI

struct FeedView: View {
    @State private var navigateToMain = false
    var body: some View {
        NavigationView {
            List {
                ForEach(0..<10) { _ in
                    RestaurantCard()
                }
            }
            .navigationTitle("Feed")
            
        }
        .navigationBarBackButtonHidden(true)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button(action: {
//                    // Action for the back button
//                    navigateToMain = true
//                }) {
//                    HStack {
//                        Image(systemName: "chevron.backward")
//                        Text("Back")
//                    }
//                    .foregroundColor(.accentColor)
//                }
//            }
//        }
    }
}

//#Preview {
//    FeedView()
//}
