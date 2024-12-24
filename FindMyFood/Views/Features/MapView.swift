import SwiftUI
import MapKit
import CoreLocation
import Firebase
import FirebaseAuth
import FirebaseFirestore

// MARK: - Custom Annotation Class
class ImageAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var image: UIImage?
    var author: String?
    var rating: Int?
    var heartC: Int?
    
    // A unique postId (to avoid duplicates)
    var postId: String?
    
    init(coordinate: CLLocationCoordinate2D,
         title: String?,
         subtitle: String?,
         image: UIImage?,
         author: String?,
         rating: Int?,
         heartC: Int?,
         postId: String?) {
        
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.author = author
        self.rating = rating
        self.heartC = heartC
        self.postId = postId
    }
}

// MARK: - Custom Popup View
class CustomPopupView: UIView {
    private let titleLabel = UILabel()
    private let imageView = UIImageView()
    private let reviewerNameLabel = UILabel()
    private let ratingLabel = UILabel()   // Optional, if you want to display "Rating: x"
    private let commentScrollView = UIScrollView()
    private let commentLabel = UILabel()
    
    private let starStackView = UIStackView()
    private let heartImageView = UIImageView()
    private var heartCountLabel = UILabel()
    
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
        // Soft background
        let softCreamyWhite = UIColor(red: 1.0, green: 0.973, blue: 0.953, alpha: 1.0)
        backgroundColor = softCreamyWhite
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 10
        
        // Popup animation
        transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut,
                       animations: {
            self.transform = .identity
        }, completion: nil)
        
        // Title
        titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 22)
            ?? UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = UIColor.orange
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Reviewer
        reviewerNameLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        reviewerNameLabel.textColor = UIColor.gray
        reviewerNameLabel.textAlignment = .center
        reviewerNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Star stack
        starStackView.axis = .horizontal
        starStackView.spacing = 4
        starStackView.alignment = .center
        starStackView.translatesAutoresizingMaskIntoConstraints = false
        
        for _ in 0..<5 {
            let starImageView = UIImageView(
                image: UIImage(systemName: "star.circle.fill")?
                    .withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
            )
            starImageView.contentMode = .scaleAspectFit
            starImageView.translatesAutoresizingMaskIntoConstraints = false
            
            // Subtle scale animation
            UIView.animate(withDuration: 0.8,
                           delay: Double.random(in: 0...0.5),
                           options: [.autoreverse, .repeat],
                           animations: {
                starImageView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }, completion: nil)
            
            starStackView.addArrangedSubview(starImageView)
            starImageViews.append(starImageView)
        }
        
        // Heart + label
        heartImageView.image = UIImage(systemName: "heart.fill")?
            .withTintColor(.systemRed, renderingMode: .alwaysOriginal)
        heartImageView.contentMode = .scaleAspectFit
        heartImageView.translatesAutoresizingMaskIntoConstraints = false
        
        heartCountLabel.font = UIFont.systemFont(ofSize: 16)
        heartCountLabel.textColor = .black
        heartCountLabel.translatesAutoresizingMaskIntoConstraints = false
        heartCountLabel.text = "0"
        
        let starsAndHeartStackView = UIStackView(
            arrangedSubviews: [starStackView, heartImageView, heartCountLabel]
        )
        starsAndHeartStackView.axis = .horizontal
        starsAndHeartStackView.spacing = 8
        starsAndHeartStackView.alignment = .center
        starsAndHeartStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Comment label
        commentScrollView.showsVerticalScrollIndicator = false
        commentScrollView.translatesAutoresizingMaskIntoConstraints = false
        
        commentLabel.font = UIFont.systemFont(ofSize: 16, weight: .light)
        commentLabel.textColor = UIColor.gray
        commentLabel.numberOfLines = 0
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        commentScrollView.addSubview(commentLabel)
        
        // Add subviews
        addSubview(titleLabel)
        addSubview(imageView)
        addSubview(reviewerNameLabel)
        addSubview(starsAndHeartStackView)
        addSubview(commentScrollView)
        
        // Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.0),
            
            reviewerNameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            reviewerNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            reviewerNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            starsAndHeartStackView.topAnchor.constraint(
                equalTo: reviewerNameLabel.bottomAnchor,
                constant: 12
            ),
            starsAndHeartStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            commentScrollView.topAnchor.constraint(
                equalTo: starsAndHeartStackView.bottomAnchor,
                constant: 16
            ),
            commentScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            commentScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            commentScrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            
            commentLabel.topAnchor.constraint(equalTo: commentScrollView.topAnchor),
            commentLabel.leadingAnchor.constraint(equalTo: commentScrollView.leadingAnchor),
            commentLabel.trailingAnchor.constraint(equalTo: commentScrollView.trailingAnchor),
            commentLabel.bottomAnchor.constraint(equalTo: commentScrollView.bottomAnchor),
            commentLabel.widthAnchor.constraint(equalTo: commentScrollView.widthAnchor)
        ])
    }
    
    private func updateStars() {
        let goldenYellow = UIColor(red: 255/255, green: 223/255, blue: 0/255, alpha: 1)
        let filledStarImage = UIImage(systemName: "star.fill")?
            .withTintColor(goldenYellow, renderingMode: .alwaysOriginal)
        let emptyStarImage = UIImage(systemName: "star")?
            .withTintColor(.lightGray, renderingMode: .alwaysOriginal)
        
        for (index, starImageView) in starImageViews.enumerated() {
            starImageView.image = index < starRating ? filledStarImage : emptyStarImage
        }
    }
    
    func setDetails(title: String?,
                    image: UIImage?,
                    reviewerName: String?,
                    rating: Int?,
                    comment: String?,
                    star: Int?,
                    heart: Int?) {
        
        titleLabel.text = title
        imageView.image = image
        
        reviewerNameLabel.text = reviewerName
        ratingLabel.text = "Rating: \(rating ?? 0)"
        commentLabel.text = comment
        
        starRating = star ?? 0
        heartCount = heart ?? 0
    }
}

// MARK: - Single Annotation View (No System Pin)
class ImageAnnotationView: MKAnnotationView {
    private var imageView: UIImageView!
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        
        imageView = UIImageView(frame: bounds)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 5.0
        imageView.layer.masksToBounds = true
        addSubview(imageView)
        
        // Clustering
        clusteringIdentifier = "ImageCluster"
    }
    
    override var image: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Cluster Annotation View
class ClusterImageAnnotationView: MKAnnotationView {
    private let imageView = UIImageView()
    private let countLabel = UILabel()
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        // size 50×50
        frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        
        imageView.frame = bounds
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 5.0
        imageView.layer.masksToBounds = true
        addSubview(imageView)
        
        countLabel.textColor = .white
        countLabel.font = UIFont.boldSystemFont(ofSize: 14)
        countLabel.textAlignment = .center
        countLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        countLabel.layer.cornerRadius = 10
        countLabel.clipsToBounds = true
        addSubview(countLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        
        let labelSize = CGSize(width: 24, height: 24)
        let inset: CGFloat = 2
        countLabel.frame = CGRect(
            x: inset,
            y: inset,
            width: labelSize.width,
            height: labelSize.height
        )
    }
    
    func configure(with cluster: MKClusterAnnotation) {
        // Use a random image from the cluster
        if let randomAnn = cluster.memberAnnotations.randomElement() as? ImageAnnotation {
            imageView.image = randomAnn.image
        }
        // Number of annotations in cluster
        countLabel.text = "\(cluster.memberAnnotations.count)"
    }
}

// MARK: - Map View Model
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
        
        // 1. Register the custom cluster annotation view by reuseIdentifier
        map.register(
            ClusterImageAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: "ClusterImageAnnotation"
        )
        
        view.addSubview(map)
        
        // Location
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Map delegate
        map.delegate = self
        
        // Tap to dismiss popup
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(handleMapTap(_:))
        )
        map.addGestureRecognizer(tapGesture)
        
        // Notification observer for single-annotation addition
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAddUserAnnotationNotification(_:)),
            name: .postAdded,
            object: nil
        )
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // If you want a fresh reload each time, uncomment the next line:
        // removeAllAnnotations()
        
        Task {
            await loadImageAnnotation()
        }
    }
    
    // MARK: - Keep All Original Utility Methods
    func removeAllAnnotations() {
        map.removeAnnotations(map.annotations)
    }
    
    func removeSpecificAnnotation(annotation: MKAnnotation) {
        map.removeAnnotation(annotation)
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
    
    // MARK: - Notification: Add Single Post Annotation
    @objc func handleAddUserAnnotationNotification(_ notification: Notification) {
        Task {
            guard
                let userInfo = notification.userInfo,
                let author = userInfo["userId"] as? String,
                let imageIdentifier = userInfo["imageData"] as? String,
                let review = userInfo["review"] as? String,
                let coordinate = userInfo["location"] as? String,
                let title = userInfo["restaurantName"] as? String,
                let likes = userInfo["likes"] as? Int,
                let rating = userInfo["starRating"] as? Int,
                // We assume you have a unique 'postId'
                let postId = userInfo["postId"] as? String
            else {
                print("Guard failed for notification userInfo.")
                return
            }
            
            guard let imageUrl = URL(string: imageIdentifier) else {
                print("Invalid URL for post.")
                return
            }
            
            // Load image
            let image: UIImage? = await withCheckedContinuation { continuation in
                URLSession.shared.dataTask(with: imageUrl) { data, _, error in
                    if let data = data,
                       let fetchedImage = UIImage(data: data) {
                        continuation.resume(returning: fetchedImage)
                    } else {
                        print("Failed to fetch image, error: \(String(describing: error))")
                        continuation.resume(returning: nil)
                    }
                }.resume()
            }
            
            guard let finalImage = image else { return }
            
            // Parse coordinate
            let components = coordinate.split(separator: ",")
            guard
                components.count == 2,
                let latitude = Double(components[0].trimmingCharacters(in: .whitespaces)),
                let longitude = Double(components[1].trimmingCharacters(in: .whitespaces))
            else {
                print("Failed to parse location string.")
                return
            }
            let coordinateC = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            // Add if not duplicate
            addUserAnnotation(
                coordinate_in: coordinateC,
                title_in: title,
                review: review,
                image_in: finalImage,
                author_in: author,
                rating_in: rating,
                heartC_in: likes,
                postId: postId
            )
        }
    }
    
    // MARK: - Add Single User Annotation
    func addUserAnnotation(
        coordinate_in: CLLocationCoordinate2D,
        title_in: String,
        review: String,
        image_in: UIImage,
        author_in: String,
        rating_in: Int,
        heartC_in: Int,
        postId: String
    ) {
        // Check duplicates
        if map.annotations.contains(where: {
            guard let ann = $0 as? ImageAnnotation else { return false }
            return ann.postId == postId
        }) {
            print("Annotation already added for postId \(postId). Skipping.")
            return
        }
        
        let annotation = ImageAnnotation(
            coordinate: coordinate_in,
            title: title_in,
            subtitle: review,
            image: image_in,
            author: author_in,
            rating: rating_in,
            heartC: heartC_in,
            postId: postId
        )
        
        map.addAnnotation(annotation)
        
        // Optionally recenter on newly added
        var region = map.region
        region.center = coordinate_in
        region.span.latitudeDelta = 0.05
        region.span.longitudeDelta = 0.05
        map.setRegion(region, animated: true)
    }
    
    // MARK: - Load All Annotations (e.g. from Firebase)
    func loadImageAnnotation() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user.")
            return
        }
        
        do {
            // Suppose this fetch returns [(Post, User)] pairs
            let feed = try await AuthViewModel.shared.fetchPostDetailsFromFeed(userId: userId)
            
            for (post, user) in feed {
                guard let imageUrl = URL(string: post.imageUrl) else {
                    print("Invalid URL for post: \(post._id)")
                    continue
                }
                
                let image: UIImage? = await withCheckedContinuation { continuation in
                    URLSession.shared.dataTask(with: imageUrl) { data, _, error in
                        if let data = data, let fetchedImage = UIImage(data: data) {
                            continuation.resume(returning: fetchedImage)
                        } else {
                            print("Failed to fetch image for post: \(post._id)")
                            continuation.resume(returning: nil)
                        }
                    }.resume()
                }
                
                guard let finalImage = image else { continue }
                
                let locComponents = post.location.split(separator: ",")
                guard
                    locComponents.count == 2,
                    let latitude = Double(locComponents[0]),
                    let longitude = Double(locComponents[1])
                else {
                    print("Invalid location for post: \(post._id)")
                    continue
                }
                
                // Check duplicates
                if map.annotations.contains(where: { ann in
                    guard let a = ann as? ImageAnnotation else { return false }
                    return a.postId == post._id
                }) {
                    print("Skipping duplicate for postId: \(post._id)")
                    continue
                }
                
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let annotation = ImageAnnotation(
                    coordinate: coordinate,
                    title: post.restaurantName,
                    subtitle: post.review,
                    image: finalImage,
                    author: user.name,
                    rating: post.starRating,
                    heartC: post.likes,
                    postId: post._id
                )
                DispatchQueue.main.async {
                    self.map.addAnnotation(annotation)
                }
            }
        } catch {
            print("Error fetching posts: \(error)")
        }
    }
    
    // MARK: - CLLocationManagerDelegate
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
        print("Failed location: \(error.localizedDescription)")
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Skip user location
        if annotation is MKUserLocation { return nil }
        
        // If cluster, use our custom cluster
        if let cluster = annotation as? MKClusterAnnotation {
            let identifier = "ClusterImageAnnotation"
            var clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? ClusterImageAnnotationView
            if clusterView == nil {
                clusterView = ClusterImageAnnotationView(
                    annotation: cluster,
                    reuseIdentifier: identifier
                )
            } else {
                clusterView?.annotation = cluster
            }
            clusterView?.configure(with: cluster)
            return clusterView
        }
        
        // Otherwise, single annotation
        if let imageAnn = annotation as? ImageAnnotation {
            let identifier = "ImageAnnotation"
            var annView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? ImageAnnotationView
            if annView == nil {
                annView = ImageAnnotationView(annotation: imageAnn, reuseIdentifier: identifier)
            } else {
                annView?.annotation = imageAnn
            }
            annView?.image = imageAnn.image
            return annView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let selectedAnnotation = view.annotation else { return }
        
        // If cluster, optionally zoom in
        if let cluster = selectedAnnotation as? MKClusterAnnotation {
            let coords = cluster.memberAnnotations.map { $0.coordinate }
            var minLat = coords.map(\.latitude).min() ?? 0
            var maxLat = coords.map(\.latitude).max() ?? 0
            var minLon = coords.map(\.longitude).min() ?? 0
            var maxLon = coords.map(\.longitude).max() ?? 0
            
            let buffer: Double = 0.01
            minLat -= buffer
            maxLat += buffer
            minLon -= buffer
            maxLon += buffer
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2.0,
                longitude: (minLon + maxLon) / 2.0
            )
            let span = MKCoordinateSpan(
                latitudeDelta: (maxLat - minLat),
                longitudeDelta: (maxLon - minLon)
            )
            let region = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(region, animated: true)
            
            // Deselect cluster so you can tap individual images
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                mapView.deselectAnnotation(cluster, animated: false)
            }
            return
        }
        
        // If single annotation, show popup
        guard let ann = selectedAnnotation as? ImageAnnotation else { return }
        
        // Remove old popup
        currentPopupView?.removeFromSuperview()
        
        let popupView = CustomPopupView()
        popupView.frame = CGRect(x: map.bounds.midX - 170,
                                 y: map.bounds.midY - 300,
                                 width: 350,
                                 height: 600)
        popupView.layer.cornerRadius = 10
        popupView.layer.masksToBounds = true
        
        // Fill details
        popupView.setDetails(
            title: ann.title ?? "Restaurant Name",
            image: ann.image,
            reviewerName: ann.author,
            rating: ann.rating,
            comment: ann.subtitle,
            star: ann.rating,
            heart: ann.heartC
        )
        
        map.addSubview(popupView)
        currentPopupView = popupView
    }
    
    // Tap on map to dismiss popup
    @objc func handleMapTap(_ recognizer: UITapGestureRecognizer) {
        let touchPoint = recognizer.location(in: map)
        if let popupView = currentPopupView,
           !popupView.frame.contains(touchPoint) {
            popupView.removeFromSuperview()
            currentPopupView = nil
        }
    }
}

// MARK: - MKMapView Utility
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

// MARK: - Notification
extension Notification.Name {
    static let postAdded = Notification.Name("postAdded")
}

// MARK: - SwiftUI Wrapper
struct MapView: UIViewControllerRepresentable {
    let viewModel: MapViewModel
    
    func makeUIViewController(context: Context) -> MapViewModel {
        return viewModel
    }
    
    func updateUIViewController(_ uiViewController: MapViewModel, context: Context) {
        // handle updates if needed
    }
}
