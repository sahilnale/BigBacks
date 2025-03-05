import SwiftUI
import MapKit
import CoreLocation
import Firebase
import FirebaseAuth
import FirebaseFirestore
private var annotationMapKey: UInt8 = 0
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
class ClusterAnnotationView: MKAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            guard let cluster = newValue as? MKClusterAnnotation else { return }

            let totalAnnotations = cluster.memberAnnotations.count

            // Ensure we have a valid annotation image
            if let latestAnnotation = cluster.memberAnnotations.last as? ImageAnnotation,
               let latestImage = latestAnnotation.image {
                
                // Generate a fresh image for the cluster with the number in the bottom-right
                let clusterImage = generateClusterImage(baseImage: latestImage, text: "\(totalAnnotations)")
                image = clusterImage
            }

//            markerTintColor = .clear  // Hide default marker color
//            glyphText = nil           // Prevent numbers in the middle
//            displayPriority = .defaultLow // Ensures MapKit doesn't override our custom image

        }
    }

    private func generateClusterImage(baseImage: UIImage, text: String) -> UIImage {
        let size = CGSize(width: 50, height: 50)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Draw the base image (without any text in the middle)
            let circlePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            circlePath.addClip()
            baseImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            
            // Create a **solid black background** for the number
            let textBgSize: CGFloat = 20
            let textBgRect = CGRect(
                x: size.width - textBgSize - 4, // Right-aligned
                y: size.height - textBgSize - 4, // Bottom-aligned
                width: textBgSize,
                height: textBgSize
            )
            let bgPath = UIBezierPath(ovalIn: textBgRect)
            UIColor.black.setFill() // **Solid black background**
            bgPath.fill()

            // Draw the number inside the black circle
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: UIColor.white // White text for contrast
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: textBgRect.midX - textSize.width / 2,
                y: textBgRect.midY - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
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
        let nonUserAnnotations = map.annotations.filter { !($0 is MKUserLocation) }
        for annotation in nonUserAnnotations {
            map.removeAnnotation(annotation)
        }
        
        
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let cluster = view.annotation as? MKClusterAnnotation {
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)

                // Increase the size of the popup
                let popupView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 400)) //height is 400
                popupView.backgroundColor = .white
                popupView.layer.cornerRadius = 12
                popupView.layer.masksToBounds = true

                let titleLabel = UILabel()
                titleLabel.text = "Restaurants"
                titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
                titleLabel.textColor = .accentColor2
                titleLabel.textAlignment = .center
                titleLabel.translatesAutoresizingMaskIntoConstraints = false

                let scrollView = UIScrollView()
                scrollView.translatesAutoresizingMaskIntoConstraints = false
                scrollView.showsVerticalScrollIndicator = true

                let contentStackView = UIStackView()
                contentStackView.axis = .vertical
                contentStackView.alignment = .fill
                contentStackView.spacing = 10
                contentStackView.translatesAutoresizingMaskIntoConstraints = false

                var annotationMap: [UIView: ImageAnnotation] = [:]

                for annotation in cluster.memberAnnotations {
                    if let imageAnnotation = annotation as? ImageAnnotation {
                        let itemContainer = UIView()
                        itemContainer.translatesAutoresizingMaskIntoConstraints = false
                        itemContainer.layer.cornerRadius = 8
                        itemContainer.layer.borderWidth = 1
                        itemContainer.layer.borderColor = UIColor.lightGray.cgColor
                        itemContainer.backgroundColor = UIColor(white: 0.95, alpha: 1.0)

                        let imageView = UIImageView(image: imageAnnotation.image)
                        imageView.contentMode = .scaleAspectFill
                        imageView.layer.cornerRadius = 8
                        imageView.clipsToBounds = true
                        imageView.translatesAutoresizingMaskIntoConstraints = false

                        let nameLabel = UILabel()
                        nameLabel.text = imageAnnotation.title
                        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
                        nameLabel.textColor = .darkGray
                        nameLabel.textAlignment = .center
                        nameLabel.translatesAutoresizingMaskIntoConstraints = false

                        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showAnnotationPopup(_:)))
                        itemContainer.addGestureRecognizer(tapGesture)
                        itemContainer.isUserInteractionEnabled = true

                        annotationMap[itemContainer] = imageAnnotation

                        itemContainer.addSubview(imageView)
                        itemContainer.addSubview(nameLabel)

                        NSLayoutConstraint.activate([
                            imageView.topAnchor.constraint(equalTo: itemContainer.topAnchor),
                            imageView.leadingAnchor.constraint(equalTo: itemContainer.leadingAnchor),
                            imageView.trailingAnchor.constraint(equalTo: itemContainer.trailingAnchor),
                            imageView.heightAnchor.constraint(equalToConstant: 120),

                            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5),
                            nameLabel.leadingAnchor.constraint(equalTo: itemContainer.leadingAnchor),
                            nameLabel.trailingAnchor.constraint(equalTo: itemContainer.trailingAnchor),
                            nameLabel.bottomAnchor.constraint(equalTo: itemContainer.bottomAnchor)
                        ])

                        contentStackView.addArrangedSubview(itemContainer)
                    }
                }

                scrollView.addSubview(contentStackView)
                popupView.addSubview(titleLabel)
                popupView.addSubview(scrollView)

                NSLayoutConstraint.activate([
                    titleLabel.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 10),
                    titleLabel.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),

                    scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
                    scrollView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 10),
                    scrollView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -10),
                    scrollView.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -10),

                    contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                    contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                    contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                    contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                    contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
                ])

                let alertControllerHeight = NSLayoutConstraint(
                    item: alertController.view!,
                    attribute: .height,
                    relatedBy: .equal,
                    toItem: nil,
                    attribute: .notAnAttribute,
                    multiplier: 1,
                    constant: 450
                )
                alertController.view.addConstraint(alertControllerHeight)

                alertController.view.addSubview(popupView)
                alertController.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))

                self.present(alertController, animated: true, completion: nil)

                mapView.deselectAnnotation(cluster, animated: true)

                objc_setAssociatedObject(alertController, &annotationMapKey, annotationMap, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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
                  let topVC = self.presentedViewController as? UIAlertController,
                  let annotationMap = objc_getAssociatedObject(topVC, &annotationMapKey) as? [UIView: ImageAnnotation],
                  let annotation = annotationMap[view] else {
                print("🚨 Annotation not found in cluster!")
                return
            }

            print("✅ Clicked on annotation: \(annotation.title ?? "Unknown")")

            // Close the cluster popup
            topVC.dismiss(animated: true) {
                // Deselect the cluster annotation
                self.map.deselectAnnotation(topVC as? MKClusterAnnotation, animated: false)

                // Select the actual annotation after a slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    print("✅ Selecting annotation: \(annotation.title ?? "Unknown")")
                    self.map.selectAnnotation(annotation, animated: true)
                }
            }
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
    


