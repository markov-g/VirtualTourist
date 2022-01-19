//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Georgi Markov on 1/4/22.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController {
    var dataController: DataController!
    var pictures: VTPictures!
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
    
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "me.gmarkov.CollectionCell", for: indexPath)
        return cell
    }
    
    
}
