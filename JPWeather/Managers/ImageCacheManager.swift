//
//  ImageCacheManager.swift
//  JPWeather
//
//  Created by Ilgar Ilyasov on 9/7/24.
//

import UIKit

class ImageCacheManager {
    static let shared = ImageCacheManager()
    private let cache = NSCache<NSString, UIImage>()
    
    // Private initializer to enforce singleton
    private init() {
        cache.countLimit = Constants.cacheLimit // Limit the number of cached images
    }
    
    enum Constants {
        static let cacheLimit = 50 // Maximum number of cached images
    }
    
    func cacheIcon(_ icon: UIImage, forKey key: String) {
        cache.setObject(icon, forKey: key as NSString)
    }
    
    func getCachedIcon(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
}

