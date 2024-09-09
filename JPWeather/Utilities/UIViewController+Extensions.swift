//
//  UIViewController+Extensions.swift
//  JPWeather
//
//  Created by Ilgar Ilyasov on 9/7/24.
//

import UIKit

extension UIViewController {
    func showErrorAlert(with message: String, title: String = "Error") {
        DispatchQueue.main.async { [weak self] in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            alertController.accessibilityLabel = title
            alertController.accessibilityHint = "Error message"
            self?.present(alertController, animated: true, completion: nil)
        }
    }
}
