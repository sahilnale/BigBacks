//import SwiftUI
//import MapKit
//import CoreLocation
//
//class FoodPlaceAnnotation: MKPointAnnotation {
//    var establishment: MKMapItem?
//    var category: String?  // To store the type of establishment
//}
//
//class MapViewModel: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
//    private let locationManager = CLLocationManager()
//    private let map: MKMapView = {
//        let map = MKMapView()
//        map.showsUserLocation = true
//        map.userTrackingMode = .followWithHeading
//        return map
//    }()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        view.addSubview(map)
//        map.delegate = self
//        
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.requestWhenInUseAuthorization()
//        locationManager.startUpdatingLocation()
//        
//        map.pointOfInterestFilter = MKPointOfInterestFilter.excludingAll
//    }
//    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        map.frame = view.bounds
//    }
//    
//    private func searchFoodPlaces(around location: CLLocation) {
//        // Create multiple search requests for different food establishment types
//        let searchQueries = [
//            "restaurant",
//            "cafe",
//            "coffee",
//            "bakery",
//            "deli",
//            "food court",
//            "fast food",
//            "ice cream",
//            "pizzeria",
//            "bar",
//            "pub"
//        ]
//        
//        // Remove existing annotations
//        let existingAnnotations = self.map.annotations.filter { $0 is FoodPlaceAnnotation }
//        self.map.removeAnnotations(existingAnnotations)
//        
//        // Perform searches for each type
//        for query in searchQueries {
//            let request = MKLocalSearch.Request()
//            request.naturalLanguageQuery = query
//            request.region = MKCoordinateRegion(
//                center: location.coordinate,
//                latitudinalMeters: 2000,
//                longitudinalMeters: 2000
//            )
//            
//            let search = MKLocalSearch(request: request)
//            search.start { [weak self] response, error in
//                guard let self = self,
//                      let response = response,
//                      error == nil else {
//                    print("Search error for \(query): \(error?.localizedDescription ?? "Unknown error")")
//                    return
//                }
//                
//                // Add new annotations for each establishment
//                for item in response.mapItems {
//                    // Check if we already have an annotation for this location
//                    let existingAnnotation = self.map.annotations.first { annotation in
//                        guard let foodAnnotation = annotation as? FoodPlaceAnnotation else { return false }
//                        return foodAnnotation.coordinate.latitude == item.placemark.coordinate.latitude &&
//                               foodAnnotation.coordinate.longitude == item.placemark.coordinate.longitude
//                    }
//                    
//                    // Only add if we don't already have this location
//                    if existingAnnotation == nil {
//                        let annotation = FoodPlaceAnnotation()
//                        annotation.coordinate = item.placemark.coordinate
//                        annotation.title = item.name
//                        
//                        // Construct subtitle with additional information
//                        var subtitleComponents: [String] = []
//                        if let thoroughfare = item.placemark.thoroughfare {
//                            subtitleComponents.append(thoroughfare)
//                        }
//                        // Add category if available
//                        if let category = item.pointOfInterestCategory?.rawValue
//                            .replacingOccurrences(of: "MKPOICategory", with: "")
//                            .lowercased() {
//                            subtitleComponents.append(category)
//                        }
//                        annotation.subtitle = subtitleComponents.joined(separator: " • ")
//                        
//                        annotation.establishment = item
//                        annotation.category = query
//                        self.map.addAnnotation(annotation)
//                    }
//                }
//            }
//        }
//    }
//    
//    // CLLocationManagerDelegate methods
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.last else { return }
//        
//        let region = MKCoordinateRegion(
//            center: location.coordinate,
//            latitudinalMeters: 2000,
//            longitudinalMeters: 2000
//        )
//        map.setRegion(region, animated: true)
//        
//        searchFoodPlaces(around: location)
//        locationManager.stopUpdatingLocation()
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("Failed to get location: \(error.localizedDescription)")
//    }
//    
//    // MKMapViewDelegate methods
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        guard let foodAnnotation = annotation as? FoodPlaceAnnotation else { return nil }
//        
//        let identifier = "FoodPlaceAnnotation"
//        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
//        
//        if annotationView == nil {
//            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
//            annotationView?.canShowCallout = true
//            
//            let button = UIButton(type: .detailDisclosure)
//            annotationView?.rightCalloutAccessoryView = button
//        } else {
//            annotationView?.annotation = annotation
//        }
//        
//        // Customize the marker based on establishment type
//        if let markerView = annotationView as? MKMarkerAnnotationView {
//            switch foodAnnotation.category?.lowercased() {
//            case "cafe", "coffee":
//                markerView.markerTintColor = .brown
//                markerView.glyphImage = UIImage(systemName: "cup.and.saucer.fill")
//            case "bakery":
//                markerView.markerTintColor = .orange
//                markerView.glyphImage = UIImage(systemName: "birthday.cake")
//            case "ice cream":
//                markerView.markerTintColor = .systemPink
//                markerView.glyphImage = UIImage(systemName: "ice.cream")
//            case "bar", "pub":
//                markerView.markerTintColor = .purple
//                markerView.glyphImage = UIImage(systemName: "wineglass")
//            default:
//                markerView.markerTintColor = .red
//                markerView.glyphImage = UIImage(systemName: "fork.knife")
//            }
//        }
//        
//        return annotationView
//    }
//    
//    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
//        guard let annotation = view.annotation as? FoodPlaceAnnotation,
//              let establishment = annotation.establishment else { return }
//        
//        establishment.openInMaps()
//    }
//}
//
//struct MapView: UIViewControllerRepresentable {
//    func makeUIViewController(context: Context) -> MapViewModel {
//        return MapViewModel()
//    }
//
//    func updateUIViewController(_ uiViewController: MapViewModel, context: Context) {
//    }
//}


import SwiftUI
import MapKit
import CoreLocation


class MapViewModel: UIViewController, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let map: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = true
        map.userTrackingMode = .followWithHeading
        return map
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the map view
        view.addSubview(map)
        
        // Configure the location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
    
    // Public method to recenter the map
    func recenterMap() {
        guard let location = locationManager.location else { return }
        
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        map.setRegion(region, animated: true)
    }
    
    // CLLocationManagerDelegate method
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Center the map on the user's current location
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
        map.setRegion(region, animated: true)
        
        // Stop updating location to save battery life
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }
}

struct MapView: UIViewControllerRepresentable {
    let viewModel: MapViewModel // Pass the MapViewModel instance

    func makeUIViewController(context: Context) -> MapViewModel {
        return viewModel
    }

    func updateUIViewController(_ uiViewController: MapViewModel, context: Context) {
        // Handle any updates to the view controller here
    }
}
