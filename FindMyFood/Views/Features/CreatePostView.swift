//import SwiftUI
//
//struct CreatePostView: View {
//    
//    @State private var restaurantName: String = ""
//        @State private var reviewText: String = ""
//        @State private var rating: Int = 0
    
    // Define the rating state here
//    var body: some View {
//        VStack(spacing: 20) {
//            Spacer()
//            Image(systemName: "square.fill")
//                .resizable()
//                .scaledToFit()
//                .frame(height: 200)
//                .cornerRadius(10)
//            
//            Text("Search for restaurants...")
//                .padding()
//                .background(Color(UIColor.systemGray6))
//                .cornerRadius(10)
//                .padding(.horizontal)
//            HStack {
//                ForEach(1...5, id: \.self) { index in
//                Image(systemName: index <= rating ? "star.fill" : "star")
//                        .foregroundColor(index <= rating ? .accentColor : .gray)
//                        .onTapGesture {
//                        rating = index
//                            }
//                    }
//                }
//            
//            // Review Text Editor
//                            TextEditor(text: $reviewText)
//                                .frame(height: 100)
//                                .padding()
//                                .background(Color(UIColor.systemGray6))
//                                .cornerRadius(10)
//                                .padding(.horizontal)
//                                .overlay(
//                                    Text(reviewText.isEmpty ? "write your review...." : "")
//                                        .foregroundColor(.gray)
//                                        .padding(.leading, 8),
//                                    alignment: .topLeading
//                                )
//                            
//                            // Post Button
//                            Button(action: {
//                                // Post action
//                                print("Post submitted")
//                            }) {
//                                Text("Post")
//                                    .bold()
//                                    .frame(maxWidth: .infinity)
//                                    .padding()
//                                    .background(Color.orange)
//                                    .foregroundColor(.white)
//                                    .cornerRadius(10)
//                                    .padding(.horizontal)
//                            }
//                            
//                            Spacer()
//                        }
//                        .navigationTitle("Add Post")
//                        .navigationBarTitleDisplayMode(.inline)
////                        .navigationBarItems(leading: Button(action: {
////                            // Back action
////                        }) {
////                            Image(systemName: "arrow.left")
////                                .foregroundColor(.black)
////                        })
//                    }
//                }


import SwiftUI
import PhotosUI
import CoreLocation
import Photos
import Swift
import MapKit

struct CreatePostView: View {
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage? = nil
    @State private var imageLocation: CLLocation? = nil
    @State private var postText: String = ""
    @State private var restaurantName: String = ""
    @State private var reviewText: String = ""
    @State private var rating: Int = 0
    @State private var showPhotoOptions = false
    @State private var showRestaurantPicker = false
    @State private var customLocation: CLLocationCoordinate2D? = nil

    var body: some View {
        VStack(spacing:20) {
            // Image Preview or Tappable Placeholder
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .padding()
            } else {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 250)
                    .overlay(
                        Text("Tap to add an image")
                            .foregroundColor(.gray)
                            .font(.headline)
                    )
                    .onTapGesture {
                        showPhotoOptions = true // Show the popup
                    }
                    .padding()
            }

            // Star Rating
            HStack {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .foregroundColor(index <= rating ? .accentColor : .gray)
                        .font(.system(size: 20))
                        .onTapGesture {
                            rating = index
                        }
                }
            }
            .padding()

            // Display Image Location
            if let location = imageLocation {
                Text("Image Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                Text("No location data available")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding()
            }

            // Restaurant Selection
            if imageLocation == nil {
                Button(action: {
                    showRestaurantPicker = true
                }) {
                    Text(restaurantName.isEmpty ? "Select a Restaurant" : restaurantName)
                        .foregroundColor(.accentColor)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }

            // Manually Change Location
            Button(action: {
                customLocation = nil
                showRestaurantPicker = true
            }) {
                Text("Change Location")
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold)) // Custom font
                    .padding()
            }
            ZStack(alignment: .topLeading) {
                // Placeholder
                if postText.isEmpty {
                    Text("Write your review here...")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false) // Prevents placeholder from intercepting taps
                }

                // TextEditor
                ScrollView {
                    TextEditor(text: $postText)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .frame(minHeight: 150, maxHeight: .infinity) // Flexible height for the editor
                        .scrollContentBackground(.hidden) // Keeps the background clean
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal)
                
            Spacer()
        }
        .confirmationDialog("Choose Image Source", isPresented: $showPhotoOptions) {
            Button("Take a Photo") {
                sourceType = .camera
                showImagePicker = true
            }
            Button("Choose from Gallery") {
                sourceType = .photoLibrary
                showImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage, imageLocation: $imageLocation)
        }
    }
}

//IMAGE PICKER
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Binding var imageLocation: CLLocation?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                
                // Save photo to library and fetch metadata
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
        
        @objc private func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
            guard error == nil else {
                print("Error saving image: \(String(describing: error))")
                return
            }
            
            // Fetch the most recently saved photo to extract metadata
            fetchLatestPhotoMetadata()
        }
        
        private func fetchLatestPhotoMetadata() {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 1
            
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            if let asset = fetchResult.firstObject {
                if let location = asset.location {
                    parent.imageLocation = location
                } else {
                    print("No location metadata available for the photo.")
                }
            }
        }
    }
}

//Restaurant list if you want to change location

struct NearbyRestaurantPicker: View {
    @Environment(\.dismiss) var dismiss
    @State private var nearbyRestaurants: [MKMapItem] = []
    @State private var isLoading = false
    var userLocation: CLLocationCoordinate2D
    var onRestaurantSelected: (String) -> Void

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Fetching nearby restaurants...")
                        .padding()
                } else if nearbyRestaurants.isEmpty {
                    Text("No restaurants found nearby.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(nearbyRestaurants, id: \.self) { restaurant in
                        Button(action: {
                            if let name = restaurant.name {
                                onRestaurantSelected(name)
                                dismiss()
                            }
                        }) {
                            Text(restaurant.name ?? "Unnamed Restaurant")
                                .font(.headline)
                        }
                    }
                }
            }
            .onAppear {
                fetchNearbyRestaurants()
            }
            .navigationTitle("Nearby Restaurants")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func fetchNearbyRestaurants() {
        isLoading = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "Restaurants"
        request.region = MKCoordinateRegion(
            center: userLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isLoading = false
            if let error = error {
                print("Error fetching nearby restaurants: \(error)")
                return
            }
            nearbyRestaurants = response?.mapItems ?? []
        }
    }
}



 //MARK: - Preview
struct CreatePost_Previews: PreviewProvider {
    static var previews: some View {
        CreatePostView()
    }
}

            
            
            
       
