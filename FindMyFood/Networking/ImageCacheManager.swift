import Foundation
import UIKit

// An enhanced cache for storing and retrieving images from both memory and disk
class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private init() {
        createCacheDirectory() // Create the cache directory if it doesn't exist
    }
    
    // NSCache is thread-safe and automatically removes objects when memory is low
    private let imageCache = NSCache<NSString, UIImage>()
    
    // File manager for disk operations
    private let fileManager = FileManager.default
    
    // Cache directory URL
    private var cacheDirectoryURL: URL? {
        return fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("ImageCache")
    }
    
    // Create cache directory if it doesn't exist
    private func createCacheDirectory() {
        guard let cacheDirectoryURL = cacheDirectoryURL else { return }
        
        if !fileManager.fileExists(atPath: cacheDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true)
            } catch {
                print("Error creating cache directory: \(error.localizedDescription)")
            }
        }
    }
    
    // Configuring cache limits
    func configure(countLimit: Int = 100, memoryLimit: Int = 1024 * 1024 * 100) { // 100MB default
        imageCache.countLimit = countLimit
        imageCache.totalCostLimit = memoryLimit
    }
    
    // Get the file URL for an image key
    private func fileURL(for key: String) -> URL? {
        guard let cacheDirectoryURL = cacheDirectoryURL else { return nil }
        
        // Create a unique filename based on the URL
        let filename = key.replacingOccurrences(of: "/", with: "_")
                          .replacingOccurrences(of: ":", with: "_")
                          .replacingOccurrences(of: "?", with: "_")
                          .replacingOccurrences(of: "&", with: "_")
                          .replacingOccurrences(of: "=", with: "_")
        
        return cacheDirectoryURL.appendingPathComponent(filename)
    }
    
    // Store an image in the memory cache
    private func storeInMemory(image: UIImage, for key: String) {
        let cacheKey = NSString(string: key)
        imageCache.setObject(image, forKey: cacheKey)
    }
    
    // Store an image on disk
    private func storeOnDisk(image: UIImage, for key: String) {
        guard let fileURL = fileURL(for: key),
              let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        do {
            try data.write(to: fileURL)
        } catch {
            print("Error writing image to disk: \(error.localizedDescription)")
        }
    }
    
    // Store an image in both memory and disk cache
    func store(image: UIImage, for url: String) {
        storeInMemory(image: image, for: url)
        storeOnDisk(image: image, for: url)
    }
    
    // Retrieve an image from memory cache
    private func retrieveFromMemory(for key: String) -> UIImage? {
        let cacheKey = NSString(string: key)
        return imageCache.object(forKey: cacheKey)
    }
    
    // Retrieve an image from disk
    private func retrieveFromDisk(for key: String) -> UIImage? {
        guard let fileURL = fileURL(for: key),
              fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else { return nil }
        
        // Store the disk-loaded image in memory for faster access next time
        storeInMemory(image: image, for: key)
        return image
    }
    
    // Retrieve an image from cache (memory first, then disk)
    func retrieveImage(for url: String) -> UIImage? {
        if let memoryImage = retrieveFromMemory(for: url) {
            return memoryImage
        }
        
        return retrieveFromDisk(for: url)
    }
    
    // Clear memory cache
    func clearMemoryCache() {
        imageCache.removeAllObjects()
    }
    
    // Clear disk cache
    func clearDiskCache() {
        guard let cacheDirectoryURL = cacheDirectoryURL,
              fileManager.fileExists(atPath: cacheDirectoryURL.path) else { return }
        
        do {
            try fileManager.removeItem(at: cacheDirectoryURL)
            createCacheDirectory()
        } catch {
            print("Error clearing disk cache: \(error.localizedDescription)")
        }
    }
    
    // Clear all caches (memory and disk)
    func clearCache() {
        clearMemoryCache()
        clearDiskCache()
    }
    
    // Download image with caching
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let urlString = url.absoluteString
        
        // Check if the image is already in the cache
        if let cachedImage = retrieveImage(for: urlString) {
            completion(cachedImage)
            return
        }
        
        // If not in cache, download the image
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data),
                  error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Store the downloaded image in cache
            self.store(image: image, for: urlString)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    // Async version of loadImage for modern Swift concurrency
    func loadImageAsync(from url: URL) async -> UIImage? {
        let urlString = url.absoluteString
        
        // Check if the image is already in the cache
        if let cachedImage = retrieveImage(for: urlString) {
            return cachedImage
        }
        
        // If not in cache, download the image
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                store(image: image, for: urlString)
                return image
            }
        } catch {
            print("Error downloading image: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // Prefetch and cache a batch of images
    func prefetchImages(urls: [URL]) {
        for url in urls {
            Task {
                _ = await loadImageAsync(from: url)
            }
        }
    }
} 