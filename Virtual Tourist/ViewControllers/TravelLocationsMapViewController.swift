//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Georgi Markov on 1/4/22.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

// TODO: Use fatch results contoller and core data notifications to auto update annotations when new pins are added

class TravelLocationsMapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationSearchTextField: UITextField!
    var dataController: DataController!
    var pin: VTLocationPin!
    var savedPins: [VTLocationPin]!
    var fetchResultsController: NSFetchedResultsController<VTLocationPin>!
    lazy var locationManager: CLLocationManager = {
        var manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        return manager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        mapView.delegate = self
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))
        mapView.addGestureRecognizer(longPressGestureRecognizer)
        
        loadSavedLocations()
    }
    
    @objc private func onLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .ended else { return }
        
        let touchPoint = sender.location(in: mapView)
        let coordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        addPin(long: coordinates.longitude, lat: coordinates.latitude)
    }
    
    func addPin(long: Double, lat: Double) {
        pin = VTLocationPin(context: dataController.viewContext)
        pin.long = long
        pin.lat = lat
        try? dataController.viewContext.save()
        redrawPin(pin)
    }
    
    fileprivate func redrawPin(_ pin: VTLocationPin) {
        let pinAnnotation = MKPointAnnotation()
        pinAnnotation.coordinate = CLLocationCoordinate2DMake(pin.lat, pin.long)
        pinAnnotation.title = "Virtual Tourist POI @ (lat: \(pin.lat), long: \(pin.long)"
        mapView.addAnnotation(pinAnnotation)
    }
    
    fileprivate func loadSavedLocations() {
        // TODO:
        let fetchRequst: NSFetchRequest<VTLocationPin> = VTLocationPin.fetchRequest()
        if let pins = try? dataController.viewContext.fetch(fetchRequst) {
            self.savedPins = pins
            debugPrint("pulled \(self.savedPins.count) pins from CoreData store.")
            for pin in pins {
                redrawPin(pin)
            }
        }
    }
}

// MARK: - MKMapViewDelegate Methods
extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    // Here we create a view with a "right callout accessory view".
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .green
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            let app = UIApplication.shared
            presentPhotoAlbumVC()            
        }
    }
    
    fileprivate func presentPhotoAlbumVC() {
        let photoAlbumVC = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumVC") as! PhotoAlbumViewController
        photoAlbumVC.currentLocationPin = pin
        present(photoAlbumVC, animated: true, completion: nil)
    }
}

// MARK: - CLLocationManagerDelegate Methods
extension TravelLocationsMapViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
}
