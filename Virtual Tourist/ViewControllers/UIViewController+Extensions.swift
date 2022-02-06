//
//  UIViewController+Extensions.swift
//  Virtual Tourist
//
//  Created by Georgi Markov on 1/29/22.
//

import UIKit
import CoreLocation
import MapKit

extension UIViewController {
    func showFailure(title: String, message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        show(alertVC, sender: nil)
    }
}
