import SwiftUI

struct CreatePostView: View {
    
    @State private var restaurantName: String = ""
        @State private var reviewText: String = ""
        @State private var rating: Int = 0 // Define the rating state here
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .cornerRadius(10)
            
            Text("Search for restaurants..")
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            HStack {
                ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                        .foregroundColor(index <= rating ? .orange : .gray)
                        .onTapGesture {
                        rating = index
                            }
                    }
                }
            
            // Review Text Editor
                            TextEditor(text: $reviewText)
                                .frame(height: 100)
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(10)
                                .padding(.horizontal)
                                .overlay(
                                    Text(reviewText.isEmpty ? "write your review...." : "")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 8),
                                    alignment: .topLeading
                                )
                            
                            // Post Button
                            Button(action: {
                                // Post action
                                print("Post submitted")
                            }) {
                                Text("Post")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                            
                            Spacer()
                        }
                        .navigationTitle("Add Post")
                        .navigationBarTitleDisplayMode(.inline)
//                        .navigationBarItems(leading: Button(action: {
//                            // Back action
//                        }) {
//                            Image(systemName: "arrow.left")
//                                .foregroundColor(.black)
//                        })
                    }
                }


 //MARK: - Preview
       
            
            
            
       
