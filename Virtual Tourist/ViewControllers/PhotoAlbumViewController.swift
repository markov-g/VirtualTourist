//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Georgi Markov on 1/4/22.
//


// TODO: Networking features
import UIKit
import MapKit
import CoreData
import Alamofire
import AlamofireImage

class PhotoAlbumViewController: UIViewController {
    var dataController: DataController!
    var fetchResultsController: NSFetchedResultsController<VTPictures>!
    var picture_page: Int = 1
    var pictures: [VTPictures] = [VTPictures]() {
        didSet {
            self.saveState()
            self.collectionView.reloadData()
        }
    }
    var currentLocationPin: VTLocationPin!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
                
    @IBAction func newCollectionButtonTapped(_ sender: UIButton) {
        for (n, p) in pictures.enumerated() {
            dataController.viewContext.delete(pictures[n])
        }
        saveState()
        if let pics = loadSavedPictures() {
            self.pictures = pics
        }
        collectionView.reloadData()
    }
    
    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
   
    fileprivate func setUpFetchResultsController() {
        let fetchRequst: NSFetchRequest<VTPictures> = VTPictures.fetchRequest()
        // sort by longitude, since NSFetchResultsController requires consistent ordering
        let sortDescriptor = NSSortDescriptor(key: "url.host", ascending: false)
        fetchRequst.sortDescriptors = [sortDescriptor]
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequst, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultsController.delegate = self
        do {
            try fetchResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func loadSavedPhotos(for locationPin: VTLocationPin) -> [VTPictures]? {
        let fetchRequst: NSFetchRequest<VTPictures> = VTPictures.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "url.host", ascending: false)
        let predicate = NSPredicate(format: "locationPin == %@", locationPin)
        fetchRequst.predicate = predicate
        fetchRequst.sortDescriptors = [sortDescriptor]
        if let photos = try? dataController.viewContext.fetch(fetchRequst) {
            debugPrint("pulled \(photos.count) pictures from CoreData store.")
            
            return photos
        }
        
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        setUpFetchResultsController()
        
        redrawPin(currentLocationPin)
        
//        newCollectionButton.isEnabled = false
                        
        let space: CGFloat = 2.0
        let dimension = (view.frame.size.width - (1*space)) / 2.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        collectionView.collectionViewLayout = flowLayout
        
        if currentLocationPin.pictures?.count == 0 {
            fetchPhotos()
        } else {
            if let pics = loadSavedPhotos(for: currentLocationPin) {
                self.pictures = pics
                if self.pictures.count < APIClient.Constants.NUM_OF_PHOTOS {
                    fetchPhotos()
                }
            }
        }
        
        collectionView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchResultsController = nil
    }
    
    fileprivate func fetchPhotos() {
        // APIClient.oauthorize()
        // APIClient.requestImagesForLocation(latitude: currentLocationPin.lat, longitude: currentLocationPin.long, completion: handleImageResponse(imageURLs:error:))
            
        // use unsigned instead ^^^
//        self.pictures.removeAll()
        picture_page += 1
        var nr_phtotos_to_download = 0
        let p = APIClient.Constants.NUM_OF_PHOTOS - pictures.count
        if p > 0 {
            nr_phtotos_to_download = p
        }
        APIClient.requestImagesForLocationUnsigned(latitude: currentLocationPin.lat, longitude: currentLocationPin.long, nr_photos: nr_phtotos_to_download, page: picture_page, completion: handleImageResponse(imageURLs:error:))
    }
    
    fileprivate func saveState() {
        do {
            try dataController.viewContext.save()
        }
        catch {
            debugPrint("there was a problem saving the state")
        }
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
                        if self.pictures.count < APIClient.Constants.NUM_OF_PHOTOS {
                            self.pictures.append(pic)
                        }
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
        let currentLocationFilter = NSPredicate(format: "ANY locationPin == %@", currentLocationPin)
        fetchRequst.predicate = currentLocationFilter
        
        if let pictures = try? dataController.viewContext.fetch(fetchRequst) {
            debugPrint("pulled \(pictures.count) pins from CoreData store.")
            return pictures
        }
        
        return nil
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return APIClient.Constants.NUM_OF_PHOTOS //pictures.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "me.gmarkov.CollectionCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        if pictures.indices.contains(indexPath.row) {
            cell.POIImageView.image = UIImage(data: (pictures[indexPath.row].image)!)
        }
        else {
            cell.POIImageView.image = UIImage(named: "placeholder")
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            debugPrint("removing picture @ \(indexPath.row)")
            dataController.viewContext.delete(pictures[indexPath.row])
            saveState()
            if let pics = loadSavedPictures() {
                self.pictures = pics
            }
            collectionView.reloadData()
            
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate Methods
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            break
        case .delete:
            fetchPhotos()
            break
        default:
            break
        }
    }
}

extension URL {
    public func compare(_ other: URL) -> ComparisonResult {
        self.absoluteString.compare(other.absoluteString)
    }
}
