//
//  QueryTest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-12.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
import MapKit
@testable import Kinvey

class QueryTest: XCTestCase {
    
    func encodeQuery(query: Query) -> String {
        return query.urlQueryStringEncoded().stringByRemovingPercentEncoding!
    }
    
    func encodeURL(query: JsonDictionary) -> String {
        let data = try! NSJSONSerialization.dataWithJSONObject(query, options: [])
        let str = String(data: data, encoding: NSUTF8StringEncoding)!
        return str
    }
    
    func testQueryEq() {
        XCTAssertEqual(encodeQuery(Query(format: "age == %@", 30)), encodeURL(["age" : 30]))
        XCTAssertEqual(encodeQuery(Query(format: "age = %@", 30)), encodeURL(["age" : 30]))
    }
    
    func testQueryGt() {
        XCTAssertEqual(encodeQuery(Query(format: "age > %@", 30)), encodeURL(["age" : ["$gt" : 30]]))
    }
    
    func testQueryGte() {
        XCTAssertEqual(encodeQuery(Query(format: "age >= %@", 30)), encodeURL(["age" : ["$gte" : 30]]))
    }
    
    func testQueryLt() {
        XCTAssertEqual(encodeQuery(Query(format: "age < %@", 30)), encodeURL(["age" : ["$lt" : 30]]))
    }
    
    func testQueryLte() {
        XCTAssertEqual(encodeQuery(Query(format: "age <= %@", 30)), encodeURL(["age" : ["$lte" : 30]]))
    }
    
    func testQueryNe() {
        XCTAssertEqual(encodeQuery(Query(format: "age != %@", 30)), encodeURL(["age" : ["$ne" : 30]]))
        XCTAssertEqual(encodeQuery(Query(format: "age <> %@", 30)), encodeURL(["age" : ["$ne" : 30]]))
    }
    
    func testQueryIn() {
        XCTAssertEqual(encodeQuery(Query(format: "colors IN %@", ["orange", "black"])), encodeURL(["colors" : ["$in" : ["orange", "black"]]]))
    }
    
    func testQueryOr() {
        XCTAssertEqual(encodeQuery(Query(format: "age = %@ OR age = %@", 18, 21)), encodeURL(["$or" : [["age" : 18], ["age" : 21]]]))
    }
    
    func testQueryAnd() {
        XCTAssertEqual(encodeQuery(Query(format: "age = %@ AND age = %@", 18, 21)), encodeURL(["$and" : [["age" : 18], ["age" : 21]]]))
    }
    
    func testQueryNot() {
        XCTAssertEqual(encodeQuery(Query(format: "NOT age = %@", 30)), encodeURL(["$not" : [["age" : 30]]]))
    }
    
    func testQueryRegex() {
        XCTAssertEqual(encodeQuery(Query(format: "name MATCHES %@", "acme.*corp")), encodeURL(["name" : ["$regex" : "acme.*corp"]]))
    }
    
    func testQueryGeoWithinCenterSphere() {
        let resultString = encodeQuery(Query(format: "location = %@", MKCircle(centerCoordinate: CLLocationCoordinate2D(latitude: 40.74, longitude: -74), radius: 10000)))
        let expectString = encodeURL(["location" : ["$geoWithin" : ["$centerSphere" : [ [-74, 40.74], 10/6378.1 ]]]])
        
        let result = try! NSJSONSerialization.JSONObjectWithData(resultString.dataUsingEncoding(NSUTF8StringEncoding)!, options: []) as? [String : [String : [String : [AnyObject]]]]
        let expect = try! NSJSONSerialization.JSONObjectWithData(expectString.dataUsingEncoding(NSUTF8StringEncoding)!, options: []) as? [String : [String : [String : [AnyObject]]]]
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(expect)
        
        if var result = result, var expect = expect {
            let centerSphereResult = result["location"]!["$geoWithin"]!["$centerSphere"]!
            let centerSphereExpect = expect["location"]!["$geoWithin"]!["$centerSphere"]!
            
            XCTAssertEqual(centerSphereResult.count, 2)
            XCTAssertEqual(centerSphereExpect.count, 2)
            
            if centerSphereResult.count == 2 && centerSphereExpect.count == 2 {
                let coordinatesResult = centerSphereResult[0] as! [Double]
                let coordinatesExpect = centerSphereExpect[0] as! [Double]
                
                XCTAssertEqual(coordinatesResult.count, 2)
                XCTAssertEqual(coordinatesExpect.count, 2)
                
                XCTAssertEqual(coordinatesResult, coordinatesExpect)
                
                XCTAssertEqualWithAccuracy(centerSphereResult[1] as! Double, centerSphereExpect[1] as! Double, accuracy: 0.00001)
            }
        }
    }
    
    func testQueryGeoWithinPolygon() {
        var coordinates = [CLLocationCoordinate2D(latitude: 40.74, longitude: -74), CLLocationCoordinate2D(latitude: 50.74, longitude: -74), CLLocationCoordinate2D(latitude: 40.74, longitude: -64)]
        let resultString = encodeQuery(Query(format: "location = %@", MKPolygon(coordinates: &coordinates, count: 3)))
        let expectString = encodeURL(["location" : ["$geoWithin" : ["$geometry" : ["type" : "Polygon", "coordinates" : [[-74, 40.74], [-74, 50.74], [-64, 40.74]]]]]])
        
        let result = try! NSJSONSerialization.JSONObjectWithData(resultString.dataUsingEncoding(NSUTF8StringEncoding)!, options: []) as? [String : [String : [String : [String : AnyObject]]]]
        let expect = try! NSJSONSerialization.JSONObjectWithData(expectString.dataUsingEncoding(NSUTF8StringEncoding)!, options: []) as? [String : [String : [String : [String : AnyObject]]]]
        
        if var result = result, var expect = expect {
            let geometryResult = result["location"]!["$geoWithin"]!["$geometry"]!
            let geometryExpect = expect["location"]!["$geoWithin"]!["$geometry"]!
            
            XCTAssertEqual(geometryResult["type"] as? String, geometryExpect["type"] as? String)
            
            let coordinatesResult = geometryResult["coordinates"] as? [[Double]]
            let coordinatesExpect = geometryExpect["coordinates"] as? [[Double]]
            
            XCTAssertNotNil(coordinatesResult)
            XCTAssertNotNil(coordinatesExpect)
            
            if let coordinatesResult = coordinatesResult, let coordinatesExpect = coordinatesExpect {
                XCTAssertEqual(coordinatesResult.count, coordinatesExpect.count)
                for (index, _) in coordinatesResult.enumerate() {
                    XCTAssertEqual(coordinatesResult[index].count, coordinatesExpect[index].count)
                }
            }
        }
    }
    
}
