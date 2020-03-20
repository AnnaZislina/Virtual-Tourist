//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Anna Zislina on 29/10/2019.
//  Copyright © 2019 Anna Zislina. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollection: UIButton!
    @IBOutlet weak var noPhotosLabel: UILabel!
    
    var photos = [Photo]()
    var annotation: Annotation!
    var dataController: DataController!
    var per_page = 30
    var pages = 1
    var selectedToRemove:[Int] = [] {
        didSet {
            if selectedToRemove.count > 0 {
                newCollection.setTitle("Remove Selected Photos", for: .normal)
            } else {
                newCollection.setTitle("New Photo Collection", for: .normal)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        
        setupPin()
        flowLayout()
        downloadPhotos()

        noPhotosLabel.isHidden = true
        newCollection.isHidden = false
        collectionView.allowsMultipleSelection = true
    }
    
//MARK: Collection View Flow Layout
    
    func flowLayout() {

        let flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 120, height: 120)
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 3, bottom: 2, right: 3)
        collectionView.collectionViewLayout = flowLayout
    }
    
//MARK: Setup Pin
    
    func setupPin() {
        
        let latitude = annotation.coordinate.latitude
        let longitude = annotation.coordinate.longitude
        let radius: CLLocationDistance = 10000
        let location: CLLocation = CLLocation(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: radius, longitudinalMeters: radius)
        
        mapView.setRegion(region, animated: true)
        self.mapView.addAnnotation(annotation)
    }
    
//MARK: Setup Photos
    
    func setupPhotos(_ flickrPhotos: FlickrImages) {
        
        guard let id = annotation.id else {
            return
        }
        photos = flickrPhotos.photo.map { flickrPhoto in
            let photo = Photo(context: dataController.viewContext)
            photo.url = FlickrURL.getFlickrImage(flickrPhoto)
            photo.createdAt = Date()
            photo.id = UUID().uuidString
            photo.pinID = id
            return photo
        }
        updateOnMainThread {
            self.newCollection.isEnabled = true
            self.collectionView.reloadData()
        }
    }
    
//MARK: Fetch Photos
    
    func fetchPhotos(id: String) -> [Photo] {
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let predicate = NSPredicate(format: "pinID == %@", id)
        fetchRequest.predicate = predicate
        
        do {
            return try dataController.viewContext.fetch(fetchRequest)
        } catch {
        }
        return [Photo]()
    }
    
//MARK: Download Photos
    
    func downloadPhotos() {
        
        if let id = annotation.id {
            photos = fetchPhotos(id: id)
            if photos.isEmpty {
                downloadPhotoAlbum(coordinate: annotation.coordinate)
            } else {
                newCollection.isEnabled = true
                collectionView.reloadData()
            }
        }
    }
    
//MARK: Download Photo Album
    
    func downloadPhotoAlbum(coordinate: CLLocationCoordinate2D) {
        
        guard let rest = Endpoint.rest.getURL().rest else { return }

        if let url = Endpoint.rest.getURL().url {
            let random = min(pages, 4000/per_page)
            rest.urlQueryParameters.add(value: "\(coordinate.latitude)", forKey: "lat")
            rest.urlQueryParameters.add(value: "\(coordinate.longitude)", forKey: "lon")
            rest.urlQueryParameters.add(value: "\(random)", forKey: "page")
            
            updateOnMainThread {
                self.newCollection.isEnabled = false
            }
            
            rest.makeRequest(toURL: url, withHttpMethod: .get) { results in
                if results.error == nil {
                    guard let data = results.data else { return }
                    
                    FlickrClient<FlickrStat>().decode(data: data) { result in
                        switch result {
                        case .success(let response):
                            if !response.photos.photo.isEmpty {
                                self.setupPhotos(response.photos)
                                self.pages = response.photos.pages
                            } else {
                                updateOnMainThread {
                                    self.noPhotosLabel.isHidden = false
                                }
                            }
                        case .failure(_):
                            print("There is an error occurred")
                            
                        }
                    }
                }
            }
        }
    }

//MARK: Unselect All Selected Items
    
    func unselectAll() {
        
        for indexPath in collectionView.indexPathsForSelectedItems! {
            collectionView.deselectItem(at: indexPath, animated: false)
            collectionView.cellForItem(at: indexPath)?.contentView.alpha = 1
        }
    }

//MARK: Remove Selected Photos From Core Data
    
    func removeSelectedPhotos() {
        
        for index in 0..<photos.count {
            if selectedToRemove.contains(index) {
                dataController.viewContext.delete(photos[index])
            }
        }
        do {
            try dataController.viewContext.save()
        } catch {
            print("Removing Photos Error")
        }
        selectedToRemove.removeAll()
    }

//MARK: Delete Photo From Core Data
    
    func deletePhoto() {
        
        for photo in photos {
            dataController.viewContext.delete(photo)
        }
    }
    
//MARK: "New Collection" Button
    
    @IBAction func newCollectionButton(_ sender: Any) {
        
        if selectedToRemove.count > 0 {
            removeSelectedPhotos()
            unselectAll()
            downloadPhotos()
            
            updateOnMainThread {
                self.collectionView.reloadData()
            }
            
        } else {
            newCollection.isEnabled = false
            deletePhoto()
            photos.removeAll()
            downloadPhotos()
            collectionView.reloadData()
        }
    }
}

//MARK: Map View

extension PhotoAlbumViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.animatesDrop = true
            pinView?.canShowCallout = false
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
}

//MARK: Collection View: Data Source & Delegate

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let photo = photos[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        cell.photo = photo
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func selectedToRemoveFromIndexPath(_ indexPathArray: [IndexPath]) -> [Int] {
        
        var selected:[Int] = []
        for indexPath in indexPathArray {
            selected.append(indexPath.row)
        }
        return selected
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        selectedToRemove = selectedToRemoveFromIndexPath(collectionView.indexPathsForSelectedItems!)
        let cell = collectionView.cellForItem(at: indexPath)
        updateOnMainThread {
            cell?.contentView.alpha = 0.5
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        selectedToRemove = selectedToRemoveFromIndexPath(collectionView.indexPathsForSelectedItems!)
        let cell = collectionView.cellForItem(at: indexPath)
        updateOnMainThread {
            cell?.contentView.alpha = 1
        }
    }
}
