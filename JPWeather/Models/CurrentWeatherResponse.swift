//
//  CurrentWeatherResponse.swift
//  JPWeather
//
//  Created by Ilgar Ilyasov on 9/7/24.
//

import Foundation

struct CurrentWeatherResponse: Codable {
    let cityName: String
    let mainWeather: MainWeather
    let weatherConditions: [WeatherCondition]
    
    enum CodingKeys: String, CodingKey {
        case cityName = "name"
        case mainWeather = "main"
        case weatherConditions = "weather"
    }

    struct MainWeather: Codable {
        let temperature: Double
        let humidity: Int?
        
        enum CodingKeys: String, CodingKey {
            case temperature = "temp"
            case humidity
        }
    }

    struct WeatherCondition: Codable {
        let description: String?
        let iconCode: String?
        
        enum CodingKeys: String, CodingKey {
            case description
            case iconCode = "icon"
        }
    }
}
