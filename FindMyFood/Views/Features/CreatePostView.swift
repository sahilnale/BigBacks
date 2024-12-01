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
    @State private var navigateToFeed = false
    @State private var navigateToMain = false
    @State private var locationDisplay: String = "Location not found"
    @State private var isUploading = false
    @State private var uploadStatus: String = ""

    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Image Preview or Placeholder
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
                            showPhotoOptions = true
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

                // Location Display
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 16, weight: .semibold))

                    Text(locationDisplay)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.primary)
                }

                Button(action: {
                    showRestaurantPicker = true
                }) {
                    Text("Change Location")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .semibold))
                }
                .sheet(isPresented: $showRestaurantPicker) {
                    NearbyRestaurantPicker(
                        userLocation: imageLocation?.coordinate ?? customLocation ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                        onRestaurantSelected: { name in
                            restaurantName = name
                            locationDisplay = name
                            showRestaurantPicker = false
                        }
                    )
                }

                ZStack(alignment: .topLeading) {
                    if postText.isEmpty {
                        Text("Write your review here...")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $postText)
                        .padding(8)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.accentColor, lineWidth: 1)
                        )
                        .frame(maxWidth: UIScreen.main.bounds.width - 32, maxHeight: 200)
                        .scrollContentBackground(.hidden)
                }

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.backward")
                            Text("Back")
                        }
                        .foregroundColor(.accentColor)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { postReview() }) {
                        Text("Post")
                            .font(.headline)
                            .foregroundColor(postText.isEmpty || selectedImage == nil ? .gray : .accentColor)
                    }
                    .disabled(postText.isEmpty || selectedImage == nil)
                }
            }
            .confirmationDialog("Choose Image Source", isPresented: $showPhotoOptions) {
                Button("Take a Photo") {
                    sourceType = .camera
                    fetchUserLocation()
                    showImagePicker = true
                }
                Button("Choose from Gallery") {
                    sourceType = .photoLibrary
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: sourceType, selectedImage: $selectedImage, imageLocation: $imageLocation, locationDisplay: $locationDisplay)
            }
        }
    }

    private func fetchUserLocation() {
        LocationManager.shared.startUpdatingLocation { location in
            DispatchQueue.main.async {
                self.imageLocation = location
                self.reverseGeocode(location)
            }
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                locationDisplay = placemark.name ?? placemark.locality ?? "Location not found"
            } else {
                locationDisplay = "Location not found"
            }
        }
    }

    
    private func postReview() {
        guard let image = selectedImage else {
            print("No image selected.")
            return
        }

        isUploading = true
        ImageUploader.uploadImage(image: image) { result in
            DispatchQueue.main.async {
                self.isUploading = false
            }
            switch result {
            case .success(let imageURL):
                // Continue with posting the review
                self.postDataToServer(imageURL: imageURL)
            case .failure(let error):
                DispatchQueue.main.async {
                    print("Image upload failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func postDataToServer(imageURL: String) {
        let boundary = UUID().uuidString
        var body = Data()
        let lineBreak = "\r\n"

        // Add fields
        let fields: [String: String] = [
            "review": reviewText.isEmpty ? postText : reviewText,
            "location": locationDisplay,
            "restaurantName": restaurantName,
            "starRating": "\(rating)",
            "imageURL": imageURL
        ]

        for (key, value) in fields {
            body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)".data(using: .utf8)!)
            body.append("\(value)\(lineBreak)".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)

        guard let url = URL(string: "https://api.bigbacksapp.com/api/v1/post/upload/\(AuthManager.shared.userId ?? "")") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        // Perform request asynchronously
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error posting data: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
                DispatchQueue.main.async {
                    self.dismiss()
                    self.selectedTab = 1 // Switch to Feed tab
                }
            }
        }.resume()
    }
    
    // IMAGE PICKER
    struct ImagePicker: UIViewControllerRepresentable {
        var sourceType: UIImagePickerController.SourceType
        @Binding var selectedImage: UIImage?
        @Binding var imageLocation: CLLocation?
        @Binding var locationDisplay: String
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
                    
                    // Attempt to retrieve PHAsset directly
                    if let asset = info[.phAsset] as? PHAsset {
                        processAsset(asset)
                    } else if let fileURL = info[.imageURL] as? URL {
                        // Fallback: Fetch PHAsset from file URL
                        fetchAssetFromFileURL(fileURL)
                    } else {
                        print("No PHAsset or file URL found for selected image.")
                        parent.locationDisplay = "Location not found"
                    }
                }
                parent.dismiss()
            }

            private func processAsset(_ asset: PHAsset) {
                if let location = asset.location {
                    print("Location metadata found: \(location)")
                    parent.imageLocation = location
                    reverseGeocode(location)
                } else {
                    print("No location metadata in PHAsset.")
                    parent.locationDisplay = "Location not found"
                }
            }

            private func fetchAssetFromFileURL(_ fileURL: URL) {
                let result = PHAsset.fetchAssets(withALAssetURLs: [fileURL], options: nil)
                if let asset = result.firstObject {
                    processAsset(asset)
                } else {
                    print("Failed to fetch PHAsset manually.")
                    parent.locationDisplay = "Location not found"
                }
            }

//            @objc private func saveImageCompletion(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
//                if let error = error {
//                    print("Error saving image: \(error)")
//                    parent.locationDisplay = "Unable to save image."
//                } else {
//                    print("Image saved successfully.")
//                    
//                    // Fetch the most recently added photo for its PHAsset
//                    PHPhotoLibrary.shared().performChanges({
//                        PHAssetChangeRequest.creationRequestForAsset(from: image)
//                    }) { success, error in
//                        if success {
//                            self.fetchLastSavedPhoto()
//                        } else if let error = error {
//                            print("Error fetching saved photo: \(error)")
//                        }
//                    }
//                }
//            }
            @objc private func saveImageCompletion(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
                if let error = error {
                    print("Error saving image: \(error)")
                    parent.locationDisplay = "Unable to save image."
                } else {
                    print("Image saved successfully.")
                    
                    // Fetch the most recently added photo for its PHAsset
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }) { success, error in
                        if success {
                            print("Image saved. Attempting to fetch the last saved photo.")
                            self.fetchLastSavedPhoto()
                        } else if let error = error {
                            print("Error fetching saved photo: \(error)")
                        }
                    }
                }
            }

            
//            private func fetchLastSavedPhoto() {
//                let fetchOptions = PHFetchOptions()
//                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
//                fetchOptions.fetchLimit = 1
//                
//                let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
//                if let lastAsset = assets.firstObject, let location = lastAsset.location {
//                    print("Location from saved photo: \(location)")
//                    parent.imageLocation = location
//                    reverseGeocode(location)
//                } else {
//                    print("No location metadata found in saved photo.")
//                    parent.locationDisplay = "Location not found"
//                }
//            }
            private func fetchLastSavedPhoto() {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchOptions.fetchLimit = 1
                
                let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                if let lastAsset = assets.firstObject {
                    print("Fetched last saved photo: \(lastAsset)")
                    if let creationDate = lastAsset.creationDate {
                        print("Last photo creation date: \(creationDate)")
                    }
                    if let location = lastAsset.location {
                        print("Location from saved photo: \(location)")
                        parent.imageLocation = location
                        reverseGeocode(location)
                    } else {
                        print("No location metadata found in the last saved photo.")
                        parent.locationDisplay = "Location not found"
                    }
                } else {
                    print("No photo assets found.")
                }
            }

            
//            private func reverseGeocode(_ location: CLLocation) {
//                let geocoder = CLGeocoder()
//                geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
//                    guard let self = self else { return }
//                    if let placemark = placemarks?.first {
//                        let locationName = placemark.name ?? placemark.locality ?? "Unknown Location"
//                        print("Geocoded Location: \(locationName)")
//                        DispatchQueue.main.async {
//                            self.parent.locationDisplay = locationName
//                        }
//                    } else {
//                        DispatchQueue.main.async {
//                            self.parent.locationDisplay = "Location not found"
//                        }
//                    }
//                }
//            }
            
            private func reverseGeocode(_ location: CLLocation) {
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                    guard let self = self else { return }
                    if let placemark = placemarks?.first {
                        let locationName = placemark.name ?? placemark.locality ?? "Unknown Location"
                        print("Geocoded Location: \(locationName)")
                        DispatchQueue.main.async {
                            self.parent.locationDisplay = locationName
                        }
                    } else {
                        print("Failed to reverse geocode location: \(location)")
                        DispatchQueue.main.async {
                            self.parent.locationDisplay = "Location not found"
                        }
                    }
                }
            }

            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                parent.dismiss()
            }
        }
    }
    
    // NEARBY RESTAURANT PICKER (unchanged from previous code)
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
            request.naturalLanguageQuery = "food"
            request.region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.005 , longitudeDelta: 0.01)
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
}



