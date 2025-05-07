import SwiftUI
import MapKit
import CoreLocation
import Firebase
import FirebaseAuth
import FirebaseFirestore
private var annotationMapKey: UInt8 = 0
// Custom annotation class



class RestaurantClusterPopupViewController: UIViewController {
    private let dimmingView = UIView()
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    
    private var imageAnnotations: [ImageAnnotation] = []
    private var onSelect: ((ImageAnnotation) -> Void)?
    private var navigationPath: NavigationPath?
    
    init(annotations: [ImageAnnotation], navigationPath: NavigationPath?, onSelect: @escaping (ImageAnnotation) -> Void) {
        self.imageAnnotations = annotations
        self.navigationPath = navigationPath
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        populateRestaurants()
    }
    
    private func setupViews() {
        // Set up main view
        view.backgroundColor = .clear
        
        // Set up dimming view
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmingView.alpha = 0
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add tap gesture to dismiss when tapping outside the container
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        dimmingView.addGestureRecognizer(tapGesture)
        
        // Set up container view
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        containerView.alpha = 0
        
        // Set up title label
        titleLabel.text = "Restaurants"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = UIColor(red: 241/255, green: 90/255, blue: 35/255, alpha: 1)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Set up close button
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .systemGray
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Set up scroll view
        scrollView.showsVerticalScrollIndicator = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set up content stack view
        contentStackView.axis = .vertical
        contentStackView.spacing = 16
        contentStackView.alignment = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews in the correct order
        view.addSubview(dimmingView)
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(closeButton)
        containerView.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Dimming view fills the entire screen
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Container view centered with fixed size
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            // Title label at the top
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Close button at the top right
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Scroll view takes the remaining space
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            
            // Content stack view fills the scroll view
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func populateRestaurants() {
        for annotation in imageAnnotations {
            let itemContainer = createRestaurantCard(for: annotation)
            contentStackView.addArrangedSubview(itemContainer)
        }
    }
    
    private func createRestaurantCard(for annotation: ImageAnnotation) -> UIView {
        print("Creating restaurant card for annotation with postId: \(annotation.postId ?? "nil")")
        
        // Create main container with shadow
        let cardContainer = UIView()
        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.backgroundColor = .clear
        
        // Inner container with rounded corners
        let itemContainer = UIView()
        itemContainer.translatesAutoresizingMaskIntoConstraints = false
        itemContainer.layer.cornerRadius = 16
        itemContainer.clipsToBounds = true
        itemContainer.backgroundColor = .systemBackground
        itemContainer.layer.masksToBounds = true
        
        // Add shadow to main container
        cardContainer.layer.shadowColor = UIColor.black.cgColor
        cardContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardContainer.layer.shadowRadius = 12
        cardContainer.layer.shadowOpacity = 0.1
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(restaurantCardTapped(_:)))
        itemContainer.addGestureRecognizer(tapGesture)
        itemContainer.isUserInteractionEnabled = true
        
        // Store the annotation reference on the itemContainer
        objc_setAssociatedObject(itemContainer, UnsafeRawPointer(bitPattern: 1)!, annotation, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        // Create image view with increased height
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        if let image = annotation.images.first {
            imageView.image = image
        } else {
            let configuration = UIImage.SymbolConfiguration(pointSize: 32, weight: .light)
            imageView.image = UIImage(systemName: "fork.knife", withConfiguration: configuration)
            imageView.tintColor = .systemGray3
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = UIColor.systemGray6
        }
        
        // Content container for text info
        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.backgroundColor = .systemBackground
        
        // Create title label with better typography
        let nameLabel = UILabel()
        nameLabel.text = annotation.title
        nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Category label
        let categoryLabel = UILabel()
        categoryLabel.text = annotation.subtitle ?? "Restaurant"
        categoryLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        categoryLabel.textColor = .secondaryLabel
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Create modern rating view
        let ratingContainer = UIView()
        ratingContainer.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        ratingContainer.layer.cornerRadius = 8
        ratingContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let ratingStack = UIStackView()
        ratingStack.axis = .horizontal
        ratingStack.spacing = 4
        ratingStack.alignment = .center
        ratingStack.translatesAutoresizingMaskIntoConstraints = false
        ratingStack.isLayoutMarginsRelativeArrangement = true
        ratingStack.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        let starIcon = UIImageView(image: UIImage(systemName: "star.fill"))
        starIcon.tintColor = UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1)
        starIcon.contentMode = .scaleAspectFit
        starIcon.translatesAutoresizingMaskIntoConstraints = false

        let ratingLabel = UILabel()
        ratingLabel.text = annotation.rating != nil ? "\(annotation.rating!)" : "N/A"
        ratingLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        ratingLabel.textColor = .white
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews to rating stack
        ratingStack.addArrangedSubview(starIcon)
        ratingStack.addArrangedSubview(ratingLabel)
        ratingContainer.addSubview(ratingStack)

        // Badge for status or promotion (optional)
        

        // Add subviews
        contentContainer.addSubview(nameLabel)
        contentContainer.addSubview(categoryLabel)
        
        // Only add ratingContainer if annotation has a rating
        if annotation.rating != nil {
            contentContainer.addSubview(ratingContainer)
        }

        itemContainer.addSubview(imageView)
        itemContainer.addSubview(contentContainer)

        // Badge is conditionally added
       
        
        // Add itemContainer to cardContainer
        cardContainer.addSubview(itemContainer)

        // Setup constraints
        NSLayoutConstraint.activate([
            cardContainer.heightAnchor.constraint(equalToConstant: 220),

            itemContainer.topAnchor.constraint(equalTo: cardContainer.topAnchor),
            itemContainer.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
            itemContainer.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),
            itemContainer.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: itemContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: itemContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: itemContainer.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: itemContainer.heightAnchor, multiplier: 0.7),

            contentContainer.topAnchor.constraint(equalTo: imageView.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: itemContainer.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: itemContainer.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: itemContainer.bottomAnchor),

            nameLabel.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: ratingContainer.leadingAnchor, constant: -8),

            categoryLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            categoryLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            categoryLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentContainer.trailingAnchor, constant: -16),
        ])

        // Add constraints only if ratingContainer exists
        if annotation.rating != nil {
            NSLayoutConstraint.activate([
                ratingContainer.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
                ratingContainer.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),

                ratingStack.topAnchor.constraint(equalTo: ratingContainer.topAnchor),
                ratingStack.leadingAnchor.constraint(equalTo: ratingContainer.leadingAnchor),
                ratingStack.trailingAnchor.constraint(equalTo: ratingContainer.trailingAnchor),
                ratingStack.bottomAnchor.constraint(equalTo: ratingContainer.bottomAnchor),

                starIcon.widthAnchor.constraint(equalToConstant: 14),
                starIcon.heightAnchor.constraint(equalToConstant: 14)
            ])
        }

        // Conditional constraints for badge
        

        return cardContainer
    }
    
    

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update gradient layer frames after layout
        for case let itemContainer as UIView in contentStackView.arrangedSubviews {
            if let overlayView = itemContainer.subviews.first(where: { $0 != $0.subviews.first }) {
                if let gradientLayer = overlayView.layer.sublayers?.first as? CAGradientLayer {
                    gradientLayer.frame = overlayView.bounds
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Animate the appearance
        UIView.animate(withDuration: 0.3) {
            self.dimmingView.alpha = 1.0
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.containerView.alpha = 1.0
            self.containerView.transform = .identity
        }
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func handleBackgroundTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: view)
        if !containerView.frame.contains(location) {
            dismiss(animated: true)
        }
    }
    
    @objc private func restaurantCardTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        print("Restaurant card tapped")
        guard let itemContainer = gestureRecognizer.view,
              let annotation = objc_getAssociatedObject(itemContainer, UnsafeRawPointer(bitPattern: 1)!) as? ImageAnnotation else {
            print("Failed to get annotation from tapped view")
            return
        }
        
        print("Found annotation with postId: \(annotation.postId ?? "nil")")
        
        // Ensure we have a valid post ID
        guard let postId = annotation.postId, !postId.isEmpty else {
            print("Invalid post ID")
            return
        }
        
        // Create Post object from annotation data
        let post = Post(
            _id: postId,
            userId: annotation.author ?? "",
            imageUrls: annotation.imageUrls,
            timestamp: Timestamp(date: Date()),
            review: annotation.subtitle ?? "",
            location: "\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)",
            restaurantName: annotation.title ?? "",
            likes: annotation.heartC ?? 0,
            likedBy: [],
            starRating: annotation.rating ?? 0,
            comments: []
        )
        
        print("Created post for restaurant: \(post.restaurantName)")
        
        // First call the onSelect closure
        onSelect?(annotation)
        
        // Then dismiss the popup
        dismiss(animated: true)
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if flag {
            UIView.animate(withDuration: 0.2, animations: {
                self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.containerView.alpha = 0
                self.dimmingView.alpha = 0
            }) { _ in
                super.dismiss(animated: false, completion: completion)
            }
        } else {
            super.dismiss(animated: false, completion: completion)
        }
    }
}


class ImageAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var imageUrls: [String] // Change to an array
    var images: [UIImage] = [] // Store downloaded images
    var author: String?
    var rating: Int?
    var heartC: Int?
    var postId: String?
    
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, imageUrls: [String], author: String?, rating: Int?, heartC: Int?, postId: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.imageUrls = imageUrls
        self.author = author
        self.rating = rating
        self.heartC = heartC
        self.postId = postId
        
    }
}

// Custom cluster annotation view
class ClusterAnnotationView: MKAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.collisionMode = .rectangle
        self.displayPriority = .defaultHigh
        self.frame = CGRect(x: 0, y: 0, width: 65, height: 65)
        
        // Add a distinctive border
        self.layer.borderWidth = 3
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.cornerRadius = 12
        self.layer.masksToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var annotation: MKAnnotation? {
        didSet {
            guard let cluster = annotation as? MKClusterAnnotation else { return }
            
            if let latestAnnotation = cluster.memberAnnotations.last as? ImageAnnotation {
                print("Cluster member annotations: \(cluster.memberAnnotations.count)")
                print("Latest annotation postId: \(latestAnnotation.postId ?? "nil")")
                
                if let latestImage = latestAnnotation.images.first {
                    let clusterImage = generateClusterImage(
                        baseImage: latestImage,
                        text: "\(cluster.memberAnnotations.count)"
                    )
                    self.image = clusterImage
                }
            }
        }
    }

    private func generateClusterImage(baseImage: UIImage, text: String) -> UIImage {
        let size = CGSize(width: 65, height: 65)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Draw the base image with proper aspect ratio (cropped, not squished)
            let squarePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: size.height), cornerRadius: 12)
            context.cgContext.saveGState()
            squarePath.addClip()
            
            // Calculate proper drawing rect to ensure image fills the entire area
            let imageSize = baseImage.size
            var drawRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            // Determine scale factor to ensure the image completely fills the annotation
            let imageAspect = imageSize.width / imageSize.height
            let targetAspect = size.width / size.height
            
            if imageAspect > targetAspect {
                // Image is wider than target - scale based on height and crop width
                let scaledWidth = size.height * imageAspect
                let xOffset = (size.width - scaledWidth) / 2
                drawRect = CGRect(x: xOffset, y: 0, width: scaledWidth, height: size.height)
            } else {
                // Image is taller than target or same aspect - scale based on width and crop height
                let scaledHeight = size.width / imageAspect
                let yOffset = (size.height - scaledHeight) / 2
                drawRect = CGRect(x: 0, y: yOffset, width: size.width, height: scaledHeight)
            }
            
            // Draw the image with proper aspect ratio
            baseImage.draw(in: drawRect)
            context.cgContext.restoreGState()
            
            // Create a solid black background for the number that will be drawn on top
            // Adjust size and position for better proportions
            let textBgSize: CGFloat = 22
            let textBgRect = CGRect(
                x: size.width - textBgSize - 6,
                y: size.height - textBgSize - 6,
                width: textBgSize,
                height: textBgSize
            )
            
            // Draw a shadow for the badge to make it stand out
            context.cgContext.setShadow(offset: CGSize(width: 0, height: 1), blur: 3, color: UIColor.black.withAlphaComponent(0.5).cgColor)
            
            // Draw the black circle with a white border
            let bgPath = UIBezierPath(ovalIn: textBgRect)
            UIColor.black.setFill()
            bgPath.fill()
            
            // Clear the shadow for the border and text
            context.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
            
            // Add a small white border around the count indicator
            let borderPath = UIBezierPath(ovalIn: textBgRect)
            borderPath.lineWidth = 1.5
            UIColor.white.setStroke()
            borderPath.stroke()

            // Draw the number inside the black circle
            // Adjust font size based on the number of digits
            let fontSize: CGFloat = text.count > 2 ? 11 : 13
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: fontSize),
                .foregroundColor: UIColor.white
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
    // Original variable names preserved
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
    private let scrollView = UIScrollView()
    private let pageControl = UIPageControl()
    private var imageViews: [UIImageView] = []
    
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
        layer.cornerRadius = 16
        layer.masksToBounds = true
        
        // Add subtle shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowRadius = 10
        layer.shadowOpacity = 0.1
        
        setupSubviews()
        setupConstraints()
    }
    
    private func setupSubviews() {
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.masksToBounds = true
        
        // ScrollView setup
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // PageControl setup
        pageControl.hidesForSinglePage = true
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor.lightGray
        pageControl.currentPageIndicatorTintColor = UIColor(red: 241/255, green: 90/255, blue: 35/255, alpha: 1)
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)
        addSubview(pageControl)
        
        // Image View
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title Container
        titleContainer.axis = .horizontal
        titleContainer.spacing = 8
        titleContainer.alignment = .center
        titleContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = UIColor(red: 241/255, green: 90/255, blue: 35/255, alpha: 1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.lineBreakMode = .byTruncatingTail
        
        // Map Icon
        mapIconImageView.image = UIImage(systemName: "mappin.circle.fill")?.withTintColor(UIColor(red: 241/255, green: 90/255, blue: 35/255, alpha: 1), renderingMode: .alwaysOriginal)
        mapIconImageView.contentMode = .scaleAspectFit
        mapIconImageView.translatesAutoresizingMaskIntoConstraints = false
        mapIconImageView.isUserInteractionEnabled = true
        mapIconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openInAppleMaps)))
        
        // Rating Container
        ratingContainer.axis = .horizontal
        ratingContainer.spacing = 4
        ratingContainer.alignment = .center
        ratingContainer.translatesAutoresizingMaskIntoConstraints = false
        ratingContainer.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        ratingContainer.layer.cornerRadius = 12
        ratingContainer.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        ratingContainer.isLayoutMarginsRelativeArrangement = true
        
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
                starImageView.widthAnchor.constraint(equalToConstant: 16),
                starImageView.heightAnchor.constraint(equalToConstant: 16)
            ])
        }
        
        // Reviewer Name
        reviewerNameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        reviewerNameLabel.textColor = .gray
        reviewerNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Comment
        commentLabel.font = .systemFont(ofSize: 16, weight: .regular)
        commentLabel.textColor = .darkGray
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
        addSubview(heartContainer)
        heartContainer.addSubview(heartImageView)
        heartContainer.addSubview(heartCountLabel)
        
        // Add the rating container on top of the image
        addSubview(ratingContainer)
        
        addSubview(titleContainer)
        titleContainer.addArrangedSubview(titleLabel)
        titleContainer.addArrangedSubview(mapIconImageView)
        addSubview(reviewerNameLabel)
        addSubview(commentLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.67),
            
            // PageControl
            pageControl.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -10),
            pageControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            // Image
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.67),
            
            // Rating Container
            ratingContainer.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -16),
            ratingContainer.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -16),
            
            // Title Container
            titleContainer.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            titleContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleContainer.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            
            // Map Icon
            mapIconImageView.widthAnchor.constraint(equalToConstant: 24),
            mapIconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Reviewer Name
            reviewerNameLabel.topAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: 12),
            reviewerNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            reviewerNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
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
        let emptyStarImage = UIImage(systemName: "star")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        
        for (index, starImageView) in starImageViews.enumerated() {
            starImageView.image = index < starRating ? filledStarImage : emptyStarImage
        }
    }
    
    func setDetails(title: String?, images: [UIImage], reviewerName: String?, rating: Int?, comment: String?, star: Int?, heart: Int?) {
        titleLabel.text = title
        reviewerNameLabel.text = "@" + (reviewerName ?? "friend")
        starRating = star ?? rating ?? 0
        commentLabel.text = comment
        heartCount = heart ?? 0
        
        // Remove old images before adding new ones
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()

        // Update page control
        pageControl.numberOfPages = images.count
        pageControl.currentPage = 0

        // Image height (2/3 of the popup height)
        let imageHeight = bounds.height * 0.67
        
        // Set up image scroll view
        for (index, image) in images.enumerated() {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            
            // Add gradient overlay for better readability
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                UIColor.black.withAlphaComponent(0.0).cgColor,
                UIColor.black.withAlphaComponent(0.3).cgColor
            ]
            gradientLayer.locations = [0.7, 1.0]
            gradientLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: imageHeight)
            
            let overlayView = UIView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: imageHeight))
            overlayView.layer.addSublayer(gradientLayer)
            
            let containerView = UIView(frame: CGRect(x: CGFloat(index) * bounds.width, y: 0, width: bounds.width, height: imageHeight))
            containerView.addSubview(imageView)
            containerView.addSubview(overlayView)
            
            imageView.frame = containerView.bounds
            overlayView.frame = containerView.bounds
            
            scrollView.addSubview(containerView)
            imageViews.append(imageView)
        }

        scrollView.contentSize = CGSize(width: bounds.width * CGFloat(images.count), height: imageHeight)
    }
}

extension CustomPopupView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x / bounds.width)
        pageControl.currentPage = Int(pageIndex)
    }
}











// MARK: - ViewModel
struct RestaurantReviewViewModel {
    let restaurantName: String
    let images: [UIImage]
    let rating: Int
    let username: String
    let userImage: UIImage?
    let reviewText: String
    let likeCount: Int
    
    init(restaurantName: String,
         images: [UIImage],
         rating: Int,
         username: String,
         userImage: UIImage? = nil,
         reviewText: String,
         likeCount: Int = 0) {
        self.restaurantName = restaurantName
        self.images = images
        self.rating = rating
        self.username = username
        self.userImage = userImage
        self.reviewText = reviewText
        self.likeCount = likeCount
    }
}

// Usage Example:
//
// let viewModel = RestaurantReviewViewModel(
//     restaurantName: "Sisterita",
//     images: [UIImage(named: "restaurant1")!, UIImage(named: "restaurant2")!],
//     rating: 5,
//     username: "@ridhima",
//     reviewText: "what an underrated spot near fidi cute little cafe",
//     likeCount: 42
// )
//
// let card = CustomPopupView(frame: CGRect(x: 0, y: 0, width: 375, height: 500))
// card.configure(with: viewModel)
// view.addSubview(card)

// Usage Example:
//
// let viewModel = RestaurantReviewViewModel(
//     restaurantName: "Sisterita",
//     images: [UIImage(named: "restaurant1")!, UIImage(named: "restaurant2")!],
//     rating: 5,
//     username: "@ridhima",
//     reviewText: "what an underrated spot near fidi cute little cafe",
//     likeCount: 42
// )
//
// let card = CustomPopupView(frame: CGRect(x: 0, y: 0, width: 375, height: 500))
// card.configure(with: viewModel)
// view.addSubview(card)


// Custom annotation view with clustering support
class ImageAnnotationView: MKAnnotationView {
    private var imageView: UIImageView!
    private var activityIndicator: UIActivityIndicatorView!
    private var isLoadingImage: Bool = false
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        self.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        
        // Initialize image view
        self.imageView = UIImageView(frame: self.bounds)
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
        self.imageView.layer.cornerRadius = 12
        self.imageView.layer.masksToBounds = true
        self.addSubview(self.imageView)
        
        // Add loading indicator
        self.activityIndicator = UIActivityIndicatorView(style: .medium)
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        self.addSubview(self.activityIndicator)
        
        // Set clustering identifier only once during initialization
        self.clusteringIdentifier = "imageCluster"
        self.collisionMode = .rectangle
        self.displayPriority = .defaultHigh
        
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.cornerRadius = 12
        self.layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var image: UIImage? {
        get { return self.imageView.image }
        set {
            if newValue == nil && !isLoadingImage {
                // If no image is set and we're not loading, show loading indicator
                self.activityIndicator.startAnimating()
                isLoadingImage = true
            } else if newValue != nil {
                // Image is set, stop loading indicator
                self.activityIndicator.stopAnimating()
                isLoadingImage = false
                self.imageView.image = newValue
                
                // Animate the image appearance
                self.imageView.alpha = 0
                UIView.animate(withDuration: 0.3) {
                    self.imageView.alpha = 1
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        self.activityIndicator.stopAnimating()
        isLoadingImage = false
    }
}
// Map View Model
class MapViewModel: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, ObservableObject {
    @Published var isPopupShown: Bool = false
    @Published var isLoadingAnnotations: Bool = false
    @Published var navigationPath: NavigationPath? {
        didSet {
            if let path = navigationPath {
                print("Navigation path updated with \(path.count) items")
                // Notify SwiftUI of the change
                objectWillChange.send()
            }
        }
    }
    
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
    private var loadTask: Task<Void, Never>?
    private var cachedAnnotations = [String: ImageAnnotation]()
    
    // Use a more comprehensive tracking system for annotations
    private var addedAnnotationIDs = Set<String>() // Just track IDs
    private var displayedAnnotations = [String: ImageAnnotation]() // Track actual annotations by ID
    
    // Helper method to navigate to PostView
    private func navigateToPostView(with post: Post) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if var navigationPath = self.navigationPath {
                navigationPath.append(post)
                self.navigationPath = navigationPath
                print("Appending post to navigation path: \(post.restaurantName)")
            } else {
                // If no navigation path exists, create a new one
                var newPath = NavigationPath()
                newPath.append(post)
                self.navigationPath = newPath
                print("Created new navigation path with post: \(post.restaurantName)")
            }
        }
    }
    
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
        
        // Add observer for deleting posts
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeletePostNotification(_:)),
            name: .postDeleted,
            object: nil
        )
        
        // Start loading annotations immediately
        loadCachedAnnotationsAndRefresh()
    }
    
    // Load cached annotations and then refresh with new ones
    private func loadCachedAnnotationsAndRefresh() {
        // Cancel any existing task
        loadTask?.cancel()
        
        // Clear any existing annotations
        clearAllAnnotations()
        
        // Start a new loading task
        loadTask = Task {
            isLoadingAnnotations = true
            
            // First try to load from cache
            let loadedFromCache = await loadAnnotationsFromCache()
            
            // Then refresh from the network only if needed
            guard let userId = Auth.auth().currentUser?.uid else {
                isLoadingAnnotations = false
                return
            }
            
            // Check if we need to refresh based on cache age
            let needsRefresh = !loadedFromCache || AnnotationDataCache.shared.needsRefresh(for: userId, maxAge: 900) // 15 minutes
            
            if needsRefresh {
                print("Cache is stale or empty, fetching from network")
                await refreshAnnotationsFromNetwork()
            } else {
                print("Using cached annotations, network refresh not needed")
            }
            
            isLoadingAnnotations = false
        }
    }
    
    // Clear all annotations properly
    private func clearAllAnnotations() {
        DispatchQueue.main.async {
            // Remove all non-user location annotations from the map
            let annotationsToRemove = self.map.annotations.filter { !($0 is MKUserLocation) }
            self.map.removeAnnotations(annotationsToRemove)
            
            // Clear our tracking dictionaries
            self.displayedAnnotations.removeAll()
            self.addedAnnotationIDs.removeAll()
        }
    }
    
    // Load annotations from cache
    private func loadAnnotationsFromCache() async -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Failed to get user ID")
            return false
        }
        
        if let cachedAnnotations = AnnotationDataCache.shared.loadAnnotations(for: userId) {
            self.cachedAnnotations = cachedAnnotations
            
            // Add cached annotations to the map
            DispatchQueue.main.async {
                for (id, annotation) in cachedAnnotations {
                    // Skip if we've already added this annotation (shouldn't happen here, but safety check)
                    if self.addedAnnotationIDs.contains(id) {
                        continue
                    }
                    
                    // Skip if the annotation has no post ID
                    guard let postId = annotation.postId, !postId.isEmpty else {
                        print("Skipping cached annotation with empty post ID")
                        continue
                    }
                    
                    // We need to create a new instance to avoid reference issues
                    let newAnnotation = ImageAnnotation(
                        coordinate: annotation.coordinate,
                        title: annotation.title,
                        subtitle: annotation.subtitle,
                        imageUrls: annotation.imageUrls,
                        author: annotation.author,
                        rating: annotation.rating,
                        heartC: annotation.heartC,
                        postId: postId // Ensure we pass the post ID
                    )
                    
                    // Load image from disk cache if available
                    if let imageUrlString = annotation.imageUrls.first,
                       let cachedImage = ImageCacheManager.shared.retrieveImage(for: imageUrlString) {
                        newAnnotation.images = [cachedImage]
                    } else {
                        // Start loading images in the background
                        Task {
                            await self.loadImagesForAnnotation(newAnnotation)
                        }
                    }
                    
                    // Add to map
                    self.map.addAnnotation(newAnnotation)
                    
                    // Track this annotation
                    self.addedAnnotationIDs.insert(id)
                    self.displayedAnnotations[id] = newAnnotation
                }
                
                print("Loaded \(self.displayedAnnotations.count) annotations from cache")
            }
            
            // Start prefetching images
            AnnotationDataCache.shared.prefetchImages(for: Array(cachedAnnotations.values))
            return true
        }
        return false
    }
    
    // Load images for an annotation
    private func loadImagesForAnnotation(_ annotation: ImageAnnotation) async {
        var loadedImages: [UIImage] = []
        
        for imageUrlString in annotation.imageUrls {
            guard let imageUrl = URL(string: imageUrlString) else { continue }
            
            if let image = await ImageCacheManager.shared.loadImageAsync(from: imageUrl) {
                loadedImages.append(image)
                
                // Update the annotation's first image as soon as we have one
                if loadedImages.count == 1 {
                    annotation.images = loadedImages
                    
                    DispatchQueue.main.async {
                        if let annotationView = self.map.view(for: annotation) as? ImageAnnotationView {
                            annotationView.image = loadedImages.first
                        }
                    }
                }
            }
        }
        
        // Update with all images once we have them all
        if loadedImages.count > 1 {
            annotation.images = loadedImages
        }
    }
    
    // Refresh annotations from network
    private func refreshAnnotationsFromNetwork() async {
        await loadImageAnnotation()
    }
    
    deinit {
        // Remove notification observers when view model is deallocated
        NotificationCenter.default.removeObserver(self)
        
        // Cancel any pending task when view model is deallocated
        loadTask?.cancel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // If there are no annotations, try loading them again
        if map.annotations.count <= 1 { // account for user location annotation
            loadCachedAnnotationsAndRefresh()
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
        
        // Don't force recalculation of clusters here - let MapKit handle it naturally
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
        
        // We don't need to reload in viewDidAppear since we're already loading in viewWillAppear
        // when needed. This was causing duplicate annotations.
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
                  let authorId = userInfo["userId"] as? String,
                  let imageIdentifiers = userInfo["imageData"] as? [String],
                  let review = userInfo["review"] as? String,
                  let coordinate = userInfo["location"] as? String,
                  let title = userInfo["restaurantName"] as? String,
                  let likes = userInfo["likes"] as? Int,
                  let postId = userInfo["postId"] as? String,
                  let rating = userInfo["starRating"] as? Int else {
                print("Guard failed")
                return
            }
            
            // Fetch user details to get the username
            let username: String
            do {
                if let user = try await AuthViewModel.shared.getUserById(friendId: authorId) {
                    username = user.username
                } else {
                    username = "@user" // Fallback if user not found
                }
            } catch {
                print("Error fetching user details: \(error)")
                username = "@user" // Fallback username
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
            
            // Use postId as the annotationId
            let annotationId = postId
            
            // Check if this annotation is already on the map
            if addedAnnotationIDs.contains(annotationId) {
                print("Annotation already exists, skipping")
                return
            }
            
            // Create the annotation with a placeholder initially
            let annotation = ImageAnnotation(
                coordinate: coordinateC,
                title: title,
                subtitle: review,
                imageUrls: imageIdentifiers,
                author: username,
                rating: rating,
                heartC: likes,
                postId: postId
            )
            
            // Add to the map immediately
            DispatchQueue.main.async {
                self.map.addAnnotation(annotation)
                
                // Track this annotation
                self.addedAnnotationIDs.insert(annotationId)
                self.displayedAnnotations[annotationId] = annotation
                
                // Adjust map view region to include the new annotation
                var region = self.map.region
                region.center = coordinateC
                region.span.latitudeDelta = 0.05
                region.span.longitudeDelta = 0.05
                self.map.setRegion(region, animated: true)
            }
            
            // Load images in the background
            await loadImagesForAnnotation(annotation)
            
            // Add to cached annotations
            if let userId = Auth.auth().currentUser?.uid {
                self.cachedAnnotations[annotationId] = annotation
                AnnotationDataCache.shared.saveAnnotations(self.cachedAnnotations, for: userId)
            }
            
            print("Done adding annotation")
        }
    }
    
    func loadImageAnnotation() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Failed to get user")
            return
        }
        
        do {
            let feed = try await AuthViewModel.shared.fetchPostDetailsFromFeed(userId: userId)
            print("Fetched feed with \(feed.count) posts")
            
            // Check if task was cancelled while waiting for the feed
            if Task.isCancelled { return }
            
            // Process the feed and update annotations
            var newAnnotations = [String: ImageAnnotation]()
            var newIDs = Set<String>()
            
            // Clear existing annotations first
            DispatchQueue.main.async {
                self.map.removeAnnotations(self.map.annotations.filter { !($0 is MKUserLocation) })
                self.displayedAnnotations.removeAll()
                self.addedAnnotationIDs.removeAll()
            }
            
            for (post, user) in feed {
                let annotationID = post._id
                print("Processing post with ID: \(annotationID)")
                
                // Skip if the post ID is empty
                guard !annotationID.isEmpty else {
                    print("Skipping post with empty ID")
                    continue
                }
                
                newIDs.insert(annotationID)
                
                // Parse location
                let locationComponents = post.location.split(separator: ",")
                guard locationComponents.count == 2,
                      let latitude = Double(locationComponents[0]),
                      let longitude = Double(locationComponents[1]) else {
                    print("Failed to parse location for post: \(annotationID)")
                    continue
                }
                
                let annotationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                
                // Create the annotation
                let annotation = ImageAnnotation(
                    coordinate: annotationCoordinate,
                    title: post.restaurantName,
                    subtitle: post.review,
                    imageUrls: post.imageUrls,
                    author: user.username,
                    rating: post.starRating,
                    heartC: post.likes,
                    postId: annotationID
                )
                
                print("Created annotation with postId: \(annotation.postId ?? "nil")")
                
                // Add to the map immediately
                DispatchQueue.main.async {
                    self.map.addAnnotation(annotation)
                    
                    // Track this annotation
                    self.addedAnnotationIDs.insert(annotationID)
                    self.displayedAnnotations[annotationID] = annotation
                }
                
                // Store in our new annotations dictionary
                newAnnotations[annotationID] = annotation
                
                // Load images asynchronously
                Task {
                    await loadImagesForAnnotation(annotation)
                }
            }
            
            // Update our cached annotations
            self.cachedAnnotations = newAnnotations
            
            // Save to disk
            AnnotationDataCache.shared.saveAnnotations(newAnnotations, for: userId)
            
            // Prefetch all images in the background
            AnnotationDataCache.shared.prefetchImages(for: Array(newAnnotations.values))
            
            // Wait for all annotations to be added to the map
            await MainActor.run {
                print("Network load complete, showing \(self.displayedAnnotations.count) annotations")
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
            annotationView?.image = imageAnnotation.images.first
            
            // Make sure these properties are set consistently
            annotationView?.collisionMode = .rectangle
            annotationView?.displayPriority = .defaultHigh
            
            return annotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            // Just add animation, don't modify clustering identifiers here
            view.alpha = 0
            UIView.animate(withDuration: 0.3) {
                view.alpha = 1
            }
        }
    }
    // Add this to your MapViewModel class

    
    
    
    
    
    
    
    
    // Show popup when annotation is selected
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let cluster = view.annotation as? MKClusterAnnotation {
            // Deselect the cluster annotation
            mapView.deselectAnnotation(cluster, animated: true)
            
            // Extract ImageAnnotations from the cluster
            let imageAnnotations = cluster.memberAnnotations.compactMap { $0 as? ImageAnnotation }
            
            // Create and show the modern popup
            let popupVC = RestaurantClusterPopupViewController(annotations: imageAnnotations, navigationPath: self.navigationPath) { [weak self] selectedAnnotation in
                guard let self = self else { return }
                
                // Ensure we have a valid post ID
                guard let postId = selectedAnnotation.postId, !postId.isEmpty else { return }
                
                // Create Post object from ImageAnnotation
                let post = Post(
                    _id: postId,
                    userId: selectedAnnotation.author ?? "",
                    imageUrls: selectedAnnotation.imageUrls,
                    timestamp: Timestamp(date: Date()),
                    review: selectedAnnotation.subtitle ?? "",
                    location: "\(selectedAnnotation.coordinate.latitude),\(selectedAnnotation.coordinate.longitude)",
                    restaurantName: selectedAnnotation.title ?? "",
                    likes: selectedAnnotation.heartC ?? 0,
                    likedBy: [],
                    starRating: selectedAnnotation.rating ?? 0,
                    comments: []
                )
                
                // Navigate to PostView using the helper method
                DispatchQueue.main.async {
                    if var path = self.navigationPath {
                        path.append(post)
                        self.navigationPath = path
                        print("Updated navigation path with post: \(post.restaurantName)")
                    } else {
                        var newPath = NavigationPath()
                        newPath.append(post)
                        self.navigationPath = newPath
                        print("Created new navigation path with post: \(post.restaurantName)")
                    }
                }
            }
            
            present(popupVC, animated: true)
        }
        else if let annotation = view.annotation as? ImageAnnotation {
            // Ensure we have a valid post ID
            guard let postId = annotation.postId, !postId.isEmpty else { return }
            
            // Create Post object from ImageAnnotation
            let post = Post(
                _id: postId,
                userId: annotation.author ?? "",
                imageUrls: annotation.imageUrls,
                timestamp: Timestamp(date: Date()),
                review: annotation.subtitle ?? "",
                location: "\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)",
                restaurantName: annotation.title ?? "",
                likes: annotation.heartC ?? 0,
                likedBy: [],
                starRating: annotation.rating ?? 0,
                comments: []
            )
            
            // Navigate to PostView using the helper method
            DispatchQueue.main.async {
                if var path = self.navigationPath {
                    path.append(post)
                    self.navigationPath = path
                    print("Updated navigation path with post: \(post.restaurantName)")
                } else {
                    var newPath = NavigationPath()
                    newPath.append(post)
                    self.navigationPath = newPath
                    print("Created new navigation path with post: \(post.restaurantName)")
                }
            }
        }
    }
    
    // Handle tap on the map to dismiss popup
    @objc func handleMapTap(_ recognizer: UITapGestureRecognizer) {
        let touchPoint = recognizer.location(in: map)
        
        // Check if the touch is outside the current popup view
        if let popupView = currentPopupView, !popupView.frame.contains(touchPoint) {
            // Find and remove the dimming view
            if let dimmingView = map.viewWithTag(999) {
                // Animate fade-out of dimming view
                UIView.animate(withDuration: 0.3, animations: {
                    dimmingView.alpha = 0.0
                    // Optional: also animate the popup fade-out
                    popupView.alpha = 0.0
                }, completion: { _ in
                    // Remove views when animation completes
                    dimmingView.removeFromSuperview()
                    popupView.removeFromSuperview()
                    self.currentPopupView = nil
                    self.isPopupShown = false
                    
                    // Deselect any selected annotations
                    if let selectedAnnotations = self.map.selectedAnnotations as? [MKAnnotation] {
                        for annotation in selectedAnnotations {
                            self.map.deselectAnnotation(annotation, animated: false)
                        }
                    }
                })
            } else {
                // Fallback if no dimming view found
                popupView.removeFromSuperview()
                currentPopupView = nil
                isPopupShown = false
                
                // Deselect any selected annotations
                if let selectedAnnotations = self.map.selectedAnnotations as? [MKAnnotation] {
                    for annotation in selectedAnnotations {
                        self.map.deselectAnnotation(annotation, animated: false)
                    }
                }
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
        
        print("✅ Clicked on annotation: \(annotation.title ?? "Unknown") with postId: \(annotation.postId ?? "nil")")
        
        // Store the annotation data we need
        let coordinate = annotation.coordinate
        let title = annotation.title
        let subtitle = annotation.subtitle
        let imageUrls = annotation.imageUrls
        let author = annotation.author
        let rating = annotation.rating
        let heartC = annotation.heartC
        let images = annotation.images
        let postId = annotation.postId
        
        // Ensure we have a valid post ID
        guard let postId = postId, !postId.isEmpty else {
            print("Error: Empty post ID in showAnnotationPopup")
            return
        }
        
        // Close the cluster popup
        topVC.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            // Create Post object from annotation data
            let post = Post(
                _id: postId,
                userId: author ?? "",
                imageUrls: imageUrls,
                timestamp: Timestamp(date: Date()),
                review: subtitle ?? "",
                location: "\(coordinate.latitude),\(coordinate.longitude)",
                restaurantName: title ?? "",
                likes: heartC ?? 0,
                likedBy: [],
                starRating: rating ?? 0,
                comments: []
            )
            
            // Navigate to PostView
            DispatchQueue.main.async {
                if var path = self.navigationPath {
                    path.append(post)
                    self.navigationPath = path
                }
            }
        }
    }
    
    // MARK: - Notification Handlers
    
    @objc func handleDeletePostNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let postId = userInfo["postId"] as? String else {
            print("Delete notification missing postId")
            return
        }
        
        print("Handling post deletion for postId: \(postId)")
        
        // Remove the annotation from the map
        if let annotation = displayedAnnotations[postId] {
            DispatchQueue.main.async {
                self.map.removeAnnotation(annotation)
                self.displayedAnnotations.removeValue(forKey: postId)
                self.addedAnnotationIDs.remove(postId)
                self.cachedAnnotations.removeValue(forKey: postId)
                
                // Update the cache
                if let userId = Auth.auth().currentUser?.uid {
                    AnnotationDataCache.shared.saveAnnotations(self.cachedAnnotations, for: userId)
                }
            }
        }
    }
}

// Move these extensions outside the class
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

// SwiftUI wrapper for the UIKit MapViewModel
struct MapView: UIViewControllerRepresentable {
    // The view model that manages the map's state and behavior
    let viewModel: MapViewModel
    
    // Binding to the navigation path from the parent view
    // This allows two-way communication of navigation state
    @Binding var navPath: NavigationPath
    
    // Creates the initial UIViewController (MapViewModel) instance
    // Called when the SwiftUI view is first created
    func makeUIViewController(context: Context) -> MapViewModel {
        // Initialize the view model with the current navigation path
        viewModel.navigationPath = navPath
        return viewModel
    }
    
    // Updates the UIViewController when SwiftUI state changes
    // Called whenever the SwiftUI view updates
    func updateUIViewController(_ uiViewController: MapViewModel, context: Context) {
        // Only update the navigation path if it has changed
        // This prevents unnecessary updates and potential infinite loops
        if uiViewController.navigationPath != navPath {
            uiViewController.navigationPath = navPath
        }
    }
}

// SwiftUI view that wraps the MapView with navigation capabilities
struct MapViewWithNavigation: View {
    @StateObject private var mapViewModel = MapViewModel()
    @State private var navPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navPath) {
            MapView(viewModel: mapViewModel, navPath: $navPath)
                .edgesIgnoringSafeArea(.all)
                .navigationDestination(for: Post.self) { post in
                    PostView(post: post)
                }
                .onChange(of: mapViewModel.navigationPath) { newPath in
                    if let newPath = newPath {
                        print("MapViewModel navigation path changed, updating SwiftUI path")
                        navPath = newPath
                    }
                }
                .onChange(of: navPath) { newPath in
                    print("SwiftUI navigation path changed, updating MapViewModel path")
                    mapViewModel.navigationPath = newPath
                }
        }
    }
}
