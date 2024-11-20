import SwiftUI
import MapKit
import CoreLocation

// Custom annotation class
class ImageAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var image: UIImage?
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, image: UIImage?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.image = image
    }
}

//Popup
class CustomPopupView: UIView {
    private let titleLabel = UILabel()
    private let imageView = UIImageView()
    private let reviewerNameLabel = UILabel()
    private let ratingLabel = UILabel()
    private let commentLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .white
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor
        
        // Title label
        titleLabel.font = UIFont.boldSystemFont(ofSize: 30)
        titleLabel.textAlignment = .center
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Image view
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Reviewer name
        reviewerNameLabel.font = UIFont.systemFont(ofSize: 25)
        reviewerNameLabel.textColor = .orange
        reviewerNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        
        
        // Create star images (filled and empty)
        let filledStarImage = UIImage(systemName: "star.fill")?.withTintColor(.yellow, renderingMode: .alwaysOriginal)
        let emptyStarImage = UIImage(systemName: "star")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)

        // Array to hold star image views
        var starImageViews: [UIImageView] = []

        // Create 5 star image views
        for _ in 0..<5 {
            let starImageView = UIImageView()
            starImageView.translatesAutoresizingMaskIntoConstraints = false
            starImageViews.append(starImageView)
            addSubview(starImageView)
        }

        // Function to set the rating (e.g., 3/5 stars)
        func setRating(_ rating: Int) {
            for i in 0..<5 {
                if i < rating {
                    starImageViews[i].image = filledStarImage  // Set filled star
                } else {
                    starImageViews[i].image = emptyStarImage  // Set empty star
                }
            }
        }

        // Call setRating with the desired rating, for example, 3/5
        setRating(3)
        
        // Rating label
//        ratingLabel.font = UIFont.systemFont(ofSize: 25)
//        ratingLabel.textColor = .orange
//        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Comment label
        commentLabel.font = UIFont.systemFont(ofSize: 25)
        commentLabel.textColor = .orange
        commentLabel.numberOfLines = 0
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        addSubview(titleLabel)
        addSubview(imageView)
        addSubview(reviewerNameLabel)
     
        addSubview(commentLabel)
        
        NSLayoutConstraint.activate([
        
            // Title Label at the Top
                titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5),
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
                
                // Image View Below the Title
                imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 300),
                imageView.heightAnchor.constraint(equalToConstant: 300),
                
                // Reviewer Name Below the Image
                reviewerNameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
                reviewerNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                
                // Star Rating Below the Reviewer Name
                starImageViews[0].topAnchor.constraint(equalTo: reviewerNameLabel.bottomAnchor, constant: 15),
                starImageViews[0].leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                
                starImageViews[1].topAnchor.constraint(equalTo: reviewerNameLabel.bottomAnchor, constant: 15),
                starImageViews[1].leadingAnchor.constraint(equalTo: starImageViews[0].trailingAnchor, constant: 4),
                
                starImageViews[2].topAnchor.constraint(equalTo: reviewerNameLabel.bottomAnchor, constant: 15),
                starImageViews[2].leadingAnchor.constraint(equalTo: starImageViews[1].trailingAnchor, constant: 4),
                
                starImageViews[3].topAnchor.constraint(equalTo: reviewerNameLabel.bottomAnchor, constant: 15),
                starImageViews[3].leadingAnchor.constraint(equalTo: starImageViews[2].trailingAnchor, constant: 4),
                
                starImageViews[4].topAnchor.constraint(equalTo: reviewerNameLabel.bottomAnchor, constant: 15),
                starImageViews[4].leadingAnchor.constraint(equalTo: starImageViews[3].trailingAnchor, constant: 4),
                    
                
                // Comment Label Below Reviewer Name and Rating
                commentLabel.topAnchor.constraint(equalTo: starImageViews[0].bottomAnchor, constant: 20),
                commentLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                commentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
                commentLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
            ])
    }

    
    func setDetails(title: String, image: UIImage?, reviewerName: String, rating: String, comment: String) {
        titleLabel.text = title
        imageView.image = image
        reviewerNameLabel.text = "Reviewer: \(reviewerName)"
        ratingLabel.text = "Rating: \(rating)"
        commentLabel.text = comment
    }
}


// Custom annotation view
class ImageAnnotationView: MKAnnotationView {
    private var imageView: UIImageView!
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        self.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        self.imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.layer.cornerRadius = 5.0
        self.imageView.layer.masksToBounds = true
        self.addSubview(self.imageView)
    }
    
    override var image: UIImage? {
        get {
            return self.imageView.image
        }
        set {
            self.imageView.image = newValue
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// Map View Model
class MapViewModel: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    private let locationManager = CLLocationManager()
    private let map: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = true
        map.userTrackingMode = .followWithHeading
        return map
    }()
    
    private var currentPopupView: CustomPopupView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the map view
        view.addSubview(map)
        
        // Configure the location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Configure map view delegate
        map.delegate = self
        
        
        // Add tap gesture recognizer to dismiss the popup
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        map.addGestureRecognizer(tapGesture)
        
        // Add image annotation for San Francisco
        loadImageAnnotation()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
    
    func recenterMap() {
        guard let location = locationManager.location else { return }
        
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        map.setRegion(region, animated: true)
    }
    
    // Load an image annotation for San Francisco
    func loadImageAnnotation() {
        let annotationCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // San Francisco coordinates
        guard let imageUrl = URL(string: "https://i.imgur.com/zIoAyCx.png"),
              let imageData = try? Data(contentsOf: imageUrl),
              let image = UIImage(data: imageData) else { return }
        
        let annotation = ImageAnnotation(
            coordinate: annotationCoordinate,
            title: "San Francisco",
            subtitle: "Golden Gate City",
            image: image
        )
        map.addAnnotation(annotation)
    }
    
    // CLLocationManagerDelegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
        map.setRegion(region, animated: true)
        
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }
    
    // MKMapViewDelegate method to provide custom annotation views
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        if let imageAnnotation = annotation as? ImageAnnotation {
            let identifier = "ImageAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? ImageAnnotationView
            if annotationView == nil {
                annotationView = ImageAnnotationView(annotation: imageAnnotation, reuseIdentifier: identifier)
            }
            annotationView?.annotation = imageAnnotation
            annotationView?.image = imageAnnotation.image
            
            return annotationView
        }
        
        return nil
    }
    
    // Show popup when annotation is selected
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? ImageAnnotation else { return }
        
        // Remove any existing popup
        currentPopupView?.removeFromSuperview()
        
        // Create a new popup view
        let popupView = CustomPopupView()
        popupView.frame = CGRect(x: map.bounds.midX - 170, y: map.bounds.midY - 300, width: 350, height: 600)
        
        // Adjust the size and position
        popupView.layer.cornerRadius = 10
        popupView.layer.masksToBounds = true
        
        // Populate the popup with annotation details
        popupView.setDetails(
            title: annotation.title ?? "Restaurant Name",
            image: annotation.image,
            reviewerName: "Nitin",
            rating: "annotation.rating", // Replace with a real rating if available
            comment: "This is a placeholder comment."
        )
        
        // Add the popup to the map
        map.addSubview(popupView)
        
        // Set the current popup view for dismissal
        currentPopupView = popupView
    }
    
    // Handle tap on the map to dismiss popup
        @objc func handleMapTap(_ recognizer: UITapGestureRecognizer) {
            let touchPoint = recognizer.location(in: map)
            
            // Check if the touch is outside the current popup view
            if let popupView = currentPopupView, !popupView.frame.contains(touchPoint) {
                // Remove the popup
                popupView.removeFromSuperview()
                currentPopupView = nil
            }
        }
}


// Utility extension for MKMapView to get annotations in a given map rectangle
extension MKMapView {
    func annotationsWithinRect(in rect: MKMapRect) -> [MKAnnotation] {
        var annotationsInRect: [MKAnnotation] = []
        
        for annotation in self.annotations {
            let point = MKMapPoint(annotation.coordinate)
            if rect.contains(point) {
                annotationsInRect.append(annotation)
            }
        }
        return annotationsInRect
    }
}


// SwiftUI wrapper for the MapViewModel
struct MapView: UIViewControllerRepresentable {
    let viewModel: MapViewModel

    func makeUIViewController(context: Context) -> MapViewModel {
        return viewModel
    }

    func updateUIViewController(_ uiViewController: MapViewModel, context: Context) {
        // Handle any updates to the view controller here
    }
}

//#Preview {
//    MapViewModel()
//}
