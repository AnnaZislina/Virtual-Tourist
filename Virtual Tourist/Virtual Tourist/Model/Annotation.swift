//
//  Annotation.swift
//  Virtual Tourist
//
//  Created by Anna Zislina on 04/11/2019.
//  Copyright © 2019 Anna Zislina. All rights reserved.
//

import MapKit

class Annotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var id: String?
    var title: String?
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
