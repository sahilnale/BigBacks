import SwiftUI

struct RestaurantCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            Image("placeholder")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .clipped()
            
            HStack {
                Text("Restaurant Name")
                    .font(.headline)
                Spacer()
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("4.5")
                }
            }
            .padding(.horizontal)
            
            Text("Description of the restaurant or recent review...")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}
