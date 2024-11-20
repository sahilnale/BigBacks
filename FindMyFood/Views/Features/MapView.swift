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
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Image view
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Reviewer name
        reviewerNameLabel.font = UIFont.systemFont(ofSize: 14)
        reviewerNameLabel.textColor = .darkGray
        reviewerNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Rating label
        ratingLabel.font = UIFont.systemFont(ofSize: 14)
        ratingLabel.textColor = .systemYellow
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Comment label
        commentLabel.font = UIFont.systemFont(ofSize: 12)
        commentLabel.textColor = .darkGray
        commentLabel.numberOfLines = 0
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        addSubview(titleLabel)
        addSubview(imageView)
        addSubview(reviewerNameLabel)
        addSubview(ratingLabel)
        addSubview(commentLabel)
        
        // Layout
        NSLayoutConstraint.activate([
            // Title label at the top
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 0.1),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            // Image view centered below the title
            imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),  // This centers the image view horizontally
            imageView.widthAnchor.constraint(equalToConstant: 300),  // You can adjust the width as needed
            imageView.heightAnchor.constraint(equalToConstant: 300),
            
            // Reviewer name label below the image view
            reviewerNameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            reviewerNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            
            // Rating label to the right of the reviewer name
            ratingLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            ratingLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            // Comment label below the reviewer name and rating
            commentLabel.topAnchor.constraint(equalTo: reviewerNameLabel.bottomAnchor, constant: 4),
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
        
        // Add image annotation for San Francisco
        loadImageAnnotation()
        
        // Add double-tap gesture recognizer for annotations
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        map.addGestureRecognizer(doubleTapRecognizer)
        
        // Add tap gesture recognizer to dismiss the popup when clicking outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        tapGesture.cancelsTouchesInView = false // Allow other gestures to be recognized
        map.addGestureRecognizer(tapGesture)
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
            
            // Add a button to the annotation's callout
            let button = UIButton(type: .detailDisclosure)
            button.addTarget(self, action: #selector(annotationButtonTapped(_:)), for: .touchUpInside)
            annotationView?.rightCalloutAccessoryView = button
            
            return annotationView
        }
        
        return nil
    }
    
    // Handle annotation button tap
    @objc func annotationButtonTapped(_ sender: UIButton) {
        print("Callout button tapped!")
        // Handle further actions like navigating to a detailed view
    }

    // Handle double-tap gesture on the map (not on annotations)
    @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        let touchPoint = recognizer.location(in: map)
        let touchMapCoordinate = map.convert(touchPoint, toCoordinateFrom: map)
        
        // Check if the double-tap is close to any annotation
        let annotations = map.annotationsWithinRect(in: map.visibleMapRect)
        for annotation in annotations {
            if let imageAnnotation = annotation as? ImageAnnotation {
                let threshold = 0.1 // Define a threshold for how close the tap should be
                if abs(imageAnnotation.coordinate.latitude - touchMapCoordinate.latitude) < threshold &&
                   abs(imageAnnotation.coordinate.longitude - touchMapCoordinate.longitude) < threshold {
                    
                    // Remove existing popup views
                    currentPopupView?.removeFromSuperview()
                    
                    // Create a new popup view
                    let popupView = CustomPopupView()
                    popupView.frame = CGRect(x: map.bounds.midX - 165, y: map.bounds.midY - 250, width: 350, height: 600)
                    
                    // Adjust the size and position
                    popupView.layer.cornerRadius = 10
                    popupView.layer.masksToBounds = true
                    
                    // Populate the popup with annotation details
                    popupView.setDetails(
                        title: imageAnnotation.title ?? "Restaurant Name",
                        image: imageAnnotation.image,
                        reviewerName: "Nitin",
                        rating: "imageAnnotation.rating",
                        comment: "this shit ass"
                    )
                    
                    // Add the popup to the map
                    map.addSubview(popupView)
                    
                    // Set the current popup view for dismissal
                    currentPopupView = popupView
                    return
                }
            }
        }
    }
    
    // Dismiss the popup if tapping anywhere outside the popup
    @objc func handleMapTap(_ recognizer: UITapGestureRecognizer) {
        let touchPoint = recognizer.location(in: map)
        
        // Check if the touch is within the bounds of the current popup view
        if let popupView = currentPopupView, !popupView.frame.contains(touchPoint) {
            // Remove the popup
            popupView.removeFromSuperview()
            currentPopupView = nil
        }
    }
    
    // MKMapViewDelegate method to handle annotation selection
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // You can use this to handle custom logic on annotation selection
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
