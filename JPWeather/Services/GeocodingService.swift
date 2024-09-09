//
//  GeocodingService.swift
//  JPWeather
//
//  Created by Ilgar Ilyasov on 9/9/24.
//

import Foundation

protocol GeocodingServiceProtocol {
    func fetchCoordinates(for city: String, completion: @escaping (Result<[GeocodingResponse], WeatherServiceError>) -> Void)
}

// Model for Geocoding API response
class GeocodingResponse: Codable {
    let name: String
    let lat: Double
    let lon: Double
    let country: String?
}

class GeocodingService {
    
    // Singleton instance
    static let shared = GeocodingService()
    
    enum Constants {
        static let apiKey = "d6b774aa61aff4c9b896679661112735"
        static let baseURL = "https://api.openweathermap.org/geo/1.0/direct"
        static let queryCity = "q"
        static let queryLimit = "limit"
        static let queryAppID = "appid"
        static let defaultLimit = "1"
    }
    
    private let cache = NSCache<NSString, NSArray>() // Store arrays of GeocodingResponse
    
    // Private initializer to prevent creating more than one instance
    private init() {}
    
    // Fetch coordinates for a city
    func fetchCoordinates(for city: String, completion: @escaping (Result<[GeocodingResponse], WeatherServiceError>) -> Void) {
        // Check the cache first
        if let cachedResponse = cache.object(forKey: city as NSString) as? [GeocodingResponse] {
            completion(.success(cachedResponse))
            return
        }
        
        let queryItems = [
            URLQueryItem(name: Constants.queryCity, value: city),
            URLQueryItem(name: Constants.queryLimit, value: Constants.defaultLimit),
            URLQueryItem(name: Constants.queryAppID, value: Constants.apiKey)
        ]
        
        guard let url = createGeocodingURL(with: queryItems) else {
            completion(.failure(.invalidURL))
            return
        }
        
        performGeocodingRequest(with: url) { [weak self] result in
            switch result {
            case .success(let response):
                // Cache the response
                self?.cache.setObject(response as NSArray, forKey: city as NSString)
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Create the URL for geocoding based on query items
    private func createGeocodingURL(with queryItems: [URLQueryItem]) -> URL? {
        var components = URLComponents(string: Constants.baseURL)
        components?.queryItems = queryItems
        return components?.url
    }
    
    // Perform the network request for geocoding
    private func performGeocodingRequest(with url: URL, completion: @escaping (Result<[GeocodingResponse], WeatherServiceError>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let geocodingResponse = try JSONDecoder().decode([GeocodingResponse].self, from: data)
                completion(.success(geocodingResponse))
            } catch {
                completion(.failure(.decodingFailed))
            }
        }.resume()
    }
}

