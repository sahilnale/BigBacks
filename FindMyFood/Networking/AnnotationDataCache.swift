import Foundation
import MapKit
import FirebaseFirestore

// Class to manage caching of post/annotation data
class AnnotationDataCache {
    static let shared = AnnotationDataCache()
    
    private init() {
        ensureCacheDirectoryExists()
    }
    
    // File manager for disk operations
    private let fileManager = FileManager.default
    
    // Cache directory URL
    private var cacheDirectoryURL: URL? {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("AnnotationCache")
    }
    
    // Create cache directory if it doesn't exist
    private func ensureCacheDirectoryExists() {
        guard let cacheDirectoryURL = cacheDirectoryURL else { return }
        
        if !fileManager.fileExists(atPath: cacheDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating annotation cache directory: \(error.localizedDescription)")
            }
        }
    }
    
    // Define the cached annotation data structure
    struct CachedAnnotation: Codable {
        let id: String
        let title: String
        let subtitle: String
        let imageUrls: [String]
        let latitude: Double
        let longitude: Double
        let author: String
        let rating: Int?
        let heartCount: Int?
        let timestamp: TimeInterval // When this annotation was cached
        let lastUpdated: TimeInterval // When this annotation was last updated
        
        // Convert to ImageAnnotation
        func toImageAnnotation() -> ImageAnnotation {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            return ImageAnnotation(
                coordinate: coordinate,
                title: title,
                subtitle: subtitle,
                imageUrls: imageUrls,
                author: author,
                rating: rating,
                heartC: heartCount
            )
        }
        
        // Create from an ImageAnnotation
        static func from(annotation: ImageAnnotation, id: String, lastUpdated: TimeInterval? = nil) -> CachedAnnotation {
            return CachedAnnotation(
                id: id,
                title: annotation.title ?? "",
                subtitle: annotation.subtitle ?? "",
                imageUrls: annotation.imageUrls,
                latitude: annotation.coordinate.latitude,
                longitude: annotation.coordinate.longitude,
                author: annotation.author ?? "",
                rating: annotation.rating,
                heartCount: annotation.heartC,
                timestamp: Date().timeIntervalSince1970,
                lastUpdated: lastUpdated ?? Date().timeIntervalSince1970
            )
        }
    }
    
    // Get the URL for the annotations cache file
    private func annotationsCacheURL(for userId: String) -> URL? {
        ensureCacheDirectoryExists()
        return cacheDirectoryURL?.appendingPathComponent("annotations_\(userId).json")
    }
    
    // Save annotations to cache
    func saveAnnotations(_ annotations: [String: ImageAnnotation], for userId: String) {
        guard let cacheURL = annotationsCacheURL(for: userId) else { return }
        
        // First load existing annotations to preserve last updated timestamps where needed
        var existingAnnotations: [String: CachedAnnotation] = [:]
        if let existing = loadCachedAnnotationsRaw(for: userId) {
            for annotation in existing {
                existingAnnotations[annotation.id] = annotation
            }
        }
        
        // Convert to CachedAnnotation format, preserving timestamps where appropriate
        let cachedAnnotations = annotations.map { (id, annotation) -> CachedAnnotation in
            if let existing = existingAnnotations[id] {
                // If no changes, keep the original lastUpdated time
                if existing.title == (annotation.title ?? "") &&
                   existing.subtitle == (annotation.subtitle ?? "") &&
                   existing.imageUrls == annotation.imageUrls &&
                   existing.latitude == annotation.coordinate.latitude &&
                   existing.longitude == annotation.coordinate.longitude &&
                   existing.author == (annotation.author ?? "") &&
                   existing.rating == annotation.rating &&
                   existing.heartCount == annotation.heartC {
                    return CachedAnnotation.from(annotation: annotation, id: id, lastUpdated: existing.lastUpdated)
                }
            }
            // If new or updated annotation, use current timestamp
            return CachedAnnotation.from(annotation: annotation, id: id)
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(cachedAnnotations)
            try data.write(to: cacheURL)
            print("Saved \(cachedAnnotations.count) annotations to cache")
        } catch {
            print("Error saving annotations to cache: \(error.localizedDescription)")
        }
    }
    
    // Load raw CachedAnnotations from cache
    private func loadCachedAnnotationsRaw(for userId: String) -> [CachedAnnotation]? {
        guard let cacheURL = annotationsCacheURL(for: userId),
              fileManager.fileExists(atPath: cacheURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: cacheURL)
            let decoder = JSONDecoder()
            return try decoder.decode([CachedAnnotation].self, from: data)
        } catch {
            print("Error loading annotations from cache: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Load annotations from cache
    func loadAnnotations(for userId: String) -> [String: ImageAnnotation]? {
        guard let cachedAnnotations = loadCachedAnnotationsRaw(for: userId) else {
            return nil
        }
        
        // Convert to dictionary of ImageAnnotations
        var result = [String: ImageAnnotation]()
        for cachedAnnotation in cachedAnnotations {
            result[cachedAnnotation.id] = cachedAnnotation.toImageAnnotation()
        }
        
        print("Loaded \(result.count) annotations from cache")
        return result
    }
    
    // Check if annotations need refresh (older than the specified maxAge in seconds)
    func needsRefresh(for userId: String, maxAge: TimeInterval = 3600) -> Bool {
        guard let cachedAnnotations = loadCachedAnnotationsRaw(for: userId), 
              !cachedAnnotations.isEmpty else {
            // No cached annotations, definitely need refresh
            return true
        }
        
        let now = Date().timeIntervalSince1970
        // If any annotation is older than maxAge, refresh
        for annotation in cachedAnnotations {
            if (now - annotation.lastUpdated) > maxAge {
                return true
            }
        }
        
        return false
    }
    
    // Clear cache
    func clearCache(for userId: String) {
        guard let cacheURL = annotationsCacheURL(for: userId),
              fileManager.fileExists(atPath: cacheURL.path) else {
            return
        }
        
        do {
            try fileManager.removeItem(at: cacheURL)
            print("Cleared annotations cache for user \(userId)")
        } catch {
            print("Error clearing annotations cache: \(error.localizedDescription)")
        }
    }
    
    // Prefetch and cache all images for annotations
    func prefetchImages(for annotations: [ImageAnnotation]) {
        let imageUrls = annotations.flatMap { $0.imageUrls }
            .compactMap { URL(string: $0) }
        
        ImageCacheManager.shared.prefetchImages(urls: imageUrls)
    }
} 