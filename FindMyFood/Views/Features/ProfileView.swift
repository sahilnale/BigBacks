import SwiftUI

struct ProfileView: View {
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 100))
                Text("Name")
                    .font(.headline)
                Text("@username")
                    .font(.subheadline)
                
                // Light grey rounded box containing the 4x3 grid
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemGray5))
                    .frame(height: 400) // Adjust height to fit 4 rows comfortably
                    .overlay(
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(0..<12) { _ in
                                Image(systemName: "person.circle.fill") // Replace with user's image array
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding()
                    )
                    .padding()
                
                // Add more views as needed
            }
            .navigationTitle("Profile")
            .navigationBarItems(trailing: NavigationLink(destination: EditProfileView()) {
                Image(systemName: "pencil")
                    .font(.system(size: 20)) // Customize size of the pencil icon
            })
        }
    }
}
