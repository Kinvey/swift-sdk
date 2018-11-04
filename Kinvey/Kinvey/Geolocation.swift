//
//  Geolocation.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-02-01.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift
import CoreLocation
import MapKit

/// Class that represents a 2D geolocation with latitude and longitude
public final class GeoPoint: Object {
    
    /// Specifies the north–south position of a point
    @objc
    public dynamic var latitude: CLLocationDegrees = 0.0
    
    /// Specifies the east-west position of a point
    @objc
    public dynamic var longitude: CLLocationDegrees = 0.0
    
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

extension GeoPoint: Encodable {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(longitude)
        try container.encode(latitude)
    }
    
}

extension GeoPoint: Decodable {
    
    public convenience init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let longitude = try container.decode(CLLocationDegrees.self)
        let latitude = try container.decode(CLLocationDegrees.self)
        self.init(latitude: latitude, longitude: longitude)
    }
    
}

/**
 Make the GeoPoint implement Mappable, so we can serialize and deserialize
 GeoPoint
 */
@available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
extension GeoPoint: Mappable {
    
    @available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    public convenience init?(map: Map) {
        guard let _: Double = map["latitude"].value(), let _: Double = map["longitude"].value() else {
            return nil
        }
        self.init()
    }
    
    @available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    public func mapping(map: Map) {
        latitude <- ("latitude", map["latitude"])
        longitude <- ("longitude", map["longitude"])
    }
    
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
