//import SwiftUI
//import PhotosUI
//import CoreLocation
//import Photos
//import Swift
//import MapKit
//
//struct CreatePostView: View {
//    @State private var showImagePicker = false
//    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
//    @State private var selectedImage: UIImage? = nil
//    @State private var imageLocation: CLLocation? = nil
//    @State private var postText: String = ""
//    @State private var restaurantName: String = ""
//    @State private var reviewText: String = ""
//    @State private var rating: Int = 0
//    @State private var showPhotoOptions = false
//    @State private var showRestaurantPicker = false
//    @State private var customLocation: CLLocationCoordinate2D? = nil
//    @State private var navigateToFeed = false
//    @State private var navigateToMain = false
//    @State private var locationDisplay: String = "Location not found"
//    
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 20) {
//                // Image Preview or Tappable Placeholder
//                if let image = selectedImage {
//                    Image(uiImage: image)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(maxHeight: 250)
//                        .cornerRadius(15)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 15)
//                                .stroke(Color.gray, lineWidth: 1)
//                        )
//                        .padding()
//                } else {
//                    RoundedRectangle(cornerRadius: 15)
//                        .fill(Color.gray.opacity(0.2))
//                        .frame(height: 250)
//                        .overlay(
//                            Text("Tap to add an image")
//                                .foregroundColor(.gray)
//                                .font(.headline)
//                        )
//                        .onTapGesture {
//                            showPhotoOptions = true // Show the popup
//                        }
//                        .padding()
//                }
//                
//                // Star Rating
//                HStack {
//                    ForEach(1...5, id: \.self) { index in
//                        Image(systemName: index <= rating ? "star.fill" : "star")
//                            .foregroundColor(index <= rating ? .accentColor : .gray)
//                            .font(.system(size: 20))
//                            .onTapGesture {
//                                rating = index
//                            }
//                    }
//                }
//                
//                // Display Image Location
////                if !restaurantName.isEmpty {
////                    HStack {
////                        Image(systemName: "mappin.and.ellipse")
////                            .foregroundColor(.accentColor)
////                            .font(.system(size: 16, weight: .semibold))
////                        
////                        Text(restaurantName)
////                            .font(.system(size: 16, weight: .semibold))
////                            .foregroundColor(.black)
////                    }
////                    .frame(alignment: .center)
////                } else {
////                    Text("Location not found")
////                        .font(.system(size: 16, weight: .semibold))
////                        .foregroundColor(.gray)
////                        .frame(alignment: .center)
////                }
//                HStack {
//                    Image(systemName: "mappin.and.ellipse")
//                        .foregroundColor(.accentColor)
//                        .font(.system(size: 16, weight: .semibold))
//                    
//                    Text(locationDisplay)
//                        .font(.system(size: 16, weight: .semibold))
//                        .foregroundColor(.black)
//                }
//                .frame(alignment: .center)
//                // Manually Change Location
//                Button(action: {
//                    showRestaurantPicker = true // Show the RestaurantSearchView
//                }) {
//                    Text("Change Location")
//                        .foregroundColor(.blue)
//                        .font(.system(size: 16, weight: .semibold))
//                        .frame(alignment: .center)
//                }
//                .sheet(isPresented: $showRestaurantPicker) {
//                    NearbyRestaurantPicker(
//                        userLocation: customLocation ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default location
//                        onRestaurantSelected: { name in
//                            restaurantName = name
//                            showRestaurantPicker = false
//                        }
//                    )
//                }
//                .sheet(isPresented: $showPhotoOptions) {
//                    ImageSourcePicker(sourceType: $sourceType, showImagePicker: $showImagePicker)
//                }
//                .sheet(isPresented: $showImagePicker) {
//                    ImagePicker(
//                        sourceType: sourceType,
//                        selectedImage: $selectedImage,
//                        imageLocation: $imageLocation,
//                        locationDisplay: $locationDisplay
//                    )
//                }
//                
//                ZStack(alignment: .topLeading) {
//                    // Placeholder
//                    if postText.isEmpty {
//                        Text("Write your review here...")
//                            .foregroundColor(.gray)
//                            .padding(.horizontal, 10)
//                            .padding(.vertical, 12)
//                            .allowsHitTesting(false)
//                    }
//                    
//                    // TextEditor
//                    TextEditor(text: $postText)
//                        .padding(8)
//                        .background(Color.accentColor.opacity(0.1))
//                        .cornerRadius(10)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 10)
//                                .stroke(Color.accentColor, lineWidth: 1)
//                        )
//                        .frame(maxWidth: UIScreen.main.bounds.width - 32, maxHeight: 200)
//                        .scrollContentBackground(.hidden)
//                }
//                
//                Spacer()
//            }
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                        Button(action: {
//                            // Action for the back button
//                            navigateToMain = true
//                        }) {
//                            HStack {
//                                Image(systemName: "chevron.backward")
//                                Text("Back")
//                            }
//                            .foregroundColor(.blue)
//                        }
//                    }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: postReview) {
//                        Text("Post")
//                            .font(.headline)
//                            .foregroundColor(postText.isEmpty || selectedImage == nil ? .gray : .blue)
//                    }
//                    .disabled(postText.isEmpty || selectedImage == nil)
//                }
//            }
//            .confirmationDialog("Choose Image Source", isPresented: $showPhotoOptions) {
//                Button("Take a Photo") {
//                    sourceType = .camera
//                    showImagePicker = true
//                }
//                Button("Choose from Gallery") {
//                    sourceType = .photoLibrary
//                    showImagePicker = true
//                }
//                Button("Cancel", role: .cancel) {}
//            }
//            .sheet(isPresented: $showImagePicker) {
//                ImagePicker(sourceType: sourceType, selectedImage: $selectedImage, imageLocation: $imageLocation)
//            }
//            .navigationDestination(isPresented: $navigateToFeed) {
//                        FeedView()
//                    }
//            .navigationDestination(isPresented: $navigateToMain) {
//                        MainTabView()
//                    }
//        }
//        .navigationBarBackButtonHidden(true)
//    }
//    
//    private func postReview() {
//        // Add the logic to post the review
//        print("Posting the review...")
//        print("Restaurant Name: \(restaurantName)")
//        print("Post Text: \(postText)")
//        print("Rating: \(rating)")
//        // Add integration
//        
//        // Set navigate to true after posting
//        navigateToFeed = true
//    }
//    
//    private func getLocationName(_ location: CLLocation) -> String {
//            let geocoder = CLGeocoder()
//            var locationName = "Unknown Location"
//            
//            geocoder.reverseGeocodeLocation(location) { placemarks, error in
//                if let placemark = placemarks?.first {
//                    if let name = placemark.name {
//                        locationName = name
//                    } else if let locality = placemark.locality, let thoroughfare = placemark.thoroughfare {
//                        locationName = "\(thoroughfare), \(locality)"
//                    } else if let locality = placemark.locality {
//                        locationName = locality
//                    }
//                }
//            }
//            
//            return locationName
//        }
//    
//    struct ImageSourcePicker: View {
//            @Binding var sourceType: UIImagePickerController.SourceType
//            @Binding var showImagePicker: Bool
//            @Environment(\.dismiss) var dismiss
//            
//            var body: some View {
//                VStack {
//                    Button("Take a Photo") {
//                        sourceType = .camera
//                        showImagePicker = true
//                        dismiss()
//                    }
//                    Button("Choose from Gallery") {
//                        sourceType = .photoLibrary
//                        showImagePicker = true
//                        dismiss()
//                    }
//                    Button("Cancel", role: .cancel) {
//                        dismiss()
//                    }
//                }
//            }
//        }
//        
//    // IMAGE PICKER
//    struct ImagePicker: UIViewControllerRepresentable {
//        var sourceType: UIImagePickerController.SourceType
//        @Binding var selectedImage: UIImage?
//        @Binding var imageLocation: CLLocation?
//        @Environment(\.dismiss) var dismiss
//        
//        func makeUIViewController(context: Context) -> UIImagePickerController {
//            let picker = UIImagePickerController()
//            picker.delegate = context.coordinator
//            picker.sourceType = sourceType
//            return picker
//        }
//        
//        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
//        
//        func makeCoordinator() -> Coordinator {
//            Coordinator(self)
//        }
//        
//        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
//            let parent: ImagePicker
//            
//            init(_ parent: ImagePicker) {
//                self.parent = parent
//            }
//            
//            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
//                if let image = info[.originalImage] as? UIImage {
//                    parent.selectedImage = image
//                    
//                    // Only save to photos if the image was taken with camera
//                    if parent.sourceType == .camera {
//                        UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
//                    } else {
//                        // For photos from gallery, try to get location directly from the asset
//                        if let asset = info[.phAsset] as? PHAsset {
//                            if let location = asset.location {
//                                parent.imageLocation = location
//                            }
//                        }
//                    }
//                }
//                
//                parent.dismiss()
//            }
//            private func reverseGeocode(_ location: CLLocation) {
//                            let geocoder = CLGeocoder()
//                            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
//                                guard let self = self else { return }
//                                
//                                if let placemark = placemarks?.first {
//                                    DispatchQueue.main.async {
//                                        var locationName = "Unknown Location"
//                                        
//                                        if let name = placemark.name {
//                                            locationName = name
//                                        } else if let locality = placemark.locality, let thoroughfare = placemark.thoroughfare {
//                                            locationName = "\(thoroughfare), \(locality)"
//                                        } else if let locality = placemark.locality {
//                                            locationName = locality
//                                        }
//                                        
//                                        print("Geocoded Location: \(locationName)")
//                                        self.parent.locationDisplay = locationName
//                                    }
//                                } else {
//                                    print("Geocoding failed: \(error?.localizedDescription ?? "Unknown error")")
//                                    DispatchQueue.main.async {
//                                        self.parent.locationDisplay = "Location not found"
//                                    }
//                                }
//                            }
//                        }
//            
//            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//                parent.dismiss()
//            }
//            
//            @objc private func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
//                guard error == nil else {
//                    print("Error saving image: \(String(describing: error))")
//                    return
//                }
//                
//                // Only fetch metadata for newly saved camera photos
//                fetchLatestPhotoMetadata()
//            }
//            
////            private func fetchLatestPhotoMetadata() {
////                let fetchOptions = PHFetchOptions()
////                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
////                fetchOptions.fetchLimit = 1
////                
////                let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
////                if let asset = fetchResult.firstObject {
////                    if let location = asset.location {
////                        parent.imageLocation = location
////                    } else {
////                        print("No location metadata available for the photo.")
////                    }
////                }
////            }
////        }
////    }
//            
//            private func fetchLatestPhotoMetadata() {
//                            let fetchOptions = PHFetchOptions()
//                            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
//                            fetchOptions.fetchLimit = 1
//                            
//                            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
//                            if let asset = fetchResult.firstObject {
//                                if let location = asset.location {
//                                    parent.imageLocation = location
//                                    
//                                    let geocoder = CLGeocoder()
//                                    geocoder.reverseGeocodeLocation(location) { placemarks, error in
//                                        if let placemark = placemarks?.first {
//                                            DispatchQueue.main.async {
//                                                var locationName = "Unknown Location"
//                                                if let name = placemark.name {
//                                                    locationName = name
//                                                } else if let locality = placemark.locality, let thoroughfare = placemark.thoroughfare {
//                                                    locationName = "\(thoroughfare), \(locality)"
//                                                } else if let locality = placemark.locality {
//                                                    locationName = locality
//                                                }
//                                                
//                                                self.parent.onLocationFound?(locationName)
//                                            }
//                                        }
//                                    }
//                                } else {
//                                    print("No location metadata available for the photo.")
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//    
//    // Restaurant list if you want to change location
//    struct NearbyRestaurantPicker: View {
//        @Environment(\.dismiss) var dismiss
//        @State private var nearbyRestaurants: [MKMapItem] = []
//        @State private var isLoading = false
//        var userLocation: CLLocationCoordinate2D
//        var onRestaurantSelected: (String) -> Void
//        
//        var body: some View {
//            NavigationView {
//                VStack {
//                    if isLoading {
//                        ProgressView("Fetching nearby restaurants...")
//                            .padding()
//                    } else if nearbyRestaurants.isEmpty {
//                        Text("No restaurants found nearby.")
//                            .foregroundColor(.gray)
//                            .padding()
//                    } else {
//                        List(nearbyRestaurants, id: \.self) { restaurant in
//                            Button(action: {
//                                if let name = restaurant.name {
//                                    onRestaurantSelected(name)
//                                    dismiss()
//                                }
//                            }) {
//                                Text(restaurant.name ?? "Unnamed Restaurant")
//                                    .font(.headline)
//                            }
//                        }
//                    }
//                }
//                .onAppear {
//                    fetchNearbyRestaurants()
//                }
//                .navigationTitle("Nearby Restaurants")
//                .toolbar {
//                    ToolbarItem(placement: .cancellationAction) {
//                        Button("Cancel") {
//                            dismiss()
//                        }
//                    }
//                }
//            }
//        }
//        
//        private func fetchNearbyRestaurants() {
//            isLoading = true
//            let request = MKLocalSearch.Request()
//            request.naturalLanguageQuery = "Restaurants"
//            request.region = MKCoordinateRegion(
//                center: userLocation,
//                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
//            )
//            
//            let search = MKLocalSearch(request: request)
//            search.start { response, error in
//                isLoading = false
//                if let error = error {
//                    print("Error fetching nearby restaurants: \(error)")
//                    return
//                }
//                nearbyRestaurants = response?.mapItems ?? []
//            }
//        }
//    }
////}
//    
////     MARK: - Preview
////    struct CreatePost_Previews: PreviewProvider {
////        static var previews: some View {
////            CreatePostView()
////            }
////        }
////    }
//    
//#Preview {
//    CreatePostView()
//}


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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
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
                        .foregroundColor(.black)
                }
                .frame(alignment: .center)
                
                // Manually Change Location
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
                        onRestaurantSelected: { name in
                            restaurantName = name
                            locationDisplay = name
                            showRestaurantPicker = false
                        }
                    )
                }
                
                ZStack(alignment: .topLeading) {
                    // Placeholder
                    if postText.isEmpty {
                        Text("Write your review here...")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                    
                    // TextEditor
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
                    Button(action: {
                        navigateToMain = true
                    }) {
                        HStack {
                            Image(systemName: "chevron.backward")
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: postReview) {
                        Text("Post")
                            .font(.headline)
                            .foregroundColor(postText.isEmpty || selectedImage == nil ? .gray : .blue)
                    }
                    .disabled(postText.isEmpty || selectedImage == nil)
                }
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
                ImagePicker(
                    sourceType: sourceType,
                    selectedImage: $selectedImage,
                    imageLocation: $imageLocation,
                    locationDisplay: $locationDisplay
                )
            }
            .navigationDestination(isPresented: $navigateToFeed) {
                FeedView()
            }
            .navigationDestination(isPresented: $navigateToMain) {
                MainTabView()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func postReview() {
        print("Posting the review...")
        print("Restaurant Name: \(restaurantName)")
        print("Post Text: \(postText)")
        print("Rating: \(rating)")
        
        navigateToFeed = true
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
                // Print out ALL keys in the info dictionary
                print("ALL INFO KEYS: \(info.keys)")
                
                if let image = info[.originalImage] as? UIImage {
                    parent.selectedImage = image
                    
                    // Try different methods to extract location
                    
                    // Method 1: Try PHAsset
                    if let asset = info[.phAsset] as? PHAsset {
                        print("PHAsset found: \(asset)")
                        if let location = asset.location {
                            print("Location from PHAsset: \(location)")
                            parent.imageLocation = location
                            reverseGeocode(location)
                        } else {
                            print("No location in PHAsset")
                            parent.locationDisplay = "Location not found"
                        }
                    }
                    
                    // Method 2: Try UIImagePickerController.InfoKey.mediaMetadata
                    if let metadata = info[.mediaMetadata] as? [String: Any] {
                        print("Metadata: \(metadata)")
                        // Some apps extract location from EXIF data here
                    }
                    
                    // Method 3: Try URL-based location extraction
                    if let imageURL = info[.imageURL] as? URL {
                        print("Image URL: \(imageURL)")
                        
                        if let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil) {
                            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any]
                            print("Image Properties: \(String(describing: imageProperties))")
                            
                            // Try to extract GPS coordinates from EXIF
                            if let gpsDict = imageProperties?[kCGImagePropertyGPSDictionary as String] as? [String: Any],
                               let latitude = gpsDict[kCGImagePropertyGPSLatitude as String] as? Double,
                               let longitude = gpsDict[kCGImagePropertyGPSLongitude as String] as? Double {
                                let location = CLLocation(latitude: latitude, longitude: longitude)
                                print("Location from EXIF: \(location)")
                                parent.imageLocation = location
                                reverseGeocode(location)
                            }
                        }
                    }
                    
                    // If no location found by any method
                    if parent.imageLocation == nil {
                        print("No location found by any method")
                        parent.locationDisplay = "Location not found"
                    }
                }
                
                parent.dismiss()
            }

            
            private func reverseGeocode(_ location: CLLocation) {
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                    guard let self = self else { return }
                    
                    if let error = error as? CLError {
                        print("Geocoding failed: \(error.localizedDescription)")
                        
                        // Handle specific CLError cases
                        switch error.code {
                        case .network:
                            print("Network issue during geocoding.")
                        case .geocodeFoundNoResult:
                            print("No results found for the location.")
                        case .geocodeCanceled:
                            print("Geocoding was canceled.")
                        default:
                            print("Unknown geocoding error: \(error.code.rawValue)")
                        }
                        
                        DispatchQueue.main.async {
                            self.parent.locationDisplay = "Location not found"
                        }
                    } else if let placemark = placemarks?.first {
                        DispatchQueue.main.async {
                            var locationName = "Unknown Location"
                            if let name = placemark.name {
                                locationName = name
                            } else if let locality = placemark.locality, let thoroughfare = placemark.thoroughfare {
                                locationName = "\(thoroughfare), \(locality)"
                            } else if let locality = placemark.locality {
                                locationName = locality
                            }
                            
                            print("Geocoded Location: \(locationName)")
                            self.parent.locationDisplay = locationName
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
}

#Preview {
    CreatePostView()
}
