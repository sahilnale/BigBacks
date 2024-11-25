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
