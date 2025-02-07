import SwiftUI
import PhotosUI
import CoreLocation
import Photos
import MapKit

struct CreatePostView: View {
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImages: [UIImage] = []
    @State private var imageLocation: CLLocation? = nil
    @State private var postText: String = ""
    @State private var restaurantName: String = ""
    @State private var reviewText: String = ""
    @State private var rating: Int = 0
    @State private var showPhotoOptions = false
    @State private var showRestaurantPicker = false
    @State private var customLocation: CLLocationCoordinate2D? = nil
    @State private var locationDisplay: String = "Location not found"
    @State private var selectedLocationCoordinates: CLLocationCoordinate2D? = nil
    @State private var isUploading = false
    @State private var isLocationManuallySet = false
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int
    @EnvironmentObject var authViewModel: AuthViewModel

    var onPostComplete: (() -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if selectedImages.isEmpty {
                    // Placeholder for no selected images
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 250)
                        .overlay(
                            Text("Tap to add images")
                                .foregroundColor(.gray)
                                .font(.headline)
                        )
                        .onTapGesture {
                            showPhotoOptions = true
                        }
                        .padding()
                } else {
                    // Scrollable preview for selected images
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(selectedImages, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 250)
                                    .cornerRadius(15)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                            }
                            // Add "Add More" button
                            Button(action: {
                                showPhotoOptions = true
                            }) {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 150, height: 250)
                                    .overlay(
                                        Text("+ Add More")
                                            .foregroundColor(.gray)
                                            .font(.headline)
                                    )
                                    .padding(.trailing, 10)
                            }
                        }
                        .padding([.leading, .top], 10)
                    }
                    .frame(height: 250)
                }

                // Star Rating
                HStack {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= rating ? "star.fill" : "star")
                            .foregroundColor(index <= rating ? .customOrange : .gray)
                            .font(.system(size: 20))
                            .onTapGesture {
                                rating = index
                            }
                    }
                }

                // Location Display
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.customOrange)
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
                        onRestaurantSelected: { name, coordinates in
                            restaurantName = name
                            locationDisplay = name
                            selectedLocationCoordinates = coordinates
                            showRestaurantPicker = false
                            isLocationManuallySet = true
                        }
                    )
                }

                // TextEditor for Review
                TextEditor(text: $postText)
                    .padding(8)
                    .background(Color.customOrange.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.customOrange, lineWidth: 1)
                    )
                    .frame(maxWidth: UIScreen.main.bounds.width - 32, maxHeight: 200)
                    .scrollContentBackground(.hidden)
                
                Spacer()

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
                        .foregroundColor(.customOrange)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await postReview()
                            onPostComplete?()
                        }
                    }) {
                        Text("Post")
                            .font(.headline)
                            .foregroundColor(postText.isEmpty || selectedImages.isEmpty || isUploading ? .gray : .customOrange)
                    }
                    .disabled(postText.isEmpty || selectedImages.isEmpty || isUploading)
                }
            }
            .confirmationDialog("Choose Image Source", isPresented: $showPhotoOptions) {
                Button("Take a Photo") {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        sourceType = .camera
                        fetchUserLocation()
                        showImagePicker = true
                    } else {
                        print("Debug: Camera not available on this device.")
                    }
                }
                Button("Choose from Gallery") {
                    sourceType = .photoLibrary
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showImagePicker) {
                if sourceType == .camera {
                    CameraPicker(selectedImages: $selectedImages)
                } else {
                    MultiImagePicker(
                        sourceType: sourceType,
                        selectedImages: $selectedImages,
                        imageLocation: $imageLocation,
                        locationDisplay: $locationDisplay,
                        isLocationManuallySet: $isLocationManuallySet
                    )
                }
            }
        }
    }

    private func fetchUserLocation() {
        guard !isLocationManuallySet else { return }
        LocationManager.shared.startUpdatingLocation { location in
            DispatchQueue.main.async {
                self.imageLocation = location
                print("Debug: Detected coordinates - Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")
                self.reverseGeocode(location)
            }
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        guard !isLocationManuallySet else { return }
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                let placeName = placemark.name ?? placemark.locality ?? "Location not found"
                DispatchQueue.main.async {
                    if !self.isLocationManuallySet {
                        self.locationDisplay = placeName
                        print("Debug: Geocoded location - \(placeName)")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    if !self.isLocationManuallySet {
                        self.locationDisplay = "Location not found"
                        print("Debug: Geocoding failed - Location not found")
                    }
                }
            }
        }
    }

    private func postReview() async {
        guard !selectedImages.isEmpty else { return }

        isUploading = true
        do {
            let imageDatas = selectedImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
            if imageDatas.isEmpty { return }

            if restaurantName.isEmpty || restaurantName == "Location not found" {
                restaurantName = locationDisplay
            }

            let coordinates = selectedLocationCoordinates ?? imageLocation?.coordinate ?? customLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            let locationString = "\(coordinates.latitude),\(coordinates.longitude)"
            let reviewContent = reviewText.isEmpty ? postText : reviewText

            let newPost = try await authViewModel.addPost(
                imageDatas: imageDatas,
                review: reviewContent,
                location: locationString,
                restaurantName: restaurantName,
                starRating: rating
            )

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
        selectedImages = []
        postText = ""
        reviewText = ""
        rating = 0
        locationDisplay = "Location not found"
        isLocationManuallySet = false
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                DispatchQueue.main.async {
                    self.parent.selectedImages.append(image)
                }
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}


struct MultiImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImages: [UIImage]
    @Binding var imageLocation: CLLocation?
    @Binding var locationDisplay: String
    @Binding var isLocationManuallySet: Bool
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0 // Allow multiple images
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultiImagePicker

        init(_ parent: MultiImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard !results.isEmpty else {
                print("Debug: No images were selected.")
                parent.dismiss()
                return
            }

            print("Debug: \(results.count) images selected.")
            for (index, result) in results.enumerated() {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                        if let uiImage = image as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.selectedImages.append(uiImage)
                                print("Debug: Added image \(index + 1).")
                            }
                        }
                    }
                }

                // Attempt to load location metadata for the first image
                if index == 0 && !parent.isLocationManuallySet {
                    result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.image") { url, error in
                        if let fileURL = url {
                            self.fetchAssetLocation(from: fileURL)
                        } else {
                            print("Debug: Unable to load file for location metadata - \(error?.localizedDescription ?? "Unknown error").")
                        }
                    }
                }
            }

            parent.dismiss()
        }

        private func fetchAssetLocation(from fileURL: URL) {
            let result = PHAsset.fetchAssets(withALAssetURLs: [fileURL], options: nil)
            if let asset = result.firstObject, let location = asset.location {
                DispatchQueue.main.async {
                    self.parent.imageLocation = location
                    print("Debug: Detected image coordinates - Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")
                    self.reverseGeocode(location)
                }
            } else {
                DispatchQueue.main.async {
                    self.parent.locationDisplay = "Location not found"
                    print("Debug: No location metadata found for the first selected image.")
                }
            }
        }

        private func reverseGeocode(_ location: CLLocation) {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first {
                    let locationName = placemark.name ?? placemark.locality ?? "Unknown Location"
                    DispatchQueue.main.async {
                        self.parent.locationDisplay = locationName
                        print("Debug: Geocoded location name - \(locationName)")
                    }
                } else {
                    DispatchQueue.main.async {
                        self.parent.locationDisplay = "Location not found"
                        print("Debug: Reverse geocoding failed with error: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
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
        let searchTerms = ["food", "coffee", "restaurants", "cafe", "bakery"]
        var allPlaces: [MKMapItem] = []
        let group = DispatchGroup()
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
                if let mapItems = response?.mapItems {
                    allPlaces.append(contentsOf: mapItems)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            isLoading = false

            // Use a custom struct to make CLLocationCoordinate2D hashable
            let uniquePlaces = Dictionary(
                grouping: allPlaces,
                by: { Coordinate($0.placemark.coordinate) }
            )
            .compactMap { $0.value.first }

            nearbyRestaurants = uniquePlaces
        }
    }
}
