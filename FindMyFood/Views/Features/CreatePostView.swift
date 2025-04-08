import SwiftUI
import PhotosUI
import CoreLocation
import Photos
import MapKit
import UIKit

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
    @State private var isKeyboardVisible = false // Track keyboard visibility
    @State private var draggedItem: UIImage?
    
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int
    @EnvironmentObject var authViewModel: AuthViewModel

    var onPostComplete: (() -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                ScrollView {
                    VStack(spacing: 10) {
                        // Image Preview Section
                        if selectedImages.isEmpty {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: isKeyboardVisible ? 150 : 250) // Shrink when typing
                                .overlay(
                                    Text("Tap to add images")
                                        .foregroundColor(.gray)
                                        .font(.headline)
                                )
                                .onTapGesture { showPhotoOptions = true }
                                .padding()
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Array(selectedImages.indices), id: \.self) { index in
                                        imageView(for: selectedImages[index], at: index)
                                            .padding(.horizontal, 4)
                                    }
                                    
                                    // Add More Images Button
                                    Button(action: { showPhotoOptions = true }) {
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 100, height: isKeyboardVisible ? 150 : 250)
                                            .overlay(
                                                Text("+ Add")
                                                    .foregroundColor(.gray)
                                                    .font(.headline)
                                            )
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: isKeyboardVisible ? 150 : 250)
                        }

                        // Star Rating Section
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

                        // Change Location Button
                        Button(action: { showRestaurantPicker = true }) {
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
                                .frame(height: 200)
                                .background(Color.customOrange.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.customOrange, lineWidth: 1)
                                )
                                .scrollContentBackground(.hidden)
                        }
                        .padding(.horizontal)
                    }
                }
                .onAppear {
                    // Keyboard Listeners
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                        withAnimation {
                            isKeyboardVisible = true
                        }
                    }
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                        withAnimation {
                            isKeyboardVisible = false
                        }
                    }
                }

                Spacer()

                if isUploading {
                    ProgressView("Uploading...")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
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
                    CameraPicker(
                        selectedImages: $selectedImages,
                        imageLocation: $imageLocation,
                        locationDisplay: $locationDisplay,
                        isLocationManuallySet: $isLocationManuallySet
                    )
                } else {
                    MultiImagePicker(
                        sourceType: sourceType,
                        selectedImages: $selectedImages,
                        imageLocation: $imageLocation,
                        locationDisplay: $locationDisplay,
                        isLocationManuallySet: $isLocationManuallySet,
                        customLocation: $customLocation
                    )
                }
            }
        }
    }
    
    // Helper method to create an image view with drag and drop support
    private func imageView(for image: UIImage, at index: Int) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(height: isKeyboardVisible ? 150 : 250)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .padding(8)
                    }
                }
            )
            .onDrag {
                self.draggedItem = image
                return NSItemProvider(object: "\(index)" as NSString)
            }
            .onDrop(of: [.text], isTargeted: nil) { providers in
                guard let provider = providers.first else { return false }
                
                _ = provider.loadObject(ofClass: NSString.self) { draggedIndex, _ in
                    if let draggedIndex = draggedIndex as? NSString, 
                       let draggedIndexInt = Int(draggedIndex as String),
                       draggedIndexInt < selectedImages.count {
                        
                        DispatchQueue.main.async {
                            // Make sure indices are valid
                            guard draggedIndexInt != index else { return }
                            
                            // Perform the move
                            withAnimation {
                                let item = selectedImages.remove(at: draggedIndexInt)
                                selectedImages.insert(item, at: index)
                            }
                        }
                    }
                }
                return true
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

            // Post notification with all necessary details for map annotation
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .postAdded,
                    object: nil,
                    userInfo: [
                        "postId": newPost.id,
                        "userId": newPost.userId,
                        "imageData": newPost.imageUrls,
                        "location": locationString,
                        "restaurantName": restaurantName,
                        "review": reviewContent,
                        "starRating": rating,
                        "likes": 0
                    ]
                )
            }

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
}

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Binding var imageLocation: CLLocation?
    @Binding var locationDisplay: String
    @Binding var isLocationManuallySet: Bool

    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        
        // Request location when opening camera
        if imageLocation == nil && !isLocationManuallySet {
            requestCurrentLocation()
        }
        
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Request current location as a fallback
    private func requestCurrentLocation() {
        LocationManager.shared.startUpdatingLocation { location in
            DispatchQueue.main.async {
                // Only set if not already set by other means
                if self.imageLocation == nil && !self.isLocationManuallySet {
                    self.imageLocation = location
                    print("Debug: Using current location as fallback - Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")
                    self.reverseGeocode(location)
                }
            }
        }
    }
    
    private func reverseGeocode(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                let locationName = placemark.name ?? placemark.locality ?? "Unknown Location"
                DispatchQueue.main.async {
                    if !self.isLocationManuallySet {
                        self.locationDisplay = locationName
                    }
                }
            }
        }
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
                    if !self.parent.isLocationManuallySet {
                        let hasLocation = self.fetchAssetLocation(from: info)
                        
                        // If no location in image metadata, ensure we have the current location
                        if !hasLocation && self.parent.imageLocation == nil {
                            self.parent.requestCurrentLocation()
                        }
                    }
                }
            }
            picker.dismiss(animated: true)
        }

        private func fetchAssetLocation(from info: [UIImagePickerController.InfoKey: Any]) -> Bool {
            if let asset = info[.phAsset] as? PHAsset, let location = asset.location {
                DispatchQueue.main.async {
                    self.parent.imageLocation = location
                    print("Debug: Camera image location - Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")
                    self.reverseGeocode(location)
                }
                return true
            }
            return false
        }

        private func reverseGeocode(_ location: CLLocation) {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first {
                    let locationName = placemark.name ?? placemark.locality ?? "Unknown Location"
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
    @Binding var customLocation: CLLocationCoordinate2D?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        
        // Request location when opening picker
        if imageLocation == nil && !isLocationManuallySet {
            requestCurrentLocation()
        }
        
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Request current location as a fallback
    private func requestCurrentLocation() {
        LocationManager.shared.startUpdatingLocation { location in
            DispatchQueue.main.async {
                // Only set if not already set by other means
                if self.imageLocation == nil && !self.isLocationManuallySet {
                    self.customLocation = location.coordinate
                    print("Debug: Using current location as fallback - Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")
                    self.reverseGeocode(location)
                }
            }
        }
    }
    
    private func reverseGeocode(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                let locationName = placemark.name ?? placemark.locality ?? "Unknown Location"
                DispatchQueue.main.async {
                    if !self.isLocationManuallySet {
                        self.locationDisplay = locationName
                    }
                }
            }
        }
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: MultiImagePicker

        init(_ parent: MultiImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                DispatchQueue.main.async {
                    self.parent.selectedImages.append(image)
                    print("Debug: Added image.")
                    
                    // Only extract location metadata if no location is set yet
                    if !self.parent.isLocationManuallySet && self.parent.imageLocation == nil {
                        var hasLocation = false
                        
                        if let asset = info[.phAsset] as? PHAsset {
                            hasLocation = self.processAsset(asset)
                            print("metadata not found1")
                        } else if let fileURL = info[.imageURL] as? URL {
                            hasLocation = self.fetchAssetFromFileURL(fileURL)
                            print("metadata not found2")
                        }
                        
                        // If no location found in metadata, use current location
                        if !hasLocation {
                            self.parent.requestCurrentLocation()
                        }
                    }
                }
            }
            picker.dismiss(animated: true)
        }

        private func processAsset(_ asset: PHAsset) -> Bool {
            if let location = asset.location {
                DispatchQueue.main.async {
                    self.parent.imageLocation = location
                    print("Debug: Detected image location - Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")
                    self.reverseGeocode(location)
                }
                return true
            } else {
                return false
            }
        }

        private func fetchAssetFromFileURL(_ fileURL: URL) -> Bool {
            let result = PHAsset.fetchAssets(withALAssetURLs: [fileURL], options: nil)
            if let asset = result.firstObject {
                return processAsset(asset)
            }
            return false
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

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
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
    @State private var nearbyRestaurants: [(restaurant: MKMapItem, distance: CLLocationDistance)] = []
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
                    List {
                        ForEach(nearbyRestaurants, id: \.restaurant) { item in
                            Button(action: {
                                let name = item.restaurant.name ?? "Unnamed Restaurant"
                                let coordinate = item.restaurant.placemark.coordinate
                                onRestaurantSelected(name, coordinate)
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.restaurant.name ?? "Unnamed Restaurant")
                                            .font(.headline)
                                        
                                        if let addressString = addressString(from: item.restaurant.placemark) {
                                            Text(addressString)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Display distance
                                    Text(formatDistance(item.distance))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
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
        // Search terms with more categories to find a wider variety of places
        let searchTerms = [
            "restaurant",
            "food", 
            "coffee shop", 
            "cafe", 
            "bakery", 
            "bar", 
            "pub", 
            "fast food", 
            "diner", 
            "bistro",
            "sandwich shop",
            "pizzeria",
            "sushi",
            "noodles",
            "mexican",
            "takeout",
            "dessert"
        ]
        
        var allPlaces: [MKMapItem] = []
        let group = DispatchGroup()
        isLoading = true
        
        // Use a larger search radius to find more places
        let searchRadius: CLLocationDistance = 2000 // 2000 meters = ~1.25 miles
        
        for term in searchTerms {
            group.enter()
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = term
            request.region = MKCoordinateRegion(
                center: userLocation,
                latitudinalMeters: searchRadius,
                longitudinalMeters: searchRadius
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
            // Create a dictionary to filter out duplicates
            let uniquePlacesDict = Dictionary(
                grouping: allPlaces,
                by: { Coordinate($0.placemark.coordinate) }
            )
            .compactMap { $0.value.first }
            
            // Calculate distance for each restaurant
            let userLocationObj = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
            let restaurantsWithDistance = uniquePlacesDict.compactMap { restaurant -> (restaurant: MKMapItem, distance: CLLocationDistance)? in
                let restaurantLocation = CLLocation(
                    latitude: restaurant.placemark.coordinate.latitude, 
                    longitude: restaurant.placemark.coordinate.longitude
                )
                let distance = restaurantLocation.distance(from: userLocationObj)
                return (restaurant: restaurant, distance: distance)
            }
            
            // Sort by distance from closest to furthest
            self.nearbyRestaurants = restaurantsWithDistance.sorted { $0.distance < $1.distance }
            
            self.isLoading = false
        }
    }
    
    // Format distance to human-readable format
    private func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            let miles = meters / 1609.34
            return String(format: "%.1f mi", miles)
        }
    }
    
    // Get a formatted address from the placemark
    private func addressString(from placemark: MKPlacemark) -> String? {
        // Extract street address components
        let thoroughfare = placemark.thoroughfare
        let subThoroughfare = placemark.subThoroughfare
        let locality = placemark.locality
        
        var components: [String] = []
        
        if let subThoroughfare = subThoroughfare {
            components.append(subThoroughfare)
        }
        
        if let thoroughfare = thoroughfare {
            components.append(thoroughfare)
        }
        
        if let locality = locality {
            components.append(locality)
        }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

// Image drop delegate for handling reordering
struct ImageDropDelegate: DropDelegate {
    let item: UIImage
    @Binding var items: [UIImage]
    let draggedItem: UIImage?
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else {
            return false
        }
        
        let _ = itemProvider.loadObject(ofClass: NSString.self) { (string, error) in
            guard let string = string as? NSString,
                  let fromIndex = Int(string as String),
                  let toIndex = self.items.firstIndex(where: { $0 == self.item }) else {
                return
            }
            
            // Only move if different positions
            if fromIndex != toIndex {
                DispatchQueue.main.async {
                    // Move the element
                    withAnimation {
                        let movedItem = self.items.remove(at: fromIndex)
                        self.items.insert(movedItem, at: toIndex)
                    }
                }
            }
        }
        
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
