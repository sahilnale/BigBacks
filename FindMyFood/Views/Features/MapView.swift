import SwiftUI
import MapKit
import CoreLocation
import Firebase
import FirebaseAuth
import FirebaseFirestore
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
// Custom cluster annotation view
class ClusterAnnotationView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            guard let cluster = newValue as? MKClusterAnnotation else { return }
            
            // Count of annotations in the cluster
            let totalAnnotations = cluster.memberAnnotations.count
            glyphText = "\(totalAnnotations)" // Show count on the marker
            
            // Customize cluster color
            markerTintColor = .accentColor2
        }
    }
}
class CustomPopupView: UIView {
    private let titleLabel = UILabel()
    private let titleContainer = UIStackView()
    private let imageView = UIImageView()
    private let reviewerNameLabel = UILabel()
    private let commentLabel = UILabel()
    private let heartContainer = UIView()
    private let heartImageView = UIImageView()
    private let heartCountLabel = UILabel()
    private let ratingContainer = UIStackView()
    private var starImageViews: [UIImageView] = []
    private let ratingNumberLabel = UILabel()
    private let mapIconImageView = UIImageView()
    
    private var heartCount: Int = 0 {
        didSet {
            heartCountLabel.text = "\(heartCount)"
        }
    }
    
    private var starRating: Int = 0 {
        didSet { updateStars() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.masksToBounds = true
        
        setupSubviews()
        setupConstraints()
    }
    
    private func setupSubviews() {
        // Image View
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title Container
        titleContainer.axis = .horizontal
        titleContainer.spacing = 4
        titleContainer.alignment = .center
        titleContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        titleLabel.textColor = UIColor(red: 241/255, green: 90/255, blue: 35/255, alpha: 1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Map Icon
        mapIconImageView.image = UIImage(systemName: "mappin")?.withTintColor(.accentColor2, renderingMode: .alwaysOriginal)
        mapIconImageView.contentMode = .scaleAspectFit
        mapIconImageView.translatesAutoresizingMaskIntoConstraints = false
        mapIconImageView.isUserInteractionEnabled = true
        mapIconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openInAppleMaps)))
        
        // Rating Container
        ratingContainer.axis = .horizontal
        ratingContainer.spacing = 2
        ratingContainer.alignment = .center
        ratingContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Stars
        let goldenYellow = UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1)
        for _ in 0..<5 {
            let starImageView = UIImageView()
            starImageView.contentMode = .scaleAspectFit
            starImageView.translatesAutoresizingMaskIntoConstraints = false
            starImageView.image = UIImage(systemName: "star.fill")?.withTintColor(goldenYellow, renderingMode: .alwaysOriginal)
            starImageViews.append(starImageView)
            ratingContainer.addArrangedSubview(starImageView)
            
            NSLayoutConstraint.activate([
                starImageView.widthAnchor.constraint(equalToConstant: 24),
                starImageView.heightAnchor.constraint(equalToConstant: 24)
            ])
        }
        
        // Rating Number
        ratingNumberLabel.font = .systemFont(ofSize: 14)
        ratingNumberLabel.textColor = .accentColor2
        ratingNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingContainer.addArrangedSubview(ratingNumberLabel)
        
        // Reviewer Name
        reviewerNameLabel.font = .systemFont(ofSize: 16, weight: .regular)
        reviewerNameLabel.textColor = .accentColor2
        reviewerNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Comment
        commentLabel.font = .systemFont(ofSize: 16)
        commentLabel.textColor = .gray
        commentLabel.numberOfLines = 0
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Heart Container setup
        heartContainer.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        heartContainer.layer.cornerRadius = 25
        heartContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Heart Icon setup
        heartImageView.image = UIImage(systemName: "heart.fill")?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)
        heartImageView.contentMode = .scaleAspectFit
        heartImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Heart Count Label setup
        heartCountLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        heartCountLabel.textColor = .white
        heartCountLabel.translatesAutoresizingMaskIntoConstraints = false
        // Add subviews
        addSubview(imageView)
        addSubview(titleContainer)
        titleContainer.addArrangedSubview(titleLabel)
        titleContainer.addArrangedSubview(mapIconImageView)
        addSubview(ratingContainer)
        addSubview(reviewerNameLabel)
        addSubview(commentLabel)
        
        addSubview(heartContainer)
        heartContainer.addSubview(heartImageView)
        heartContainer.addSubview(heartCountLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Image
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.67),
            
            // Title Container
            titleContainer.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            titleContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            // Map Icon
            mapIconImageView.widthAnchor.constraint(equalToConstant: 24),
            mapIconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Rating Container
            ratingContainer.topAnchor.constraint(equalTo: titleContainer.topAnchor),
            ratingContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            // Reviewer Name
            reviewerNameLabel.topAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: 8),
            reviewerNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            // Comment
            commentLabel.topAnchor.constraint(equalTo: reviewerNameLabel.bottomAnchor, constant: 8),
            commentLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            commentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            commentLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16),
            
            // Heart Container
            heartContainer.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 16),
            heartContainer.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -16),
            heartContainer.widthAnchor.constraint(equalToConstant: 50),
            heartContainer.heightAnchor.constraint(equalToConstant: 50),
            
            // Heart Icon
            heartImageView.centerXAnchor.constraint(equalTo: heartContainer.centerXAnchor),
            heartImageView.centerYAnchor.constraint(equalTo: heartContainer.centerYAnchor),
            heartImageView.widthAnchor.constraint(equalToConstant: 30),
            heartImageView.heightAnchor.constraint(equalToConstant: 30),
            
            // Heart Count Label
            heartCountLabel.leadingAnchor.constraint(equalTo: heartContainer.trailingAnchor, constant: 8),
            heartCountLabel.centerYAnchor.constraint(equalTo: heartContainer.centerYAnchor)
        ])
    }
    
    @objc private func openInAppleMaps() {
        guard let title = titleLabel.text else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = title
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
            
            let placemark = MKPlacemark(coordinate: coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = title
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        }
    }
    
    private func updateStars() {
        let goldenYellow = UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1)
        let filledStarImage = UIImage(systemName: "star.fill")?.withTintColor(goldenYellow, renderingMode: .alwaysOriginal)
        let emptyStarImage = UIImage(systemName: "star")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
        
        for (index, starImageView) in starImageViews.enumerated() {
            starImageView.image = index < starRating ? filledStarImage : emptyStarImage
        }
    }
    
    func setDetails(title: String?, image: UIImage?, reviewerName: String?, rating: Int?, comment: String?, star: Int?, heart: Int?) {
        titleLabel.text = title
        imageView.image = image
        reviewerNameLabel.text = "@" + (reviewerName ?? "friend")
        starRating = rating ?? 0
        ratingNumberLabel.text = " (\(rating ?? 0))"
        commentLabel.text = comment
        heartCount = heart ?? 0
    }
}
// Custom annotation view with clustering support
class ImageAnnotationView: MKAnnotationView {
    private var imageView: UIImageView!
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        self.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        self.imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.layer.cornerRadius = 25
        self.imageView.layer.masksToBounds = true
        self.addSubview(self.imageView)
        
        // Enable clustering
        self.clusteringIdentifier = "imageCluster" //supposendly imageCluster
        
        
        // Set a smaller collision bounding rectangle to encourage clustering
            // This will make the annotations cluster more aggressively
            self.collisionMode = .circle
            
            // Set display priority to encourage clustering
            self.displayPriority = .defaultHigh
        
        // Add a border to make the image stand out
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.cornerRadius = 25
        self.layer.masksToBounds = true
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
class MapViewModel: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, ObservableObject {
    @Published var isPopupShown: Bool = false
    private let locationManager = CLLocationManager()
    private let map: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = true
        map.userTrackingMode = .followWithHeading
    
    
        map.isZoomEnabled = true
        map.isScrollEnabled = true
        map.showsBuildings = false
        map.showsCompass = true
        map.showsPointsOfInterest = true
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
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.requestWhenInUseAuthorization()
                locationManager.startUpdatingLocation()
                
                // Configure map view delegate
                map.delegate = self
                
                // Configure clustering
                configureMapClustering()
                
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
            
    func configureMapClustering() {
        // Register the custom cluster annotation view
        map.register(
            ClusterAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier
        )
        
        // Register your custom annotation view
        map.register(
            ImageAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: "ImageAnnotation"
        )
        
        // Force the map to recalculate clusters
        map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
        
        // Re-add the annotations if needed
        Task {
            await loadImageAnnotation()
        }
    }
            
            func removeAllAnnotations() {
                map.removeAnnotations(map.annotations)
            }
            
            func removeSpecificAnnotation(annotation: MKAnnotation) {
                map.removeAnnotation(annotation)
            }
            
            override func viewDidLayoutSubviews() {
                super.viewDidLayoutSubviews()
                map.frame = view.bounds
            }
            
            override func viewDidAppear(_ animated: Bool) {
                super.viewDidAppear(animated)
                
                // Remove all existing annotations
//                removeAllAnnotations()
                
                // Reload image annotations asynchronously
                Task {
                    await loadImageAnnotation()
                }
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
                          let author = userInfo["userId"] as? String,
                          let imageIdentifier = userInfo["imageData"] as? String,
                          let review = userInfo["review"] as? String,
                          let coordinate = userInfo["location"] as? String,
                          let title = userInfo["restaurantName"] as? String,
                          let likes = userInfo["likes"] as? Int,
                          let rating = userInfo["starRating"] as? Int else {
                        print("Guard failed")
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
                        print("Coordinate parsing failed")
                        return
                    }
                    let coordinateC = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    
                    print("About to add")
                    addUserAnnotation(coordinate_in: coordinateC, title_in: title, review: review, image_in: image, author_in: author, rating_in: rating, heartC_in: likes)
                    print("Done")
                }
            }
            
            func addUserAnnotation(
                coordinate_in: CLLocationCoordinate2D,
                title_in: String,
                review: String,
                image_in: UIImage,
                author_in: String,
                rating_in: Int,
                heartC_in: Int
            ) {
                let annotation = ImageAnnotation(
                    coordinate: coordinate_in,
                    title: title_in,
                    subtitle: review,
                    image: image_in,
                    author: author_in,
                    rating: rating_in,
                    heartC: heartC_in
                )
                print("working")
                self.map.addAnnotation(annotation)
                
                // Optionally, adjust map view region to include the new annotation
                var region = self.map.region
                region.center = coordinate_in
                region.span.latitudeDelta = 0.05
                region.span.longitudeDelta = 0.05
                self.map.setRegion(region, animated: true)
            }
            private var addedAnnotationIDs = Set<String>()
            
            func loadImageAnnotation() async {
                guard let userId = Auth.auth().currentUser?.uid else {
                    print("Failed to get user")
                    return
                }
                do {
                    let feed = try await AuthViewModel.shared.fetchPostDetailsFromFeed(userId: userId)
                    for (post, user) in feed {
                        let annotationID = post._id
                        
                        
                        if addedAnnotationIDs.contains(annotationID) {
                                        continue
                                    }
                        
                        addedAnnotationIDs.insert(annotationID)
                        guard let imageUrl = URL(string: post.imageUrl) else {
                            print("Invalid URL for post: \(post._id)")
                            continue
                        }
                        
                        
                        
                        // Load the image asynchronously
                        let image: UIImage? = await withCheckedContinuation { continuation in
                            URLSession.shared.dataTask(with: imageUrl) { data, _, error in
                                if let data = data, let fetchedImage = UIImage(data: data) {
                                    continuation.resume(returning: fetchedImage)
                                } else {
                                    print("Failed to fetch image for post: \(post._id), error: \(String(describing: error))")
                                    continuation.resume(returning: nil)
                                }
                            }.resume()
                        }
                        guard let image = image else { continue }
                        // Parse the location
                        let locationComponents = post.location.split(separator: ",")
                        guard locationComponents.count == 2,
                              let latitude = Double(locationComponents[0]),
                              let longitude = Double(locationComponents[1]) else {
                            print("Invalid location format for post: \(post._id)")
                            continue
                        }
                        let annotationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        // Create annotation
                        let annotation = ImageAnnotation(
                            coordinate: annotationCoordinate,
                            title: post.restaurantName,
                            subtitle: post.review,
                            image: image,
                            author: user.username,
                            rating: post.starRating,
                            heartC: post.likes
                        )
                        // Add annotation to the map
                        DispatchQueue.main.async {
                            self.map.addAnnotation(annotation)
//                            if self.map.annotations.count % 10 == 0 {  // Every 10 annotations, refresh the clustering
//                                    self.configureMapClustering()
//                                }
                        }
                    }
                } catch {
                    print("Error fetching post details: \(error)")
                }
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
    static var lastZoom: Double = 0
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // After a significant zoom change, force redisplay of clusters
        // This helps ensure clusters reappear when zooming out
        
        // Get the current zoom level (approximate)
        let span = mapView.region.span
        let currentZoom = (span.latitudeDelta + span.longitudeDelta) / 2
        // Store this as a static or instance property to track zoom changes
        // This is a simplified approach - you can make this more sophisticated
        let zoomThreshold: Double = 0.05 // Adjust based on your needs
        
        // If zoom has changed significantly
        if abs(currentZoom - Self.lastZoom) > zoomThreshold {
            Self.lastZoom = currentZoom
            
            // Force the map to recalculate annotations after a small delay
            // This helps with clusters reappearing when zooming out
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // This subtle trick forces MapKit to reconsider clustering without removing annotations
                for annotation in mapView.annotations where annotation is ImageAnnotation {
                    if let annotationView = mapView.view(for: annotation) as? ImageAnnotationView {
                        annotationView.clusteringIdentifier = nil
                        annotationView.clusteringIdentifier = "imageCluster"
                    }
                }
            }
        }
    }
    
//
            
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
                print("Failed to get location: \(error.localizedDescription)")
            }
            
            // MKMapViewDelegate method to provide custom annotation views
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        if let cluster = annotation as? MKClusterAnnotation {
            let identifier = MKMapViewDefaultClusterAnnotationViewReuseIdentifier
            var clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? ClusterAnnotationView
            if clusterView == nil {
                clusterView = ClusterAnnotationView(annotation: cluster, reuseIdentifier: identifier)
            } else {
                clusterView?.annotation = cluster
            }
            
            return clusterView
        }
        if let imageAnnotation = annotation as? ImageAnnotation {
            let identifier = "ImageAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? ImageAnnotationView
            if annotationView == nil {
                annotationView = ImageAnnotationView(annotation: imageAnnotation, reuseIdentifier: identifier)
                annotationView?.clusteringIdentifier = "imageCluster"
            } else {
                annotationView?.annotation = imageAnnotation
                            // Important: Always re-set the clustering identifier when reusing a view
                            annotationView?.clusteringIdentifier = "imageCluster"
                
            }
            annotationView?.image = imageAnnotation.image
                    
                    // Make sure these properties are set consistently
                    annotationView?.collisionMode = .rectangle
                    annotationView?.displayPriority = .defaultHigh
                    
                    return annotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            // Make sure all ImageAnnotationViews have clustering enabled
            if let imageView = view as? ImageAnnotationView {
                imageView.clusteringIdentifier = "imageCluster"
            }
            
            // Add an animation for smoother appearance
            view.alpha = 0
            UIView.animate(withDuration: 0.3) {
                view.alpha = 1
            }
        }
    }
    // Add this to your MapViewModel class
    func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
        // If there's only one annotation or they're all duplicates, don't create a cluster
            if memberAnnotations.count == 1 {
                return MKClusterAnnotation(memberAnnotations: [])
            }
            
            // Check for duplicates by comparing coordinates
            var uniqueCoordinates = Set<String>()
            var uniqueAnnotations: [MKAnnotation] = []
            
            for annotation in memberAnnotations {
                let coordString = "\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)"
                if !uniqueCoordinates.contains(coordString) {
                    uniqueCoordinates.insert(coordString)
                    uniqueAnnotations.append(annotation)
                }
            }
            
            // If after removing duplicates we have only one annotation, don't cluster
            if uniqueAnnotations.count == 1 {
                return MKClusterAnnotation(memberAnnotations: [])
            }
            
            // Create a cluster with only unique annotations
            let clusterAnnotation = MKClusterAnnotation(memberAnnotations: uniqueAnnotations)
            clusterAnnotation.title = "\(uniqueAnnotations.count) Locations"
            return clusterAnnotation
    }
    
    
    
    
    
    
    
    
            
            // Show popup when annotation is selected
    // Show popup when annotation is selected
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let cluster = view.annotation as? MKClusterAnnotation {
            let alertController = UIAlertController(title: "Locations", message: "Contains \(cluster.memberAnnotations.count) locations", preferredStyle: .alert)
            
            // Create a custom view to hold all content
            let customView = UIView(frame: CGRect(x: 0, y: 0, width: 270, height: 300))
            
            // Create a scroll view to allow scrolling if many items
            let scrollView = UIScrollView(frame: CGRect(x: 10, y: 10, width: 250, height: 280))
            scrollView.showsVerticalScrollIndicator = true
            
            // Create a stack view for our content
            let contentStackView = UIStackView()
            contentStackView.axis = .vertical
            contentStackView.alignment = .fill
            contentStackView.distribution = .fillProportionally
            contentStackView.spacing = 15
            contentStackView.translatesAutoresizingMaskIntoConstraints = false
            
            // Calculate how tall our content will be
            var contentHeight: CGFloat = 0
            
            // Add each annotation's info to the stack view
            for annotation in cluster.memberAnnotations {
                if let imageAnnotation = annotation as? ImageAnnotation,
                   let image = imageAnnotation.image,
                   let title = imageAnnotation.title {
                   
                    let itemContainer = UIView()
                    itemContainer.translatesAutoresizingMaskIntoConstraints = false
                    
                    let nameLabel = UILabel()
                    nameLabel.text = title
                    nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
                    nameLabel.textColor = UIColor(red: 241/255, green: 90/255, blue: 35/255, alpha: 1)
                    nameLabel.translatesAutoresizingMaskIntoConstraints = false
                    
                    let imageView = UIImageView(image: image)
                    imageView.contentMode = .scaleAspectFill
                    imageView.layer.cornerRadius = 8
                    imageView.layer.masksToBounds = true
                    imageView.translatesAutoresizingMaskIntoConstraints = false
                    
                    // Add a tap gesture to open the annotation popup
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showAnnotationPopup(_:)))
                    itemContainer.addGestureRecognizer(tapGesture)
                    itemContainer.isUserInteractionEnabled = true
                    
                    // Store the annotation reference in the container's tag
                    if let index = cluster.memberAnnotations.firstIndex(where: { $0 === annotation }) {
                        itemContainer.tag = index
                    }
                    itemContainer.addSubview(nameLabel)
                    itemContainer.addSubview(imageView)
                    
                    NSLayoutConstraint.activate([
                        nameLabel.topAnchor.constraint(equalTo: itemContainer.topAnchor),
                        nameLabel.leadingAnchor.constraint(equalTo: itemContainer.leadingAnchor),
                        nameLabel.trailingAnchor.constraint(equalTo: itemContainer.trailingAnchor),
                        imageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
                        imageView.leadingAnchor.constraint(equalTo: itemContainer.leadingAnchor),
                        imageView.trailingAnchor.constraint(equalTo: itemContainer.trailingAnchor),
                        imageView.heightAnchor.constraint(equalToConstant: 120),
                        imageView.bottomAnchor.constraint(equalTo: itemContainer.bottomAnchor)
                    ])
                    
                    contentStackView.addArrangedSubview(itemContainer)
                    contentHeight += 145 // 20 for label + 120 for image + 5 spacing
                }
            }
            
            // Add the stack view to the scroll view
            scrollView.addSubview(contentStackView)
            
            // Configure stack view and scroll view content size
            NSLayoutConstraint.activate([
                contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            ])
            
            scrollView.contentSize = CGSize(width: 250, height: max(contentHeight, 280))
            
            // Add scroll view to custom view
            customView.addSubview(scrollView)
            
            // Add custom view to alert
            alertController.view.addSubview(customView)
            
            // Adjust the alert height
            let heightConstraint = NSLayoutConstraint(
                item: alertController.view!,
                attribute: .height,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1,
                constant: 350
            )
            alertController.view.addConstraint(heightConstraint)
            
            // Add close button
            alertController.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
            mapView.deselectAnnotation(cluster, animated: true)
        }
        // Rest of your existing code for regular annotations
        else if let annotation = view.annotation as? ImageAnnotation {
            // Your existing code for handling individual annotations...
            currentPopupView?.removeFromSuperview()
            let popupView = CustomPopupView()
            popupView.frame = CGRect(x: map.bounds.midX - 170, y: map.bounds.midY - 300, width: 350, height: 600)
            popupView.layer.cornerRadius = 10
            popupView.layer.masksToBounds = true
            popupView.setDetails(
                title: annotation.title ?? "Restaurant Name",
                image: annotation.image,
                reviewerName: annotation.author,
                rating: annotation.rating,
                comment: annotation.subtitle,
                star: annotation.rating,
                heart: annotation.heartC
            )
            map.addSubview(popupView)
            currentPopupView = popupView
            isPopupShown = true
        }
    }
            
            // Handle tap on the map to dismiss popup
            @objc func handleMapTap(_ recognizer: UITapGestureRecognizer) {
                let touchPoint = recognizer.location(in: map)
                
                // Check if the touch is outside the current popup view
                if let popupView = currentPopupView, !popupView.frame.contains(touchPoint) {
                    // Remove the popup
                    popupView.removeFromSuperview()
                    currentPopupView = nil
                    DispatchQueue.main.async {
                        self.isPopupShown = false
                    }
                }
            }
    
    
    @objc func showAnnotationPopup(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view,
              let cluster = map.selectedAnnotations.first as? MKClusterAnnotation,
              view.tag >= 0, view.tag < cluster.memberAnnotations.count,
              let annotation = cluster.memberAnnotations[view.tag] as? ImageAnnotation else { return }
        // Remove any existing popup
        currentPopupView?.removeFromSuperview()
        
        // Create a new popup view
        let popupView = CustomPopupView()
        popupView.frame = CGRect(x: map.bounds.midX - 170, y: map.bounds.midY - 300, width: 350, height: 600)
        popupView.layer.cornerRadius = 10
        popupView.layer.masksToBounds = true
        popupView.setDetails(
            title: annotation.title ?? "Restaurant Name",
            image: annotation.image,
            reviewerName: annotation.author,
            rating: annotation.rating,
            comment: annotation.subtitle,
            star: annotation.rating,
            heart: annotation.heartC
        )
        // Add the popup to the map
        map.addSubview(popupView)
        currentPopupView = popupView
        isPopupShown = true
    }
        }
        // Utility extension for MKMapView
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
//        extension Notification.Name {
//            static let postAdded = Notification.Name("postAdded")
//        }
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

