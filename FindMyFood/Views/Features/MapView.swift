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
    private let ratingLabel = UILabel()  // Optional, remove if not used
    private let commentScrollView = UIScrollView()
    private let commentLabel = UILabel()
    private let nameAndStarsStackView = UIStackView()
    private let profileImageView = UIImageView()
    
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
        
        // Create star images (filled and empty)
        let filledStarImage = UIImage(systemName: "star.fill")?.withTintColor(.orange, renderingMode: .alwaysOriginal)
        let emptyStarImage = UIImage(systemName: "star")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
        
        // Array to hold star image views
        var starImageViews: [UIImageView] = []
        
        // Title label
        titleLabel.font = UIFont(name: "Helvetica-Bold", size: 30)
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textColor = .orange
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Image view
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
    
        
        // Reviewer name and stars stack view
        nameAndStarsStackView.axis = .horizontal
        nameAndStarsStackView.alignment = .center
        nameAndStarsStackView.spacing = 4
        nameAndStarsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Profile picture view
        
        profileImageView.image = UIImage(systemName: "person.crop.circle")?.withTintColor(.gray, renderingMode: .alwaysOriginal) // Replace with actual profile picture
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20 // Make it round
        profileImageView.clipsToBounds = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        nameAndStarsStackView.addArrangedSubview(profileImageView) // Add profile image to stack view
        
        
        
        // Reviewer name
        reviewerNameLabel.font = UIFont(name: "Helvetica-Regular", size: 25)
        reviewerNameLabel.textColor = .orange
        reviewerNameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameAndStarsStackView.addArrangedSubview(reviewerNameLabel)
        
        
        
        

        

        // Create 5 star image views
        for _ in 0..<5 {

            let starImageView = UIImageView()
                starImageView.contentMode = .scaleAspectFit
                starImageView.image = UIImage(systemName: "star")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
                starImageView.translatesAutoresizingMaskIntoConstraints = false
                starImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
                starImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
                
                starImageViews.append(starImageView) // Add to the array
                nameAndStarsStackView.addArrangedSubview(starImageView)
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
        
        // Comment Scroll View
        commentScrollView.translatesAutoresizingMaskIntoConstraints = false
        commentScrollView.showsVerticalScrollIndicator = true
        
        // Comment label
        commentLabel.font = UIFont(name: "Helvetica-Regular", size: 16)
        commentLabel.textColor = .black
        commentLabel.numberOfLines = 0 // Unlimited lines for full text rendering
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        commentScrollView.addSubview(commentLabel)
        
        // Add subviews
        addSubview(titleLabel)
        addSubview(imageView)
        addSubview(nameAndStarsStackView)
        addSubview(commentScrollView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
            imageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
            
            
            nameAndStarsStackView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 19),
            nameAndStarsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
        
            
            commentScrollView.topAnchor.constraint(equalTo: nameAndStarsStackView.bottomAnchor, constant: 8),
            commentScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            commentScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            commentScrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            commentLabel.topAnchor.constraint(equalTo: commentScrollView.topAnchor, constant: 10),
            commentLabel.leadingAnchor.constraint(equalTo: commentScrollView.leadingAnchor),
            commentLabel.trailingAnchor.constraint(equalTo: commentScrollView.trailingAnchor),
            commentLabel.bottomAnchor.constraint(equalTo: commentScrollView.bottomAnchor),
            commentLabel.widthAnchor.constraint(equalTo: commentScrollView.widthAnchor)
        ])
    }

    func setDetails(title: String, image: UIImage?, reviewerName: String, rating: String, comment: String) {
        titleLabel.text = title
        imageView.image = image
        reviewerNameLabel.text = reviewerName
        ratingLabel.text = "Rating: \(rating)"  // Set this only if used
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
            comment: "The food very much sucks ass"
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

#Preview {
    MapViewModel()
}
