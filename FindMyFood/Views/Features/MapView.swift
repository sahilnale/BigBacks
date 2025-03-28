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
    
    init(annotations: [ImageAnnotation], onSelect: @escaping (ImageAnnotation) -> Void) {
        self.imageAnnotations = annotations
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
    
//    private func createRestaurantCard(for annotation: ImageAnnotation) -> UIView {
//        // Create container
//        let itemContainer = UIView()
//        itemContainer.translatesAutoresizingMaskIntoConstraints = false
//        itemContainer.layer.cornerRadius = 12
//        itemContainer.clipsToBounds = true
//        itemContainer.backgroundColor = .secondarySystemBackground
//        
//        // Add tap gesture
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(restaurantCardTapped(_:)))
//        itemContainer.addGestureRecognizer(tapGesture)
//        itemContainer.isUserInteractionEnabled = true
//        
//        // Store the annotation reference
//        objc_setAssociatedObject(itemContainer, UnsafeRawPointer(bitPattern: 1)!, annotation, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        
//        // Create image view
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFill
//        imageView.clipsToBounds = true
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        if let image = annotation.images.first {
//            imageView.image = image
//        } else {
//            imageView.image = UIImage(systemName: "photo")
//            imageView.tintColor = .gray
//            imageView.contentMode = .scaleAspectFit
//            imageView.backgroundColor = UIColor.systemGray6
//        }
//        
//        // Create gradient overlay
//        let gradientLayer = CAGradientLayer()
//        gradientLayer.colors = [
//            UIColor.clear.cgColor,
//            UIColor.black.withAlphaComponent(0.6).cgColor
//        ]
//        gradientLayer.locations = [0.6, 1.0]
//        
//        let overlayView = UIView()
//        overlayView.translatesAutoresizingMaskIntoConstraints = false
//        overlayView.layer.addSublayer(gradientLayer)
//        
//        // Create title label
//        let nameLabel = UILabel()
//        nameLabel.text = annotation.title
//        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
//        nameLabel.textColor = .white
//        nameLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Create rating view if rating exists
//        let ratingContainer = UIView()
//        ratingContainer.backgroundColor = UIColor.black.withAlphaComponent(0.5)
//        ratingContainer.layer.cornerRadius = 8
//        ratingContainer.translatesAutoresizingMaskIntoConstraints = false
//        
//        let ratingStack = UIStackView()
//        ratingStack.axis = .horizontal
//        ratingStack.spacing = 4
//        ratingStack.alignment = .center
//        ratingStack.translatesAutoresizingMaskIntoConstraints = false
//        ratingStack.isLayoutMarginsRelativeArrangement = true
//        ratingStack.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
//        
//        let starIcon = UIImageView(image: UIImage(systemName: "star.fill"))
//        starIcon.tintColor = UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1)
//        starIcon.contentMode = .scaleAspectFit
//        starIcon.translatesAutoresizingMaskIntoConstraints = false
//        
//        let ratingLabel = UILabel()
//        ratingLabel.text = annotation.rating != nil ? "\(annotation.rating!)" : "N/A"
//        ratingLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
//        ratingLabel.textColor = .white
//        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Add subviews
//        ratingStack.addArrangedSubview(starIcon)
//        ratingStack.addArrangedSubview(ratingLabel)
//        ratingContainer.addSubview(ratingStack)
//        
//        itemContainer.addSubview(imageView)
//        itemContainer.addSubview(overlayView)
//        itemContainer.addSubview(nameLabel)
//        
//        if annotation.rating != nil {
//            itemContainer.addSubview(ratingContainer)
//        }
//        
//        // Setup constraints
//        NSLayoutConstraint.activate([
//            itemContainer.heightAnchor.constraint(equalToConstant: 120),
//            
//            imageView.topAnchor.constraint(equalTo: itemContainer.topAnchor),
//            imageView.leadingAnchor.constraint(equalTo: itemContainer.leadingAnchor),
//            imageView.trailingAnchor.constraint(equalTo: itemContainer.trailingAnchor),
//            imageView.bottomAnchor.constraint(equalTo: itemContainer.bottomAnchor),
//            
//            overlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
//            overlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
//            overlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
//            overlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
//            
//            nameLabel.leadingAnchor.constraint(equalTo: itemContainer.leadingAnchor, constant: 12),
//            nameLabel.trailingAnchor.constraint(equalTo: itemContainer.trailingAnchor, constant: -12),
//            nameLabel.bottomAnchor.constraint(equalTo: itemContainer.bottomAnchor, constant: -12)
//        ])
//        
//        if annotation.rating != nil {
//            NSLayoutConstraint.activate([
//                ratingContainer.topAnchor.constraint(equalTo: itemContainer.topAnchor, constant: 12),
//                ratingContainer.trailingAnchor.constraint(equalTo: itemContainer.trailingAnchor, constant: -12),
//                
//                ratingStack.topAnchor.constraint(equalTo: ratingContainer.topAnchor),
//                ratingStack.leadingAnchor.constraint(equalTo: ratingContainer.leadingAnchor),
//                ratingStack.trailingAnchor.constraint(equalTo: ratingContainer.trailingAnchor),
//                ratingStack.bottomAnchor.constraint(equalTo: ratingContainer.bottomAnchor),
//                
//                starIcon.widthAnchor.constraint(equalToConstant: 14),
//                starIcon.heightAnchor.constraint(equalToConstant: 14)
//            ])
//        }
//        
//        return itemContainer
//    }
//    private func createRestaurantCard(for annotation: ImageAnnotation) -> UIView {
//        // Create main container with shadow
//        let cardContainer = UIView()
//        cardContainer.translatesAutoresizingMaskIntoConstraints = false
//        cardContainer.backgroundColor = .clear
//        
//        // Inner container with rounded corners
//        let itemContainer = UIView()
//        itemContainer.translatesAutoresizingMaskIntoConstraints = false
//        itemContainer.layer.cornerRadius = 16
//        itemContainer.clipsToBounds = true
//        itemContainer.backgroundColor = .systemBackground
//        itemContainer.layer.masksToBounds = true
//        
//        // Add shadow to main container
//        cardContainer.layer.shadowColor = UIColor.black.cgColor
//        cardContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
//        cardContainer.layer.shadowRadius = 12
//        cardContainer.layer.shadowOpacity = 0.1
//        
//        
//        
//        // Add tap gesture
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(restaurantCardTapped(_:)))
//        cardContainer.addGestureRecognizer(tapGesture)
//        cardContainer.isUserInteractionEnabled = true
//        
//        // Store the annotation reference
//        objc_setAssociatedObject(cardContainer, UnsafeRawPointer(bitPattern: 1)!, annotation, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//
//        
//        // Create image view with increased height
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFill
//        imageView.clipsToBounds = true
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        if let image = annotation.images.first {
//            imageView.image = image
//        } else {
//            // Enhanced placeholder
//            let configuration = UIImage.SymbolConfiguration(pointSize: 32, weight: .light)
//            imageView.image = UIImage(systemName: "fork.knife", withConfiguration: configuration)
//            imageView.tintColor = .systemGray3
//            imageView.contentMode = .scaleAspectFit
//            imageView.backgroundColor = UIColor.systemGray6
//        }
//        
//        // Content container for text info
//        let contentContainer = UIView()
//        contentContainer.translatesAutoresizingMaskIntoConstraints = false
//        contentContainer.backgroundColor = .systemBackground
//        
//        // Create title label with better typography
//        let nameLabel = UILabel()
//        nameLabel.text = annotation.title
//        nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
//        nameLabel.textColor = .label
//        nameLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Category label (example, you might need to adjust based on your data model)
//        let categoryLabel = UILabel()
//        categoryLabel.text = annotation.subtitle ?? "Restaurant"
//        categoryLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
//        categoryLabel.textColor = .secondaryLabel
//        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Create modern rating view
//        let ratingView = UIView()
//        ratingView.backgroundColor = .systemBackground
//        ratingView.translatesAutoresizingMaskIntoConstraints = false
//        
//                // Create rating view if rating exists
//                let ratingContainer = UIView()
//                ratingContainer.backgroundColor = UIColor.black.withAlphaComponent(0.5)
//                ratingContainer.layer.cornerRadius = 8
//                ratingContainer.translatesAutoresizingMaskIntoConstraints = false
//        
//                let ratingStack = UIStackView()
//                ratingStack.axis = .horizontal
//                ratingStack.spacing = 4
//                ratingStack.alignment = .center
//                ratingStack.translatesAutoresizingMaskIntoConstraints = false
//                ratingStack.isLayoutMarginsRelativeArrangement = true
//                ratingStack.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
//        
//                let starIcon = UIImageView(image: UIImage(systemName: "star.fill"))
//                starIcon.tintColor = UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1)
//                starIcon.contentMode = .scaleAspectFit
//                starIcon.translatesAutoresizingMaskIntoConstraints = false
//        
//                let ratingLabel = UILabel()
//                ratingLabel.text = annotation.rating != nil ? "\(annotation.rating!)" : "N/A"
//                ratingLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
//                ratingLabel.textColor = .white
//                ratingLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        
//        // Badge for status or promotion (optional)
//        let badgeLabel = UILabel()
//        badgeLabel.text = "Open"
//        badgeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
//        badgeLabel.textColor = .white
//        badgeLabel.backgroundColor = UIColor(red: 40/255, green: 167/255, blue: 69/255, alpha: 1) // Green color
//        badgeLabel.textAlignment = .center
//        badgeLabel.layer.cornerRadius = 10
//        badgeLabel.layer.masksToBounds = true
//        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Add subviews to containers
//        ratingStack.addArrangedSubview(starIcon)
//        ratingStack.addArrangedSubview(ratingLabel)
//        ratingView.addSubview(ratingStack)
//        
//        contentContainer.addSubview(nameLabel)
//        contentContainer.addSubview(categoryLabel)
//        contentContainer.addSubview(ratingView)
//        
//        itemContainer.addSubview(imageView)
//        itemContainer.addSubview(contentContainer)
//        
//        //        // Add subviews
//        //        ratingStack.addArrangedSubview(starIcon)
//        //        ratingStack.addArrangedSubview(ratingLabel)
//        //        ratingContainer.addSubview(ratingStack)
//        //
//        //        itemContainer.addSubview(imageView)
//        //        itemContainer.addSubview(overlayView)
//        //        itemContainer.addSubview(nameLabel)
//        //
//                if annotation.rating != nil {
//                    itemContainer.addSubview(ratingContainer)
//                }
//        // Badge is conditionally added (you can customize this logic)
//        if Bool.random() { // Replace with actual condition based on your data
//            contentContainer.addSubview(badgeLabel)
//        }
//        
//        // Add itemContainer to cardContainer
//        cardContainer.addSubview(itemContainer)
//        
//        // Setup constraints
//        NSLayoutConstraint.activate([
//            // Card container constraints
//            cardContainer.heightAnchor.constraint(equalToConstant: 220),
//            
//            // Item container fills card container
//            itemContainer.topAnchor.constraint(equalTo: cardContainer.topAnchor),
//            itemContainer.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
//            itemContainer.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),
//            itemContainer.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor),
//            
//            // Image view takes 70% of the card height
//            imageView.topAnchor.constraint(equalTo: itemContainer.topAnchor),
//            imageView.leadingAnchor.constraint(equalTo: itemContainer.leadingAnchor),
//            imageView.trailingAnchor.constraint(equalTo: itemContainer.trailingAnchor),
//            imageView.heightAnchor.constraint(equalTo: itemContainer.heightAnchor, multiplier: 0.7),
//            
//            // Content container takes the remaining space
//            contentContainer.topAnchor.constraint(equalTo: imageView.bottomAnchor),
//            contentContainer.leadingAnchor.constraint(equalTo: itemContainer.leadingAnchor),
//            contentContainer.trailingAnchor.constraint(equalTo: itemContainer.trailingAnchor),
//            contentContainer.bottomAnchor.constraint(equalTo: itemContainer.bottomAnchor),
//            
//            // Content layout
//            nameLabel.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 12),
//            nameLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
//            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: ratingView.leadingAnchor, constant: -8),
//            
//            categoryLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
//            categoryLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
//            categoryLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentContainer.trailingAnchor, constant: -16),
//            
//            // Rating view aligned to the right
//            ratingView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
//            ratingView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
//            
//            // Rating stack inside rating view
//            ratingStack.topAnchor.constraint(equalTo: ratingView.topAnchor),
//            ratingStack.leadingAnchor.constraint(equalTo: ratingView.leadingAnchor),
//            ratingStack.trailingAnchor.constraint(equalTo: ratingView.trailingAnchor),
//            ratingStack.bottomAnchor.constraint(equalTo: ratingView.bottomAnchor),
//        ])
//        
//        
//        // Conditional constraints for badge
//        if badgeLabel.superview != nil {
//            NSLayoutConstraint.activate([
//                badgeLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 12),
//                badgeLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 12),
//                badgeLabel.heightAnchor.constraint(equalToConstant: 20),
//                badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
//            ])
//        }
//        
//        return cardContainer
//    }
    
//March 14
    private func createRestaurantCard(for annotation: ImageAnnotation) -> UIView {
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
        cardContainer.addGestureRecognizer(tapGesture)
        cardContainer.isUserInteractionEnabled = true
        
        // Store the annotation reference
        objc_setAssociatedObject(cardContainer, UnsafeRawPointer(bitPattern: 1)!, annotation, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

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
        let badgeLabel = UILabel()
        badgeLabel.text = "Open"
        badgeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = UIColor(red: 40/255, green: 167/255, blue: 69/255, alpha: 1)
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 10
        badgeLabel.layer.masksToBounds = true
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false

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
        if Bool.random() { // Replace with actual condition based on your data
            contentContainer.addSubview(badgeLabel)
        }
        
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
        if badgeLabel.superview != nil {
            NSLayoutConstraint.activate([
                badgeLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 12),
                badgeLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 12),
                badgeLabel.heightAnchor.constraint(equalToConstant: 20),
                badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            ])
        }

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
        guard let itemContainer = gestureRecognizer.view,
              let annotation = objc_getAssociatedObject(itemContainer, UnsafeRawPointer(bitPattern: 1)!) as? ImageAnnotation else {
            return
        }
        
        dismiss(animated: true) { [weak self] in
            self?.onSelect?(annotation)
        }
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
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, imageUrls: [String], author: String?, rating: Int?, heartC: Int?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.imageUrls = imageUrls
        self.author = author
        self.rating = rating
        self.heartC = heartC
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
            
            if let latestAnnotation = cluster.memberAnnotations.last as? ImageAnnotation,
               let latestImage = latestAnnotation.images.first {
                let clusterImage = generateClusterImage(
                    baseImage: latestImage,
                    text: "\(cluster.memberAnnotations.count)"
                )
                self.image = clusterImage
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
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        self.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        self.imageView = UIImageView(frame: self.bounds)
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
        self.imageView.layer.cornerRadius = 12
        self.imageView.layer.masksToBounds = true
        self.addSubview(self.imageView)
        
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
        set { self.imageView.image = newValue }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
    }
    
    // Don't override prepareForDisplay as it might interfere with MapKit's internal KVO
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
                  let imageIdentifiers = userInfo["imageData"] as? [String],
                  let review = userInfo["review"] as? String,
                  let coordinate = userInfo["location"] as? String,
                  let title = userInfo["restaurantName"] as? String,
                  let likes = userInfo["likes"] as? Int,
                  let rating = userInfo["starRating"] as? Int else {
                print("Guard failed")
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
            addUserAnnotation(coordinate_in: coordinateC, title_in: title, review: review, image_in: imageIdentifiers, author_in: author, rating_in: rating, heartC_in: likes)
            
            print("Done")
        }
    }
    
    func addUserAnnotation(
        coordinate_in: CLLocationCoordinate2D,
        title_in: String,
        review: String,
        image_in: [String],
        author_in: String,
        rating_in: Int,
        heartC_in: Int
    ) {
        let annotation = ImageAnnotation(
            coordinate: coordinate_in,
            title: title_in,
            subtitle: review,
            imageUrls: image_in,
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
                
                let imageUrls = post.imageUrls // Use the array
                var images: [UIImage] = []
                
                for imageUrlString in imageUrls {
                    guard let imageUrl = URL(string: imageUrlString) else { continue }
                    
                    let image: UIImage? = await withCheckedContinuation { continuation in
                        URLSession.shared.dataTask(with: imageUrl) { data, _, error in
                            if let data = data, let fetchedImage = UIImage(data: data) {
                                continuation.resume(returning: fetchedImage)
                            } else {
                                continuation.resume(returning: nil)
                            }
                        }.resume()
                    }
                    
                    if let image = image {
                        images.append(image)
                    }
                }
                
                guard !images.isEmpty else { continue }
                
                let locationComponents = post.location.split(separator: ",")
                guard locationComponents.count == 2,
                      let latitude = Double(locationComponents[0]),
                      let longitude = Double(locationComponents[1]) else {
                    continue
                }
                let annotationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                
                let annotation = ImageAnnotation(
                    coordinate: annotationCoordinate,
                    title: post.restaurantName,
                    subtitle: post.review,
                    imageUrls: imageUrls,
                    author: user.username,
                    rating: post.starRating,
                    heartC: post.likes
                )
                annotation.images = images
                
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
            let popupVC = RestaurantClusterPopupViewController(annotations: imageAnnotations) { [weak self] selectedAnnotation in
                guard let self = self else { return }
                
                // Center the map on the selected annotation
                let region = MKCoordinateRegion(
                    center: selectedAnnotation.coordinate,
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                )
                self.map.setRegion(region, animated: true)
                
                // Create the CustomPopupView directly instead of selecting the annotation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Remove any existing popup
                    self.currentPopupView?.removeFromSuperview()
                    if let dimmingView = self.map.viewWithTag(999) {
                        dimmingView.removeFromSuperview()
                    }
                    
                    // Create dimming view
                    let dimmingView = UIView(frame: self.map.bounds)
                    dimmingView.backgroundColor = UIColor.black
                    dimmingView.alpha = 0.0
                    dimmingView.tag = 999
                    
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleMapTap(_:)))
                    dimmingView.addGestureRecognizer(tapGesture)
                    
                    // Create popup view
                    let popupView = CustomPopupView()
                    let popupWidth: CGFloat = 350
                    let popupHeight: CGFloat = 600
                    
                    let centerX = self.map.bounds.midX - (popupWidth / 2)
                    let centerY = self.map.bounds.midY - (popupHeight / 2)
                    
                    popupView.frame = CGRect(x: centerX, y: centerY, width: popupWidth, height: popupHeight)
                    popupView.layer.cornerRadius = 10
                    popupView.layer.masksToBounds = true
                    popupView.setDetails(
                        title: selectedAnnotation.title,
                        images: selectedAnnotation.images,
                        reviewerName: selectedAnnotation.author,
                        rating: selectedAnnotation.rating,
                        comment: selectedAnnotation.subtitle,
                        star: selectedAnnotation.rating,
                        heart: selectedAnnotation.heartC
                    )
                    
                    self.map.addSubview(dimmingView)
                    self.map.addSubview(popupView)
                    self.currentPopupView = popupView
                    
                    UIView.animate(withDuration: 0.3) {
                        dimmingView.alpha = 0.5
                    }
                    
                    self.isPopupShown = true
                }
            }
            
            present(popupVC, animated: true)
        }
        else if let annotation = view.annotation as? ImageAnnotation {
            // Your existing code for handling individual annotations...
            currentPopupView?.removeFromSuperview()
            let dimmingView = UIView(frame: map.bounds)
            dimmingView.backgroundColor = UIColor.black
            dimmingView.alpha = 0.0
            dimmingView.tag = 999
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
            dimmingView.addGestureRecognizer(tapGesture)
            
            let popupView = CustomPopupView()
            let popupWidth: CGFloat = 350
            let popupHeight: CGFloat = 600
            
            let centerX = map.bounds.midX - (popupWidth / 2)
            let centerY = map.bounds.midY - (popupHeight / 2)
            
            popupView.frame = CGRect(x: centerX, y: centerY, width: popupWidth, height: popupHeight)
            popupView.layer.cornerRadius = 10
            popupView.layer.masksToBounds = true
            popupView.setDetails(
                title: annotation.title,
                images: annotation.images,
                reviewerName: annotation.author,
                rating: annotation.rating,
                comment: annotation.subtitle,
                star: annotation.rating,
                heart: annotation.heartC
            )
            
            map.addSubview(dimmingView)
            map.addSubview(popupView)
            currentPopupView = popupView
            
            UIView.animate(withDuration: 0.3) {
                dimmingView.alpha = 0.5
            }
            
            isPopupShown = true
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
                })
            } else {
                // Fallback if no dimming view found
                popupView.removeFromSuperview()
                currentPopupView = nil
                isPopupShown = false
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
        
        // Store the annotation data we need
        let coordinate = annotation.coordinate
        let title = annotation.title
        let subtitle = annotation.subtitle
        let imageUrls = annotation.imageUrls
        let author = annotation.author
        let rating = annotation.rating
        let heartC = annotation.heartC
        let images = annotation.images
        
        // Close the cluster popup
        topVC.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            // Use a delay to ensure the alert controller is fully dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // First, check if there's already an annotation at this coordinate
                let existingAnnotations = self.map.annotations.filter { 
                    if let imgAnnotation = $0 as? ImageAnnotation {
                        // Check if coordinates are very close (within ~10 meters)
                        let distance = MKMapPoint(imgAnnotation.coordinate).distance(to: MKMapPoint(coordinate))
                        return distance < 10 && imgAnnotation.title == title
                    }
                    return false
                }
                
                // Remove any existing annotations at this location
                for existingAnnotation in existingAnnotations {
                    if !(existingAnnotation is MKUserLocation) {
                        self.map.removeAnnotation(existingAnnotation)
                    }
                }
                
                // Center the map on the selected annotation first
                let region = MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                )
                self.map.setRegion(region, animated: false)
                
                // Create and add the new annotation
                let newAnnotation = ImageAnnotation(
                    coordinate: coordinate,
                    title: title,
                    subtitle: subtitle,
                    imageUrls: imageUrls,
                    author: author,
                    rating: rating,
                    heartC: heartC
                )
                newAnnotation.images = images
                
                // Then add and select the annotation
                self.map.addAnnotation(newAnnotation)
                self.map.selectAnnotation(newAnnotation, animated: true)
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

// Move the SwiftUI wrapper outside the class
struct MapView: UIViewControllerRepresentable {
    let viewModel: MapViewModel
    
    func makeUIViewController(context: Context) -> MapViewModel {
        return viewModel
    }
    
    func updateUIViewController(_ uiViewController: MapViewModel, context: Context) {
        // Handle any updates to the view controller here
    }
}
