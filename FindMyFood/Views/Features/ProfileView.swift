import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // Inject the AuthViewModel instance
    @StateObject private var viewModel = ProfileViewModel()
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView{
                VStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 100))
//                    Text("Name")
//                        .font(.headline)
//                    Text("@username")
//                        .font(.subheadline)
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                    } else {
                        Text(viewModel.name)
                        .font(.headline)
                        Text("@\(viewModel.username)")
                        .font(.subheadline)
                    }
                    
                    // Light grey rounded box containing the 4x3 grid of posts
                    // Removed the RoundedRectangle container to avoid the big grey box
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(0..<12) { index in
                            NavigationLink(destination: PostDetailView(postId: index)) {
                                Rectangle() // Rectangle as placeholder for posts
                                    .fill(Color.gray.opacity(0.4)) // Background color for the rectangle
                                    .frame(height: 81) // Height of the rectangle
                                    .cornerRadius(10) // Rounded corners for the rectangle
                                                }
                                    .buttonStyle(PlainButtonStyle()) // Remove the default button style of NavigationLink
                        }
                    }
                    .padding()
                                
                    .padding()
                    Spacer()
                    
                    // Logout Button
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        Text("Logout")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(minWidth: 40, maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
                            .background(Color.accentColor)
                            .cornerRadius(10)
                            .padding()
                    }
                }
                .navigationTitle("Profile")
                .navigationBarItems(trailing: NavigationLink(destination: EditProfileView()) {
                    Image(systemName: "pencil")
                        .font(.system(size: 20)) // Customize size of the pencil icon
                })
            }
            .onAppear {
                Task {
                    await viewModel.loadProfile() // Fetch user details when the view appears
                }
            }
        }
    }
}

struct PostDetailView: View {
    var postId: Int // Use the post ID or any unique identifier for the post
    
    var body: some View {
        VStack {
            Text("Post \(postId)") // Placeholder for the actual post content
                .font(.largeTitle)
            // Display more post details here as needed
        }
        .navigationTitle("Post Detail")
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel()) // Ensure the AuthViewModel is passed to the view
}

