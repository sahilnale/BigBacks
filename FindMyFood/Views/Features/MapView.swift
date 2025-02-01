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
//
////Popup
//
//class CustomPopupView: UIView {
//    private let titleLabel = UILabel()
//    private let imageView = UIImageView()
//    private let reviewerNameLabel = UILabel()
//    private let commentLabel = UILabel()
//    private let heartContainer = UIView()
//    private let heartImageView = UIImageView()
//    private let heartCountLabel = UILabel()
//    private let ratingContainer = UIStackView()
//    private let starImageView = UIImageView()
//    private let ratingNumberLabel = UILabel()
//    private var starImageViews: [UIImageView] = []
//    
//    private var heartCount: Int = 0 {
//        didSet {
//            heartCountLabel.text = "\(heartCount)"
//        }
//    }
//    
//        private var starRating: Int = 0 {
//                    didSet { updateStars() }
//        }
//    
//    private let mapIconImageView = UIImageView()
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupView()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    private func setupView() {
//        // Background setup
//        let softCreamyWhite = UIColor(red: 1.0, green: 0.973, blue: 0.953, alpha: 1.0)
//        backgroundColor = softCreamyWhite
//        layer.cornerRadius = 20
//        layer.shadowColor = UIColor.black.cgColor
//        layer.shadowOpacity = 0.08
//        layer.shadowOffset = CGSize(width: 0, height: 6)
//        layer.shadowRadius = 10
//        
//        // Animation setup
//        transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
//        UIView.animate(withDuration: 0.4,
//                      delay: 0,
//                      usingSpringWithDamping: 0.6,
//                      initialSpringVelocity: 0.8,
//                      options: .curveEaseOut,
//                      animations: {
//            self.transform = .identity
//        })
//        
//        // Image View setup
//        imageView.contentMode = .scaleAspectFill
//        imageView.clipsToBounds = true
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Heart Container setup
//        heartContainer.backgroundColor = UIColor.black.withAlphaComponent(0.3)
//        heartContainer.layer.cornerRadius = 25
//        heartContainer.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Heart Icon setup
//        heartImageView.image = UIImage(systemName: "heart.fill")?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)
//        heartImageView.contentMode = .scaleAspectFit
//        heartImageView.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Heart Count Label setup
//        heartCountLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
//        heartCountLabel.textColor = .black
//        heartCountLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Rating Container setup
//        ratingContainer.axis = .horizontal
//        ratingContainer.spacing = 4
//        ratingContainer.alignment = .trailing
//        ratingContainer.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Star Image setup
//        let goldenYellow = UIColor(red: 255/255, green: 223/255, blue: 0/255, alpha: 1)
//        starImageView.image = UIImage(systemName: "star.fill")?.withTintColor(goldenYellow, renderingMode: .alwaysOriginal)
//        starImageView.contentMode = .scaleAspectFit
//        starImageView.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Rating Number Label setup
//        ratingNumberLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
//        ratingNumberLabel.textColor = .black
//        ratingNumberLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Other labels setup
//        titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .bold)
//        titleLabel.textColor = UIColor(Color.customOrange)
//        titleLabel.numberOfLines = 0
//        titleLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        reviewerNameLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
//        reviewerNameLabel.textColor = .gray
//        reviewerNameLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        commentLabel.font = UIFont.systemFont(ofSize: 14)
//        commentLabel.textColor = .gray
//        commentLabel.numberOfLines = 0
//        commentLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        mapIconImageView.image = UIImage(systemName: "mappin")?.withTintColor(.accentColor2, renderingMode: .alwaysOriginal) // A simple map icon
//        mapIconImageView.contentMode = .scaleAspectFit
//        mapIconImageView.translatesAutoresizingMaskIntoConstraints = false
//        mapIconImageView.isUserInteractionEnabled = true
//        
//        let stackView = UIStackView()
//        stackView.axis = .horizontal
//        stackView.spacing = 8
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//                
//        
//        stackView.addArrangedSubview(mapIconImageView)
//        stackView.addArrangedSubview(titleLabel)
//        
//        addSubview(stackView)
//        
//        // Add subviews
//        addSubview(imageView)
//        imageView.addSubview(heartContainer)
//        heartContainer.addSubview(heartImageView)
//        addSubview(heartCountLabel)
//        
//        ratingContainer.addArrangedSubview(starImageView)
//        ratingContainer.addArrangedSubview(ratingNumberLabel)
//        
//        
//        
//        addSubview(titleLabel)
//        addSubview(reviewerNameLabel)
//        addSubview(ratingContainer)
//        addSubview(commentLabel)
//        
//        // Add the map icon next to the restaurant name label
//        addSubview(mapIconImageView)
//        mapIconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openInAppleMaps)))
//        
//        NSLayoutConstraint.activate([
//            // Image View
//            imageView.topAnchor.constraint(equalTo: topAnchor),
//            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
//            imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.67),
//            
//            // Heart Container
//            heartContainer.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 16),
//            heartContainer.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -16),
//            heartContainer.widthAnchor.constraint(equalToConstant: 50),
//            heartContainer.heightAnchor.constraint(equalToConstant: 50),
//            
//            // Heart Icon
//            heartImageView.centerXAnchor.constraint(equalTo: heartContainer.centerXAnchor),
//            heartImageView.centerYAnchor.constraint(equalTo: heartContainer.centerYAnchor),
//            heartImageView.widthAnchor.constraint(equalToConstant: 30),
//            heartImageView.heightAnchor.constraint(equalToConstant: 30),
//            
//            // Heart Count Label (outside the circle)
//            heartCountLabel.leadingAnchor.constraint(equalTo: heartContainer.trailingAnchor, constant: 8),
//            heartCountLabel.centerYAnchor.constraint(equalTo: heartContainer.centerYAnchor),
//            
//            // Title and Reviewer Name
//            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
//            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
//            titleLabel.trailingAnchor.constraint(equalTo: ratingContainer.leadingAnchor, constant: -8),
//            
//            reviewerNameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
//            reviewerNameLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
//            reviewerNameLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
//            
//            // Rating Container
//            //ratingContainer.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
//            ratingContainer.topAnchor.constraint(equalTo: titleLabel.topAnchor), // Ensures alignment with title
//            ratingContainer.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
//            starImageView.widthAnchor.constraint(equalToConstant: 20),
//            starImageView.heightAnchor.constraint(equalToConstant: 20),
//            
//            // Comment Label
//            commentLabel.topAnchor.constraint(equalTo: reviewerNameLabel.bottomAnchor, constant: 16),
//            commentLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
//            commentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
//            commentLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16),
//            
//            mapIconImageView.leadingAnchor.constraint(equalTo: reviewerNameLabel.trailingAnchor, constant: 8),
//            mapIconImageView.centerYAnchor.constraint(equalTo: reviewerNameLabel.centerYAnchor),
//            mapIconImageView.widthAnchor.constraint(equalToConstant: 20),
//            mapIconImageView.heightAnchor.constraint(equalToConstant: 20),
//            
//            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
//            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
//            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
//        ])
//        
//        // Maps integration
//        titleLabel.isUserInteractionEnabled = true
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openInAppleMaps))
//        titleLabel.addGestureRecognizer(tapGesture)
//    }
//    
//    @objc private func openInAppleMaps() {
//        guard let title = titleLabel.text else { return }
//        
//        let request = MKLocalSearch.Request()
//        request.naturalLanguageQuery = title
//        
//        let search = MKLocalSearch(request: request)
//        search.start { response, error in
//            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
//            
//            let placemark = MKPlacemark(coordinate: coordinate)
//            let mapItem = MKMapItem(placemark: placemark)
//            mapItem.name = title
//            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
//        }
//    }
//
//
//    
//    private func updateStars() {
//            let goldenYellow = UIColor(red: 255/255, green: 223/255, blue: 0/255, alpha: 1) // Custom golden yellow color
//        let filledStarImage = UIImage(systemName: "star.fill")?.withTintColor(goldenYellow, renderingMode: .alwaysOriginal)
//            let emptyStarImage = UIImage(systemName: "star")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
//            
//            for (index, starImageView) in starImageViews.enumerated() {
//                starImageView.image = index < starRating ? filledStarImage : emptyStarImage
//            }
//        }
//    
//
//
//    func setDetails(title: String?, image: UIImage?, reviewerName: String?, rating: Int?, comment: String?, star: Int?, heart: Int?) {
//        
//        
////        titleLabel.text = title
////        imageView.image = image
////
////        reviewerNameLabel.text = "Reviewer: \(reviewerName)"
////        ratingLabel.text = "Rating: \(rating)"  // Set this only if used
////        commentLabel.text = comment
////
////        reviewerNameLabel.text = reviewerName
////        
////        commentLabel.text = comment
////        
////        starRating = star ?? 0
////        heartCount = heart ?? 0
//        
//        titleLabel.text = title
//                imageView.image = image
//                reviewerNameLabel.text = reviewerName
//                ratingNumberLabel.text = "\(rating ?? 0)"
//                commentLabel.text = comment
//                heartCount = heart ?? 0
//
//    }
//}
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
        heartCountLabel.textColor = .white  // Changed to black since it's outside now
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
class MapViewModel: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, ObservableObject {
    @Published var isPopupShown: Bool = false
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
            removeAllAnnotations()
            
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
                
//                  let heartC = userInfo["heartC"] as? Int else {
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
                print("this shit failed")
                return
            }
            let coordinateC = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            // Create annotation
            
            
            // Add annotation to map view
            
            print("About to add")
            addUserAnnotation(coordinate_in: coordinateC, title_in: title, review: review, image_in: image, author_in: author, rating_in: rating, heartC_in: likes)
            print("Done")
            
            
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
            
            // Optionally, adjust map view region to include the new annotation
            var region = self.map.region
            region.center = coordinate_in
            region.span.latitudeDelta = 0.05
            region.span.longitudeDelta = 0.05
            self.map.setRegion(region, animated: true)
        }
    
    
    //Load image annotation
    func loadImageAnnotation() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Failed to get user")
            return
        }

        do {
            let feed = try await AuthViewModel.shared.fetchPostDetailsFromFeed(userId: userId)

            for (post, user) in feed {
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
        isPopupShown = true
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
