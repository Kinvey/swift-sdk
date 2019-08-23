//
//  RealmMapKitSupport.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2019-08-21.
//  Copyright © 2019 Kinvey. All rights reserved.
//

import Foundation
import MapKit

#if !os(watchOS)
    internal func tupleMKShape(predicate: NSPredicate) -> (NSComparisonPredicate, (keyPathExpression: NSExpression, constantValueExpression: NSExpression), Any)? {
        if let predicate = predicate as? NSComparisonPredicate,
            let keyPathConstantTuple = predicate.keyPathConstantTuple,
            let constantValue = keyPathConstantTuple.constantValueExpression.constantValue,
            constantValue is MKCircle || constantValue is MKPolygon
        {
            return (predicate, keyPathConstantTuple, constantValue)
        }
        return nil
    }
#endif

extension AnyRandomAccessCollection where Element: NSObject, Element: Persistable {
    
    internal func filter(predicate: NSPredicate) -> AnyRandomAccessCollection<Iterator.Element> {
        #if !os(watchOS)
            if let (_, keyPathConstantTuple, constantValue) = tupleMKShape(predicate: predicate) {
                if let circle = constantValue as? MKCircle {
                    let center = CLLocation(latitude: circle.coordinate.latitude, longitude: circle.coordinate.longitude)
                    return AnyRandomAccessCollection(filter({ (item) -> Bool in
                        if let geoPoint = item[keyPathConstantTuple.keyPathExpression.keyPath] as? GeoPoint {
                            return CLLocation(geoPoint: geoPoint).distance(from: center) <= circle.radius
                        }
                        return false
                    }))
                } else if let polygon = constantValue as? MKPolygon {
                    let pointCount = polygon.pointCount
                    var coordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: polygon.pointCount)
                    polygon.getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
                    if let first = coordinates.first, let last = coordinates.last, first == last {
                        coordinates.removeLast()
                    }
                    #if os(OSX)
                    let path = NSBezierPath()
                    #else
                    let path = UIBezierPath()
                    #endif
                    for (i, coordinate) in coordinates.enumerated() {
                        let point = CGPoint(x: coordinate.latitude, y: coordinate.longitude)
                        switch i {
                        case 0:
                            path.move(to: point)
                        default:
                            #if os(OSX)
                            path.line(to: point)
                            #else
                            path.addLine(to: point)
                            #endif
                        }
                    }
                    path.close()
                    return AnyRandomAccessCollection(filter({ (item) -> Bool in
                        if let geoPoint = item[keyPathConstantTuple.keyPathExpression.keyPath] as? GeoPoint {
                            return path.contains(CGPoint(x: geoPoint.latitude, y: geoPoint.longitude))
                        }
                        return false
                    }))
                }
            }
        #endif
        return self
    }
    
}
