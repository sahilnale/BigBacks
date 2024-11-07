import SwiftUI

struct FriendsView: View {
    var body: some View {
        NavigationView {
            
            VStack {
                
                Button(action: {
                }) {
                    Text("View Requests")
                        .font(.headline)
                    
                }
                
                
                List {
                    ForEach(0..<5) { _ in
                        HStack {
                            
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                            VStack(alignment: .leading) {
                                Text("Friend Name")
                                    .font(.headline)
                                Text("@username")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .navigationTitle("Friends")
                
                .navigationBarItems(
                    
                    
                    
                    trailing: Button("Add") {
                        // Implement add friend
                    })
            }
        }
    }
}
