//
//  WeatherViewController.swift
//  JPWeather
//
//  Created by Ilgar Ilyasov on 9/7/24.
//

import CoreLocation
import UIKit

private enum Constants {
    // UI Strings
    static let enterCityPlaceholder = "Enter city"
    static let fetchingLocationPlaceholder = "Fetching location..."
    static let searchButtonTitle = "Search"
    
    // Error Messages
    static let errorFetchingWeather = "Error fetching weather: "
    static let errorLocationAccessDenied = "Location access denied. Please enable it in Settings."
    static let errorFailedToGetLocationFormat = "Failed to get user location. Please try again later. (%@)"
    static let cityNameMissing = "Please enter a city name."
    
    // Layout Spacing
    static let stackViewSpacing: CGFloat = 16
    static let stackViewHorizontalPadding: CGFloat = 20
}

class WeatherViewController: UIViewController {

    // MARK: - Properties
    
    private let viewModel = WeatherViewModel()
    private let locationManager = CLLocationManager()

    // MARK: - UI Components
    
    private let cityTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = Constants.enterCityPlaceholder
        textField.borderStyle = .roundedRect
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return textField
    }()
    
    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(Constants.searchButtonTitle, for: .normal)
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return button
    }()
    
    private let cityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.text = Constants.fetchingLocationPlaceholder
        return label
    }()
    
    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        label.textAlignment = .center
        return label
    }()
    
    private let weatherIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fetchInitialWeatherData()
        setupUI()
        bindViewModel()
        setupButtonActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Helper Methods

    private func fetchInitialWeatherData() {
        if let lastCity = viewModel.loadLastSearchedCity() {
            viewModel.fetchWeather(forCity: lastCity)
        } else {
            requestLocationAccess()
        }
    }

    private func setupUI() {
        cityTextField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        setupLayout()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupLayout() {
        let searchStack = UIStackView(arrangedSubviews: [
            cityTextField, searchButton
        ])
        searchStack.axis = .horizontal
        searchStack.spacing = Constants.stackViewSpacing
        searchStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchStack)
        
        let temperatureStack = UIStackView(arrangedSubviews: [
            temperatureLabel, weatherIconImageView
        ])
        temperatureStack.axis = .horizontal
        temperatureStack.distribution = .fillProportionally
        temperatureStack.spacing = Constants.stackViewSpacing
        temperatureStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(temperatureStack)
        
        let stackView = UIStackView(arrangedSubviews: [
            searchStack,
            cityLabel,
            temperatureStack
        ])
        stackView.axis = .vertical
        stackView.spacing = Constants.stackViewSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: Constants.stackViewHorizontalPadding),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: -Constants.stackViewHorizontalPadding)
        ])
    }

    private func bindViewModel() {
        viewModel.didUpdateWeather = { [weak self] in
            DispatchQueue.main.async {
                self?.updateUI()
            }
        }
        
        viewModel.didFailWithError = { [weak self] error in
            self?.showErrorAlert(with: Constants.errorFetchingWeather + error.localizedDescription)
        }
    }

    private func setupButtonActions() {
        searchButton.addAction(UIAction { [weak self] _ in
            self?.didTapSearch()
        }, for: .touchUpInside)
    }
    
    // MARK: - Update UI
    
    private func updateUI() {
        cityLabel.text = viewModel.cityName
        temperatureLabel.text = viewModel.temperatureInFahrenheit
        weatherIconImageView.image = viewModel.weatherIcon
    }
    
    // MARK: - Button Actions
    
    func didTapSearch() {
        view.endEditing(true)
        
        guard let city = cityTextField.text,
                !city.isEmpty else {
            showErrorAlert(with: Constants.cityNameMissing)
            return
        }
        viewModel.saveLastSearchedCity(city)
        viewModel.fetchWeather(forCity: city)
    }
    
    func didTapCurrentLocationButton() {
        requestLocationAccess()
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherViewController: CLLocationManagerDelegate {
    private func requestLocationAccess() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            showErrorAlert(with: Constants.errorLocationAccessDenied)
        case .notDetermined:
            // Wait until the user responds to the permission request.
            break
        default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        handleAuthorizationStatus(status)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.first else { return }
        
        let latitude = currentLocation.coordinate.latitude
        let longitude = currentLocation.coordinate.longitude
        
        viewModel.fetchWeatherForCurrentLocation(latitude: latitude, longitude: longitude)
        
        locationManager.stopUpdatingLocation() // Stop to save battery
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let errorMessage = String(format: Constants.errorFailedToGetLocationFormat, error.localizedDescription)
        showErrorAlert(with: errorMessage)
    }
}

extension WeatherViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // Dismiss the keyboard
        return true
    }
}
