//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Anna Zislina on 29/10/2019.
//  Copyright © 2019 Anna Zislina. All rights reserved.
//

import Foundation
import MapKit
import CoreData
import UIKit


class TravelLocationsMapViewController: UIViewController  {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var deleteLabel: UILabel!
    
    var dataController: DataController!
    var annotations = [Annotation]()
    var onEdit = false

    override func viewDidLoad() {
        super.viewDidLoad()

        saveMap()
        longPress()
        fetchPins()
        deleteLabel.isHidden = true
    }

//MARK: Set Region

    func saveMap() {
        let userDefaults = UserDefaults.standard
        if UserDefaults.standard.bool(forKey: "FirstLaunch") {
            let centerLatitude = userDefaults.double(forKey: "Latitude")
            let centerLongitude = userDefaults.double(forKey: "Longitude")
            let latitudeDelta = userDefaults.double(forKey: "LatitudeDelta")
            let longitudeDelta = userDefaults.double(forKey: "LongitudeDelta")
            
            let centerCoordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
            let spanCoordinate = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            let region = MKCoordinateRegion(center: centerCoordinate, span: spanCoordinate)
            
            updateOnMainThread {
                self.mapView.setRegion(region, animated: true)
            }
        } else {
            userDefaults.set(true, forKey: "FirstLaunch")
        }
    }
    
//MARK: Long Press Gesture Recognizer
    
    fileprivate func longPress() {
           let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressResponse(press:)))
           mapView.addGestureRecognizer(longPress)
       }
    
    @objc func longPressResponse(press: UILongPressGestureRecognizer) {
        if press.state == .began {
            let location = press.location(in: mapView)
            let coordinates = mapView.convert(location, toCoordinateFrom: mapView)
            
            addPin(coordinate: coordinates) { (pin, coordinate) in
                let annotation = Annotation(coordinate: coordinate)
                annotation.coordinate = coordinate
                annotation.id = pin.id!
                updateOnMainThread {
                    self.mapView.addAnnotation(annotation)
                }
            }
        }
    }
    
//MARK: Pin Methods
    
    func addPin(coordinate: CLLocationCoordinate2D, created: (Pin, CLLocationCoordinate2D) -> Void) {
        let pin = Pin(context: dataController.viewContext)
        pin.id = UUID().uuidString
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        pin.createdAt = Date()
        created(pin, coordinate)
        try? dataController.viewContext.save()
    }
    
    func fetchPins() {
    
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            setupPin(pins: try dataController.viewContext.fetch(fetchRequest))
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func deletePin(id: String?, completion: (Bool) -> Void) {
        guard let id = id else {
                completion(false)
                return
            }
       
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let predicate = NSPredicate(format: "id == %@", id)
        fetchRequest.predicate = predicate

        do {
            let pins = try self.dataController.viewContext.fetch(fetchRequest)
            for pin in pins {
                dataController.viewContext.delete(pin)
            }
            completion(true)
            try dataController.viewContext.save()
        } catch {
            completion(false)
        }
    }

    func setupPin(pins: [Pin]) {
        annotations = pins.map { pin in
            let latitude = CLLocationDegrees(pin.latitude)
            let longitude = CLLocationDegrees(pin.longitude)
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let annotation = Annotation(coordinate: coordinate)
            annotation.id = pin.id
            return annotation
        }
        self.mapView.addAnnotations(annotations)
    }

//MARK: "Edit" Button
    
    @IBAction func edit(_ sender: Any) {
        if editButton.title == "Edit" {
            deleteLabel.isHidden = false
            editButton.title = "Done"
            onEdit = true
        } else {
            deleteLabel.isHidden = true
            editButton.title = "Edit"
            onEdit = false
        }
    }
}

//MARK: Map View

extension TravelLocationsMapViewController: MKMapViewDelegate {

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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? Annotation else { return }
        
        if (onEdit) {
            deletePin(id: annotation.id!) { completed in
                DispatchQueue.main.async {
                    if completed {
                        self.mapView.removeAnnotation(annotation)
                    } else {
                        fatalError()
                    }
                }
            }
        } else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
            vc.annotation = annotation
            vc.dataController = dataController
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(self.mapView.region.center.latitude, forKey: "Latitude")
        userDefaults.set(self.mapView.region.center.longitude, forKey: "Longitude")
        userDefaults.set(self.mapView.region.span.latitudeDelta, forKey: "LatitudeDelta")
        userDefaults.set(self.mapView.region.span.longitudeDelta, forKey: "LongitudeDelta")
    }
}


