import SwiftUI
import MapKit
import CoreLocation




// Custom annotation class
class ImageAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var image: UIImage?
    var author: String?
    var rating: Int?
    var heartC: Int?
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, image: UIImage?, author: String?, rating: Int?, heartC: Int?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.author = author
        self.rating = rating
        self.heartC = heartC
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
    private let spacerView = UIView()
    
    
    private let starStackView = UIStackView()
    private let heartImageView = UIImageView()
    private let heartCountLabel = UILabel()
    
    
    // Create a horizontal stack view for stars and heart
    
    
    private var starRating: Int = 0 {
        didSet { updateStars() }
    }
    private var heartCount: Int = 0 {
        didSet { heartCountLabel.text = "\(heartCount)" }
    }
    
    private var starImageViews: [UIImageView] = []
    
 

    
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

        // Configure title label
        titleLabel.font = UIFont.boldSystemFont(ofSize: 30)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Configure image view
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false

        // Configure reviewer name
        reviewerNameLabel.font = UIFont.systemFont(ofSize: 20)
        reviewerNameLabel.textColor = .orange
        reviewerNameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Configure star stack view
        starStackView.axis = .horizontal
        starStackView.spacing = 4
        starStackView.translatesAutoresizingMaskIntoConstraints = false

        for _ in 0..<5 {
            let starImageView = UIImageView(image: UIImage(systemName: "star")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal))
            starImageView.translatesAutoresizingMaskIntoConstraints = false
            starImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
            starImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
            starStackView.addArrangedSubview(starImageView)
            starImageViews.append(starImageView)
        }
      

        // Configure heart image and label
        heartImageView.image = UIImage(systemName: "heart.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal)
        heartImageView.contentMode = .scaleAspectFit
        heartImageView.translatesAutoresizingMaskIntoConstraints = false
        heartImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        heartImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true

        heartCountLabel.font = UIFont.systemFont(ofSize: 16)
        heartCountLabel.textColor = .black
        heartCountLabel.translatesAutoresizingMaskIntoConstraints = false

        spacerView.widthAnchor.constraint(equalToConstant: 140).isActive = true
        // Combine stars and heart into a stack view
        let starsAndHeartStackView = UIStackView(arrangedSubviews: [starStackView, spacerView, heartImageView, heartCountLabel])
        starsAndHeartStackView.axis = .horizontal
        starsAndHeartStackView.alignment = .center
        starsAndHeartStackView.spacing = 8
        starsAndHeartStackView.translatesAutoresizingMaskIntoConstraints = false

        // Configure comment scroll view
        commentScrollView.translatesAutoresizingMaskIntoConstraints = false
        commentScrollView.showsVerticalScrollIndicator = true

        commentLabel.font = UIFont.systemFont(ofSize: 16)
        commentLabel.textColor = .black
        commentLabel.numberOfLines = 0
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        commentScrollView.addSubview(commentLabel)

        // Add subviews to main view
        addSubview(titleLabel)
        addSubview(imageView)
        addSubview(reviewerNameLabel)
        addSubview(starsAndHeartStackView)
        addSubview(commentScrollView)

        // Apply constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6),
            imageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6),

            reviewerNameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            reviewerNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),

            starsAndHeartStackView.topAnchor.constraint(equalTo: reviewerNameLabel.bottomAnchor, constant: 15),
            starsAndHeartStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            starsAndHeartStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),

            commentScrollView.topAnchor.constraint(equalTo: starsAndHeartStackView.bottomAnchor, constant: 8),
            commentScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            commentScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            commentScrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            commentLabel.topAnchor.constraint(equalTo: commentScrollView.topAnchor),
            commentLabel.leadingAnchor.constraint(equalTo: commentScrollView.leadingAnchor),
            commentLabel.trailingAnchor.constraint(equalTo: commentScrollView.trailingAnchor),
            commentLabel.bottomAnchor.constraint(equalTo: commentScrollView.bottomAnchor),
            commentLabel.widthAnchor.constraint(equalTo: commentScrollView.widthAnchor)
        ])
    }

    
    private func updateStars() {
            let filledStarImage = UIImage(systemName: "star.fill")?.withTintColor(.yellow, renderingMode: .alwaysOriginal)
            let emptyStarImage = UIImage(systemName: "star")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
            
            for (index, starImageView) in starImageViews.enumerated() {
                starImageView.image = index < starRating ? filledStarImage : emptyStarImage
            }
        }
    


    func setDetails(title: String?, image: UIImage?, reviewerName: String?, rating: Int?, comment: String?, star: Int?, heart: Int?) {
        
        
        titleLabel.text = title
        imageView.image = image

        reviewerNameLabel.text = "Reviewer: \(reviewerName)"
        ratingLabel.text = "Rating: \(rating)"  // Set this only if used
        commentLabel.text = comment

        reviewerNameLabel.text = reviewerName
        
        commentLabel.text = comment
        
        starRating = star ?? 0
        heartCount = heart ?? 0

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
        
        // Add observer for adding annotations
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAddUserAnnotationNotification(_:)),
            name: .postAdded,
            object: nil
        )
        
        // Add image annotation for San Francisco
        Task {
            await loadImageAnnotation()
        }
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
    
    
    @objc func handleAddUserAnnotationNotification(_ notification: Notification) {
        
        print("Adding annotation based on notification")
        
        Task {
            
            guard let userInfo = notification.userInfo,
                  let coordinate = userInfo["coordinate"] as? String,
                  let title = userInfo["title"] as? String,
                  let review = userInfo["review"] as? String,
                  let imageIdentifier = userInfo["image"] as? String,
                  let author = userInfo["author"] as? String,
                  let rating = userInfo["rating"] as? Int,
                  let heartC = userInfo["heartC"] as? Int else {
                return
            }
            
            guard let imageUrl = URL(string: imageIdentifier) else {
                print("Invalid URL for post:")
                return
            }
            
            // Load the image asynchronously
            let image: UIImage? = await withCheckedContinuation { continuation in
                URLSession.shared.dataTask(with: imageUrl) { data, _, error in
                    if let data = data, let fetchedImage = UIImage(data: data) {
                        continuation.resume(returning: fetchedImage)
                    } else {
                        print("Failed to fetch image for post:), error:")
                        continuation.resume(returning: nil)
                    }
                }.resume()
            }
            
            guard let image = image else {
                return
            }
            
            // Parse the coordinate
            let components = coordinate.split(separator: ",")
            guard components.count == 2,
                  let latitude = Double(components[0].trimmingCharacters(in: .whitespaces)),
                  let longitude = Double(components[1].trimmingCharacters(in: .whitespaces)) else {
                return
            }
            let coordinateC = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            
            print("hello sahil")
            
            // Add annotation
            addUserAnnotation(
                coordinate_in: coordinateC,
                title_in: title,
                review: review,
                image_in: image,
                author_in: author,
                rating_in: rating,
                heartC_in: heartC
                )
            }
        }
    
    
    
    
    
    
    func addUserAnnotation(
            coordinate_in: CLLocationCoordinate2D,
            title_in: String,
            review: String,
            image_in: UIImage, // The identifier or URL for the image
            author_in: String,
            rating_in: Int,
            heartC_in: Int
        ) {
            let annotation = ImageAnnotation(
                coordinate: coordinate_in,
                title: title_in,
                subtitle: review,
                image: image_in, // Store the image identifier here
                author: author_in,
                rating: rating_in,
                heartC: heartC_in
            )
            print("working")
            self.map.addAnnotation(annotation)
        }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //Load image annotation
    func loadImageAnnotation() async {
        guard let userId = AuthManager.shared.userId else {
            print("Failed to get user")
            return
        }

        do {
            
            let posts = try await NetworkManager.shared.fetchPostDetailsFromFeed(userId: userId)

            for (post, user) in posts {
                
                
                guard let imageUrl = URL(string: post.imageUrl) else {
                    print("Invalid URL for post: \(post.id)")
                    continue
                }
                
                // Load the image asynchronously
                let image: UIImage? = await withCheckedContinuation { continuation in
                    URLSession.shared.dataTask(with: imageUrl) { data, _, error in
                        if let data = data, let fetchedImage = UIImage(data: data) {
                            continuation.resume(returning: fetchedImage)
                        } else {
                            print("Failed to fetch image for post: \(post.id), error: \(String(describing: error))")
                            continuation.resume(returning: nil)
                        }
                    }.resume()
                }
                
                guard let image = image else {
                    continue
                }
                
                
                
                let locate = post.location
                
                let locationComponents = locate.split(separator: ",")

               
                guard locationComponents.count == 2,
              let latitude = Double(locationComponents[0]),
              let longitude = Double(locationComponents[1]) else {
                    print("Invalid location format for post: \(post.id)")
                    continue
                }
                    
                    
                // Create annotation coordinate from post (replace with actual lat/lon from post)
                let annotationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

                // Create annotation object
                let annotation = ImageAnnotation(
                    coordinate: annotationCoordinate,
                    title: post.restaurantName, // or use other field as title
                    subtitle: post.review,     // replace with proper user display name or other subtitle info
                    image: image,
                    author: user.name,
                    rating: post.starRating,
                    heartC: post.likes
                )

                // Add annotation to the map
                DispatchQueue.main.async {
                    self.map.addAnnotation(annotation)
                }
                            
           

                }

         
        } catch {
            print("Error fetching post details: \(error)")
        }
    }
    
    func removeAllAnnotations() {
        map.removeAnnotations(map.annotations)
    }
    
    func removeSpecificAnnotation(annotation: MKAnnotation) {
        map.removeAnnotation(annotation)
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


                    reviewerName: annotation.author,
                    rating: annotation.rating, // Replace with a real rating if available
                    comment: annotation.subtitle,
                    star: annotation.rating,
                    heart: annotation.heartC
                    

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

extension Notification.Name {
    static let addUserAnnotationNotification = Notification.Name("postAdded")
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
