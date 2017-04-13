//
//  Geolocation.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-02-01.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper
import CoreLocation
import MapKit

open class GeoPoint: Object, Mappable {
    
    open dynamic var latitude: CLLocationDegrees = 0.0
    open dynamic var longitude: CLLocationDegrees = 0.0
    
    public convenience required init?(map: Map) {
        guard let _: Double = map["latitude"].value(), let _: Double = map["longitude"].value() else {
            return nil
        }
        self.init()
    }
    
    public convenience init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.init()
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    convenience init(_ array: [CLLocationDegrees]) {
        self.init(latitude: array[1], longitude: array[0])
    }
    
    public func mapping(map: Map) {
        latitude <- map["latitude"]
        longitude <- map["longitude"]
    }
    
}

class GeoPointTransform: TransformOf<GeoPoint, [CLLocationDegrees]> {
    
    init() {
        super.init(fromJSON: { (array) -> GeoPoint? in
            if let array = array, array.count == 2 {
                return GeoPoint(array)
            }
            return nil
        }, toJSON: { (geopoint) -> [CLLocationDegrees]? in
            if let geopoint = geopoint {
                return [geopoint.longitude, geopoint.latitude]
            }
            return nil
        })
    }
    
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- (left: inout GeoPoint, right: (String, Map)) {
    let (right, map) = right
    kinveyMappingType(left: right, right: map.currentKey!)
    left <- (map, GeoPointTransform())
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- (left: inout GeoPoint?, right: (String, Map)) {
    let (right, map) = right
    kinveyMappingType(left: right, right: map.currentKey!)
    left <- (map, GeoPointTransform())
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- (left: inout GeoPoint!, right: (String, Map)) {
    let (right, map) = right
    kinveyMappingType(left: right, right: map.currentKey!)
    left <- (map, GeoPointTransform())
}

func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}

extension CLLocation {
    
    public convenience init(geoPoint: GeoPoint) {
        self.init(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
    }
    
}

extension CLLocationCoordinate2D {
    
    public init(geoPoint: GeoPoint) {
        self.init(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
    }
    
}
