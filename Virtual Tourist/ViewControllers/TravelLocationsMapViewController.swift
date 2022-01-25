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

// TODO: Save current map location & Resolution

class TravelLocationsMapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!

    var dataController: DataController!
    var pin: VTLocationPin!
    var fetchResultsController: NSFetchedResultsController<VTLocationPin>!
    lazy var locationManager: CLLocationManager = {
        var manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        return manager
    }()
    
    @IBAction func searchButtonTapped(_ sender: UIBarButtonItem) {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        present(searchController, animated: true, completion: nil)
    }
    
    fileprivate func setUpFetchResultsController() {
        let fetchRequst: NSFetchRequest<VTLocationPin> = VTLocationPin.fetchRequest()
        // sort by longitude, since NSFetchResultsController requires consistent ordering
        let sortDescriptor = NSSortDescriptor(key: "long", ascending: false)
        fetchRequst.sortDescriptors = [sortDescriptor]
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequst, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultsController.delegate = self
        do {
            try fetchResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        mapView.delegate = self
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))
        mapView.addGestureRecognizer(longPressGestureRecognizer)
        
        setUpFetchResultsController()

        _ = loadSavedLocations()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchResultsController = nil
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
//        redrawPin(pin)
    }
    
    func removePin(forAnnotation pin: MKAnnotation) {
        let contains = NSPredicate(format: "lat == %lf AND long == %lf", pin.coordinate.latitude, pin.coordinate.longitude)
        
        if let pins = self.loadSavedLocations(redraw: false) {
            let toRemove = pins.filter { location in
                contains.evaluate(with: location)
            }
            debugPrint("Removing location @ \(toRemove.first)")
            dataController.viewContext.delete(toRemove.first!)
            try? dataController.viewContext.save()
            loadSavedLocations()
        }
    }
    
    fileprivate func redrawPin(_ pin: VTLocationPin) {
        let pinAnnotation = MKPointAnnotation()
        pinAnnotation.coordinate = CLLocationCoordinate2DMake(pin.lat, pin.long)
        pinAnnotation.title = "POI@(lat:\(pin.lat),long:\(pin.long)"
        mapView.addAnnotation(pinAnnotation)
    }
    
    fileprivate func loadSavedLocations(redraw: Bool = true) -> [VTLocationPin]? {
        let fetchRequst: NSFetchRequest<VTLocationPin> = VTLocationPin.fetchRequest()
        if let pins = try? dataController.viewContext.fetch(fetchRequst) {
            debugPrint("pulled \(pins.count) pins from CoreData store.")
            if redraw {
                for pin in pins {
                    redrawPin(pin)
                }
            }
            
            return pins
        }
        
        return nil
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
            pinView!.rightCalloutAccessoryView = UIButton(type: .infoDark)
            pinView?.leftCalloutAccessoryView = UIButton(type: .close)
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
        
        if control == view.leftCalloutAccessoryView {
            debugPrint("delete annotation")
            self.removePin(forAnnotation: view.annotation as! MKAnnotation)
            mapView.removeAnnotation(view.annotation as! MKAnnotation)
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

// MARK: - NSFetchedResultsControllerDelegate Methods
extension TravelLocationsMapViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let newPin = anObject as! VTLocationPin
        switch type {
        case .insert:
            debugPrint("New pin inserted: \(newPin.lat), \(newPin.long)")
            redrawPin(newPin)
        case .delete:
            break
        default:
            break
        }
    }
}

// MARK: - UISearchBarDelegate Methods
extension TravelLocationsMapViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        UIApplication.shared.beginIgnoringInteractionEvents()
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.style = .gray
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        self.view.addSubview(activityIndicator)
        
        // hide searchBar
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        
        // create search request
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchBar.text
        let activeSearch = MKLocalSearch(request: searchRequest)
        activeSearch.start { response, err in
            activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            guard let response = response else {
                print("Something went wrong searching the location: \(err?.localizedDescription)")
                return
            }
            
            // Get data
            let lat = response.boundingRegion.center.latitude
            let long = response.boundingRegion.center.longitude
            
            self.addPin(long: long, lat: lat)
            
            // Zoom-in on new pin
            let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, long)
            let span = MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            self.mapView.setRegion(region, animated: true)
        }
    }
}
