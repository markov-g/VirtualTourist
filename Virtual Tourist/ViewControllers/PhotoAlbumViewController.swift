//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Georgi Markov on 1/4/22.
//

import UIKit
import MapKit
import CoreData
import Alamofire
import AlamofireImage

class PhotoAlbumViewController: UIViewController {
    var dataController: DataController!
    var pictures: [VTPictures] = [VTPictures]()
    var currentLocationPin: VTLocationPin!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
                
    @IBAction func newCollectionButtonTapped(_ sender: UIButton) {
    }
    
    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        redrawPin(currentLocationPin)
                        
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - (2*space)) / 3.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        if currentLocationPin.pictures?.count == 0 {
            fetchPhotos()
            collectionView.reloadData()
        } else {
            debugPrint("Found \(currentLocationPin.pictures?.count) pictures associated with location: (\(currentLocationPin.lat), \(currentLocationPin.long)")
        }
    }
    
    fileprivate func fetchPhotos() {
        // APIClient.oauthorize()
        // APIClient.requestImagesForLocation(latitude: currentLocationPin.lat, longitude: currentLocationPin.long, completion: handleImageResponse(imageURLs:error:))
            
        // use unsigned instead ^^^
        APIClient.requestImagesForLocationUnsigned(latitude: currentLocationPin.lat, longitude: currentLocationPin.long, completion: handleImageResponse(imageURLs:error:))
    }
    
    func handleImageResponse(imageURLs: [URL]?, error: Error?) {
        if error != nil {
            showFailure(title: "Image Retrieval Failed", message: error?.localizedDescription ?? "Something went wrong trying to pull images for location: \(currentLocationPin.lat), \(currentLocationPin.long)")
        }
        if let imageURLs = imageURLs {
            debugPrint("Recevied \(imageURLs.count) image URLs for location: \(currentLocationPin.lat), \(currentLocationPin.long)")
            imageURLs.forEach { (imageURL) in
                AF.request(imageURL).responseImage { response in
                    if case .success(let image) = response.result {
                        let pic = VTPictures(context: self.dataController.viewContext)
                        pic.image = image.jpegData(compressionQuality: 1)
                        pic.url = imageURL
                        pic.locationPin = self.currentLocationPin
                        self.pictures.append(pic)
                    }
                    else {
                        fatalError("could not download images for url: \(imageURL)")
                    }
                }
            }
        }
    }
    
   
    func redrawPin(_ pin: VTLocationPin) {
        let pinAnnotation = MKPointAnnotation()
        pinAnnotation.coordinate = CLLocationCoordinate2DMake(pin.lat, pin.long)
        pinAnnotation.title = "POI@(lat:\(pin.lat),long:\(pin.long)"
        mapView.addAnnotation(pinAnnotation)
    }
    
    fileprivate func loadSavedPictures(redraw: Bool = true) -> [VTPictures]? {
        let fetchRequst: NSFetchRequest<VTPictures> = VTPictures.fetchRequest()
        //TODO: Filter with predicate only pictures for current location
        if let pictures = try? dataController.viewContext.fetch(fetchRequst) {
            debugPrint("pulled \(pictures.count) pins from CoreData store.")
            return pictures
        }
        
        return nil
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pictures.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "me.gmarkov.CollectionCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        cell.POIImageView.image = UIImage(data: (pictures.first!.image)!)
        return cell
    }
}
