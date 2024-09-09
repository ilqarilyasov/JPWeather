//
//  WeatherViewModel.swift
//  JPWeather
//
//  Created by Ilgar Ilyasov on 9/7/24.
//

import Foundation
import UIKit
import CoreLocation

class WeatherViewModel {
    // Services
    private let geocodingService = GeocodingService.shared
    private let weatherService = WeatherService.shared
    private let cacheManager = ImageCacheManager.shared
    
    var cityName: String = ""
    var temperatureInFahrenheit: String = ""
    var weatherIcon: UIImage? = UIImage(systemName: "cloud.fill.questionmark")
    
    // Observable closures
    var didUpdateWeather: (() -> Void)?
    var didFailWithError: ((Error) -> Void)?
    
    // Constants enum for hardcoded values
    enum Constants {
        static let lastSearchedCityKey = "lastSearchedCity"
        static let fahrenheitFormat = "%.1f°F"
    }
    
    // MARK: - Fetch Weather Data
    
    func fetchWeather(forCity city: String) {
        // Use the GeocodingService to get coordinates
        geocodingService.fetchCoordinates(for: city) { [weak self] result in
            switch result {
            case .success(let geocodingResponse):
                guard let latitude = geocodingResponse.first?.lat,
                      let longitude = geocodingResponse.first?.lon else {
                    self?.didFailWithError?(WeatherServiceError.cityNotFound)
                    return
                }
                // Use the coordinates to fetch the weather
                self?.fetchWeatherForCurrentLocation(latitude: latitude, longitude: longitude)
                
            case .failure(let error):
                self?.didFailWithError?(error)
            }
        }
    }
    
    func fetchWeatherForCurrentLocation(latitude: Double, longitude: Double) {
        weatherService.fetchWeatherForCoordinates(latitude: latitude, longitude: longitude) { [weak self] result in
            switch result {
            case .success(let response):
                self?.processWeatherData(response)
            case .failure(let error):
                self?.didFailWithError?(error)
            }
        }
    }
    
    // MARK: - Process Weather Data
    
    private func processWeatherData(_ response: CurrentWeatherResponse) {
        self.cityName = response.cityName
        self.temperatureInFahrenheit = convertToFahrenheit(kelvin: response.mainWeather.temperature)
        
        // Cache the weather icon
        if let iconCode = response.weatherConditions.first?.iconCode {
            fetchWeatherIcon(iconCode: iconCode)
        } else {
            self.didUpdateWeather?()
        }
    }
    
    // MARK: - Fetch Weather Icon
    
    private func fetchWeatherIcon(iconCode: String) {
        // First, check if the image is already cached
        if let cachedIcon = cacheManager.getCachedIcon(forKey: iconCode) {
            self.weatherIcon = cachedIcon
            DispatchQueue.main.async {
                self.didUpdateWeather?()
            }
            return
        }
        
        // If not cached, download it
        weatherService.downloadWeatherIcon(iconCode: iconCode) { [weak self] result in
            switch result {
            case .success(let image):
                self?.cacheManager.cacheIcon(image, forKey: iconCode)
                self?.weatherIcon = image
                DispatchQueue.main.async {
                    self?.didUpdateWeather?()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.didUpdateWeather?()
                }
            }
        }
    }
    
    // MARK: - Conversion
    
    private func convertToFahrenheit(kelvin: Double) -> String {
        let fahrenheit = (kelvin - 273.15) * 9/5 + 32
        return String(format: Constants.fahrenheitFormat, fahrenheit)
    }
    
    // MARK: - User Defaults
    
    func saveLastSearchedCity(_ city: String) {
        UserDefaults.standard.set(city, forKey: Constants.lastSearchedCityKey)
    }
    
    func loadLastSearchedCity() -> String? {
        return UserDefaults.standard.string(forKey: Constants.lastSearchedCityKey)
    }
}
