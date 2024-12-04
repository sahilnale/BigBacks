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
    @State private var selectedLocationCoordinates: CLLocationCoordinate2D? = nil
    @State private var isUploading = false
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
                .frame(alignment: .center)

                // Change Location Button
                Button(action: {
                    showRestaurantPicker = true
                }) {
                    Text("Change Location")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(alignment: .center)
                }
                .sheet(isPresented: $showRestaurantPicker) {
                    NearbyRestaurantPicker(
                        userLocation: imageLocation?.coordinate ?? customLocation ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                        onRestaurantSelected: { name, coordinates in
                            restaurantName = name
                            locationDisplay = name
                            selectedLocationCoordinates = coordinates
                            showRestaurantPicker = false
                        }
                    )
                }

                // TextEditor for Review
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

                // Uploading Status
                if isUploading {
                    ProgressView("Uploading...")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.backward")
                            Text("Back")
                        }
                        .foregroundColor(.accentColor)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await postReview()
                        }
                    }) {
                        Text("Post")
                            .font(.headline)
                            .foregroundColor(postText.isEmpty || selectedImage == nil || isUploading ? .gray : .accentColor)
                    }
                    .disabled(postText.isEmpty || selectedImage == nil || isUploading)
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
                ImagePicker(
                    sourceType: sourceType,
                    selectedImage: $selectedImage,
                    imageLocation: $imageLocation,
                    locationDisplay: $locationDisplay
                )
            }
        }
        .navigationBarBackButtonHidden(true)
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
                if let placeName = placemark.name {
                    self.locationDisplay = placeName
                } else if let locality = placemark.locality {
                    self.locationDisplay = locality
                } else {
                    self.locationDisplay = "Location not found"
                }
            } else {
                self.locationDisplay = "Location not found"
            }
        }
    }

    private func postReview() async {
        guard let image = selectedImage else {
            print("No image selected.")
            return
        }

        isUploading = true
        do {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("Failed to compress image.")
                isUploading = false
                return
            }

            guard let userId = AuthManager.shared.userId else {
                print("User ID is not available.")
                isUploading = false
                return
            }

            if restaurantName.isEmpty || restaurantName == "Location not found" {
                restaurantName = locationDisplay
            }

            let coordinates = selectedLocationCoordinates ?? customLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            let locationString = "\(coordinates.latitude),\(coordinates.longitude)"

            let reviewContent = reviewText.isEmpty ? postText : reviewText
            let newPost = try await NetworkManager.shared.addPost(
                userId: userId,
                imageData: imageData,
                review: reviewContent,
                location: locationString,
                restaurantName: restaurantName,
                starRating: rating
            )

            print("Post created successfully: \(newPost)")
            resetPostState()
            DispatchQueue.main.async {
                dismiss()
                selectedTab = 1
            }
        } catch {
            print("Failed to create post: \(error.localizedDescription)")
        }

        isUploading = false
    }

    private func resetPostState() {
        selectedImage = nil
        postText = ""
        reviewText = ""
        rating = 0
        locationDisplay = "Location not found"
    }

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

            private func reverseGeocode(_ location: CLLocation) {
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    if let placemark = placemarks?.first {
                        let locationName = placemark.name ?? placemark.locality ?? "Unknown Location"
                        print("Geocoded Location: \(locationName)")
                        DispatchQueue.main.async {
                            self.parent.locationDisplay = locationName
                        }
                    } else {
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


    struct NearbyRestaurantPicker: View {
        @Environment(\.dismiss) var dismiss
        @State private var nearbyRestaurants: [MKMapItem] = []
        @State private var isLoading = false
        var userLocation: CLLocationCoordinate2D
        var onRestaurantSelected: (String, CLLocationCoordinate2D) -> Void

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
                                let name = restaurant.name ?? "Unnamed Restaurant"
                                let coordinate = restaurant.placemark.coordinate
                                onRestaurantSelected(name, coordinate)
                                dismiss()
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
            let searchTerms = ["food", "coffee", "grocery store", "restaurants", "restaurant", "bars", "clubs", "fast food"] // Define terms
            var allPlaces: [MKMapItem] = []
            let group = DispatchGroup() // To manage asynchronous calls
            isLoading = true

            for term in searchTerms {
                group.enter()
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = term
                request.region = MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.01)
                )
                
                let search = MKLocalSearch(request: request)
                search.start { response, error in
                    if let error = error {
                        print("Error fetching nearby \(term): \(error)")
                    } else if let mapItems = response?.mapItems {
                        allPlaces.append(contentsOf: mapItems)
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                isLoading = false

                // Remove duplicates using Coordinate as a key
                let uniquePlaces = Dictionary(grouping: allPlaces, by: { Coordinate($0.placemark.coordinate) })
                    .compactMap { $0.value.first } // Get one instance of each coordinate

                // Sort by distance from userLocation
                let sortedPlaces = uniquePlaces.sorted {
                    let distance1 = $0.placemark.location?.distance(from: CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)) ?? Double.infinity
                    let distance2 = $1.placemark.location?.distance(from: CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)) ?? Double.infinity
                    return distance1 < distance2
                }

                nearbyRestaurants = sortedPlaces // Assign compiled results
                print("Fetched \(sortedPlaces.count) unique places sorted by distance for terms: \(searchTerms)")
            }
        }


    }
}


struct Coordinate: Hashable {
    let latitude: Double
    let longitude: Double

    init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }

    static func == (lhs: Coordinate, rhs: Coordinate) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
