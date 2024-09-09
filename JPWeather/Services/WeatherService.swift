//
//  WeatherService.swift
//  JPWeather
//
//  Created by Ilgar Ilyasov on 9/7/24.
//

import UIKit

protocol WeatherServiceProtocol {
    func fetchWeatherForCoordinates(
        latitude: Double,
        longitude: Double,
        completion: @escaping (Result<CurrentWeatherResponse, WeatherServiceError>) -> Void
    )
}

enum WeatherServiceError: LocalizedError {
    case invalidURL
    case noData
    case decodingFailed
    case networkError(Error)
    case cityNotFound
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The URL is invalid."
        case .noData: return "No data was received from the server."
        case .decodingFailed: return "Failed to decode the weather data."
        case .networkError(let error): return error.localizedDescription
        case .cityNotFound: return "City not found. Please try again."
        case .serverError: return "The server encountered an error. Please try again later."
        }
    }
    
    static let unauthorizedErrorDomain = NSError(domain: "Unauthorized", code: 401, userInfo: nil)
    static let forbiddenErrorDomain = NSError(domain: "Forbidden", code: 403, userInfo: nil)
}

class WeatherService: WeatherServiceProtocol {
    // Singleton instance
    static let shared = WeatherService()
    
    // Private initializer to enforce singleton pattern
    private init() {}
    
    // Centralized constants
    enum Constants {
        // API constants
        static let apiKey = "d6b774aa61aff4c9b896679661112735"
        static let scheme = "https"
        static let host = "api.openweathermap.org"
        static let path = "/data/2.5/weather"
        
        // Image fetching
        static let imageBaseURL = "https://openweathermap.org/img/wn/"
        static let imageFormat = "@2x.png"
        
        // Query parameter keys
        static let queryCity = "q"
        static let queryAppID = "appid"
        static let queryLatitude = "lat"
        static let queryLongitude = "lon"
    }
    
    // Fetch weather by coordinates
    func fetchWeatherForCoordinates(
        latitude: Double,
        longitude: Double,
        completion: @escaping (Result<CurrentWeatherResponse, WeatherServiceError>) -> Void
    ) {
        let queryItems = [
            URLQueryItem(name: Constants.queryLatitude, value: "\(latitude)"),
            URLQueryItem(name: Constants.queryLongitude, value: "\(longitude)"),
            URLQueryItem(name: Constants.queryAppID, value: Constants.apiKey)
        ]
        guard let url = createWeatherURL(with: queryItems) else {
            completion(.failure(.invalidURL))
            return
        }
        performRequest(with: url, completion: completion)
    }
    
    // Centralized network request handler
    private func performRequest(
        with url: URL,
        headers: [String: String]? = nil,
        completion: @escaping (Result<CurrentWeatherResponse, WeatherServiceError>) -> Void
    ) {
        var request = URLRequest(url: url)
        
        // Apply headers if available
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network error
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            // Handle HTTP response codes with granular error handling
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    break // Proceed if 2XX success
                case 401:
                    completion(.failure(.networkError(WeatherServiceError.unauthorizedErrorDomain)))
                    return
                case 403:
                    completion(.failure(.networkError(WeatherServiceError.forbiddenErrorDomain)))
                    return
                case 404:
                    completion(.failure(.cityNotFound))
                    return
                case 500...599:
                    completion(.failure(.serverError))
                    return
                default:
                    completion(.failure(.serverError))
                    return
                }
            }
            
            // Handle missing data
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            // Handle decoding of JSON response
            do {
                let weatherResponse = try JSONDecoder().decode(CurrentWeatherResponse.self, from: data)
                completion(.success(weatherResponse))
            } catch {
                completion(.failure(.decodingFailed))
            }
        }.resume()
    }
    
    // Create a URL based on queryItems
    private func createWeatherURL(with queryItems: [URLQueryItem]) -> URL? {
        var components = URLComponents()
        components.scheme = Constants.scheme
        components.host = Constants.host
        components.path = Constants.path
        components.queryItems = queryItems
        return components.url
    }
    
    func downloadWeatherIcon(iconCode: String, completion: @escaping (Result<UIImage, WeatherServiceError>) -> Void) {
        if let cachedIcon = ImageCacheManager.shared.getCachedIcon(forKey: iconCode) {
            completion(.success(cachedIcon))
            return
        }
        
        let iconURL = Constants.imageBaseURL + iconCode + Constants.imageFormat
        guard let url = URL(string: iconURL) else {
            completion(.failure(.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            guard let image = UIImage(data: data) else {
                completion(.failure(.decodingFailed))
                return
            }
            
            // Cache the downloaded icon
            ImageCacheManager.shared.cacheIcon(image, forKey: iconCode)
            
            completion(.success(image))
        }.resume()
    }
}
