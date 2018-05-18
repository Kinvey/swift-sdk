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

/// Class that represents a 2D geolocation with latitude and longitude
public final class GeoPoint: Object {
    
    /// Specifies the north–south position of a point
    @objc
    open dynamic var latitude: CLLocationDegrees = 0.0
    
    /// Specifies the east-west position of a point
    @objc
    open dynamic var longitude: CLLocationDegrees = 0.0
    
    /**
     Constructor that takes `CLLocationDegrees` (`Double`) values for latitude
     and longitude
     */
    public convenience init(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees
    ) {
        self.init()
        self.latitude = latitude
        self.longitude = longitude
    }
    
    /// Constructor that takes a `CLLocationCoordinate2D`
    public convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
    
    /**
     Constructor that takes an array of `CLLocationDegrees` (`Double`) values
     for longitude and latitude (in this order)
     */
    convenience init(_ array: [CLLocationDegrees]) {
        self.init(latitude: array[1], longitude: array[0])
    }
    
}

/**
 Make the GeoPoint implement Mappable, so we can serialize and deserialize
 GeoPoint
 */
extension GeoPoint: Mappable {
    
    public convenience init?(map: Map) {
        guard let _: Double = map["latitude"].value(), let _: Double = map["longitude"].value() else {
            return nil
        }
        self.init()
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
    let transform = GeoPointTransform()
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    left <- (map, transform)
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- (left: inout GeoPoint?, right: (String, Map)) {
    let (right, map) = right
    let transform = GeoPointTransform()
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    left <- (map, transform)
}

func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}

extension CLLocation {
    
    /**
     Constructor that takes a `GeoPoint` to make it easy to convert to a
     `CLLocation` instance
     */
    public convenience init(geoPoint: GeoPoint) {
        self.init(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
    }
    
}

extension CLLocationCoordinate2D {
    
    /**
     Constructor that takes a `GeoPoint` to make it easy to convert to a
     `CLLocationCoordinate2D` instance
     */
    public init(geoPoint: GeoPoint) {
        self.init(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
    }
    
}
