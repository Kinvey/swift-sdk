//
//  Bus.swift
//  BuSber
//
//  Created by Vinay Gahlawat on 5/3/16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Kinvey
import MapKit

class Bus : NSObject, Persistable, MKAnnotation
{
    dynamic var _id: String?
    dynamic var name: String?
    dynamic var location: Array<Double>?
    
    static func kinveyCollectionName() -> String {
        return "Bus"
    }
    
    static func kinveyPropertyMapping() -> [String : String] {
        return ["_id": PersistableIdKey, "name": "name", "location": "location"]
    }
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: CLLocationDegrees(location![1]), longitude: CLLocationDegrees(location![0]))
        }
    }
    
    var title: String? {
        get {
            return name
        }
    }
}
