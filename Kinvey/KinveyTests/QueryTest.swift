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
    
    func encodeQuery(_ query: Query) -> String {
        var urlComponents = URLComponents(url: URL(string: "parse://")!, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = query.urlQueryItems
        return urlComponents.url!.query!
    }
    
    func convert(urlQueryItems: [URLQueryItem]?) -> [String : String]? {
        guard let urlQueryItems = urlQueryItems else {
            return nil
        }
        
        var result = [String : String](minimumCapacity: urlQueryItems.count)
        for urlQueryItem in urlQueryItems {
            result[urlQueryItem.name] = urlQueryItem.value!
        }
        return result
    }
    
    func convert(jsonDictionary : [String : Any]) -> [String : String] {
        var result = [String : String](minimumCapacity: jsonDictionary.count)
        for (key, value) in jsonDictionary {
            if let value = value as? String {
                result[key] = value
            } else if let value = value as? [String : Any] {
                result[key] = String(data: try! JSONSerialization.data(withJSONObject: value), encoding: .utf8)!
            } else {
                Swift.fatalError()
            }
        }
        return result
    }
    
    func encodeURL(_ query: JsonDictionary) -> String {
        let data = try! JSONSerialization.data(withJSONObject: query)
        let str = String(data: data, encoding: String.Encoding.utf8)!
        return str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    }
    
    func testQueryEq() {
        XCTAssertEqual(encodeQuery(Query(format: "age == %@", 30)), "query=\(encodeURL(["age" : 30]))")
        XCTAssertEqual(encodeQuery(Query(format: "age = %@", 30)), "query=\(encodeURL(["age" : 30]))")
        XCTAssertEqual(encodeQuery(Query(format: "obj._id == %@", 30)), "query=\(encodeURL(["obj._id" : 30]))")
        
        do {
            let client = Client(
                appKey: UUID().uuidString,
                appSecret: UUID().uuidString
            )
            
            var mockReached = false
            mockResponse(client: client) { (request) -> HttpResponse in
                let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                let query = components.queryItems!.filter { $0.name == "query" }.first!.value!
                XCTAssertEqual(query, "{\"obj._id\":30}")
                mockReached = true
                return HttpResponse(json: [])
            }
            defer {
                setURLProtocol(nil)
            }
            
            let dataStore = DataStore<Person>.collection(.network, client: client)
            let query = Query(format: "obj._id == %@", 30)
            
            weak var expectationFind = expectation(description: "Find")
            
            dataStore.find(query, options: Options(client: client)) { (result: Result<[Person], Swift.Error>) in
                switch result {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 0)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: 30) { (error) in
                expectationFind = nil
            }
            
            XCTAssertTrue(mockReached)
        }
    }
    
    func testQueryGt() {
        XCTAssertEqual(encodeQuery(Query(format: "age > %@", 30)), "query=\(encodeURL(["age" : ["$gt" : 30]]))")
    }
    
    func testQueryGte() {
        XCTAssertEqual(encodeQuery(Query(format: "age >= %@", 30)), "query=\(encodeURL(["age" : ["$gte" : 30]]))")
    }
    
    func testQueryLt() {
        XCTAssertEqual(encodeQuery(Query(format: "age < %@", 30)), "query=\(encodeURL(["age" : ["$lt" : 30]]))")
    }
    
    func testQueryLte() {
        XCTAssertEqual(encodeQuery(Query(format: "age <= %@", 30)), "query=\(encodeURL(["age" : ["$lte" : 30]]))")
    }
    
    func testQueryNe() {
        XCTAssertEqual(encodeQuery(Query(format: "age != %@", 30)), "query=\(encodeURL(["age" : ["$ne" : 30]]))")
        XCTAssertEqual(encodeQuery(Query(format: "age <> %@", 30)), "query=\(encodeURL(["age" : ["$ne" : 30]]))")
    }
    
    func testQueryIn() {
        XCTAssertEqual(encodeQuery(Query(format: "colors IN %@", ["orange", "black"])), "query=\(encodeURL(["colors" : ["$in" : ["orange", "black"]]]))")
    }
    
    func testQueryOr() {
        XCTAssertEqual(encodeQuery(Query(format: "age = %@ OR age = %@", 18, 21)), "query=\(encodeURL(["$or" : [["age" : 18], ["age" : 21]]]))")
    }
    
    func testQueryAnd() {
        XCTAssertEqual(encodeQuery(Query(format: "age = %@ AND age = %@", 18, 21)), "query=\(encodeURL(["$and" : [["age" : 18], ["age" : 21]]]))")
    }
    
    func testQueryNot() {
        XCTAssertEqual(encodeQuery(Query(format: "NOT age = %@", 30)), "query=\(encodeURL(["$not" : [["age" : 30]]]))")
    }
    
    func testQueryRegex() {
        XCTAssertEqual(encodeQuery(Query(format: "name MATCHES %@", "acme.*corp")), "query=\(encodeURL(["name" : ["$regex" : "acme.*corp"]]))")
    }

    func testQueryBeginsWith() {
        XCTAssertEqual(encodeQuery(Query(format: "name BEGINSWITH %@", "acme")), "query=\(encodeURL(["name" : ["$regex" : "^acme"]]))")
    }

    
    func testQueryGeoWithinCenterSphere() {
        let result = convert(urlQueryItems: Query(format: "location = %@", MKCircle(center: CLLocationCoordinate2D(latitude: 40.74, longitude: -74), radius: 10000)).urlQueryItems)!
        let expect = convert(jsonDictionary: [
            "query" : [
                "location" : [
                    "$geoWithin" : [
                        "$centerSphere" : [
                            [-74, 40.74],
                            10/6378.1
                        ]
                    ]
                ]
            ]
        ])
        
        XCTAssertEqual(result.count, expect.count)
        if result.count == expect.count {
            let resultQuery = try! JSONSerialization.jsonObject(with: result["query"]!.data(using: .utf8)!) as! [String : [String : [String : [Any]]]]
            let expectQuery = try! JSONSerialization.jsonObject(with: expect["query"]!.data(using: .utf8)!) as! [String : [String : [String : [Any]]]]
            
            let centerSphereResult = resultQuery["location"]!["$geoWithin"]!["$centerSphere"]!
            let centerSphereExpect = expectQuery["location"]!["$geoWithin"]!["$centerSphere"]!
            
            XCTAssertEqual(centerSphereResult.count, 2)
            XCTAssertEqual(centerSphereExpect.count, 2)
            
            if centerSphereResult.count == 2 && centerSphereExpect.count == 2 {
                let coordinatesResult = centerSphereResult[0] as! [Double]
                let coordinatesExpect = centerSphereExpect[0] as! [Double]
                
                XCTAssertEqual(coordinatesResult.count, 2)
                XCTAssertEqual(coordinatesExpect.count, 2)
                
                XCTAssertEqual(coordinatesResult, coordinatesExpect)
                
                XCTAssertEqual(centerSphereResult[1] as! Double, centerSphereExpect[1] as! Double, accuracy: 0.00001)
            }
        }
    }
    
    func testQueryGeoWithinPolygon() {
        var coordinates = [CLLocationCoordinate2D(latitude: 40.74, longitude: -74), CLLocationCoordinate2D(latitude: 50.74, longitude: -74), CLLocationCoordinate2D(latitude: 40.74, longitude: -64)]
        let result = convert(urlQueryItems: Query(format: "location = %@", MKPolygon(coordinates: &coordinates, count: 3)).urlQueryItems)!
        let expect = convert(jsonDictionary: [
            "query" : [
                "location" : [
                    "$geoWithin" : [
                        "$geometry" : [
                            "type" : "Polygon",
                            "coordinates" : [
                                [-74, 40.74],
                                [-74, 50.74],
                                [-64, 40.74]
                            ]
                        ]
                    ]
                ]
            ]
        ])
        
        XCTAssertEqual(result.count, expect.count)
        if result.count == expect.count {
            let result = try! JSONSerialization.jsonObject(with: result["query"]!.data(using: .utf8)!) as? [String : [String : [String : [String : AnyObject]]]]
            let expect = try! JSONSerialization.jsonObject(with: expect["query"]!.data(using: .utf8)!) as? [String : [String : [String : [String : AnyObject]]]]
            
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
                    for (index, _) in coordinatesResult.enumerated() {
                        XCTAssertEqual(coordinatesResult[index].count, coordinatesExpect[index].count)
                    }
                }
            }
        }
    }
    
    func testSortAscending() {
        XCTAssertEqual(encodeQuery(Query(sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])), "sort=\(encodeURL(["name" : 1]))")
    }
    
    func testSortDescending() {
        XCTAssertEqual(encodeQuery(Query(sortDescriptors: [NSSortDescriptor(key: "name", ascending: false)])), "sort=\(encodeURL(["name" : -1]))")
    }
    
    func testSkip() {
        XCTAssertEqual(encodeQuery(Query { $0.skip = 100 }), "skip=100")
    }
    
    func testLimit() {
        XCTAssertEqual(encodeQuery(Query { $0.limit = 100 }), "limit=100")
    }
    
    func testSkipAndLimit() {
        XCTAssertEqual(encodeQuery(Query { $0.skip = 100; $0.limit = 300 }), "skip=100&limit=300")
    }
    
    func testPredicateSortSkipAndLimit() {
        let result = encodeQuery(Query { $0.predicate = NSPredicate(format: "lastName == %@", "Barros"); $0.sortDescriptors = [NSSortDescriptor(key: "age", ascending: false)]; $0.skip = 2; $0.limit = 5 })
        let expected = "query=\(encodeURL(["lastName" : "Barros"]))&sort=\(encodeURL(["age" : -1]))&skip=2&limit=5"
        XCTAssertEqual(result, expected)
    }
    
    func testPredicateBetween() {
        let result = encodeQuery(Query(format: "expenses BETWEEN %@", [200, 400]))
        let json = [
            "$and" : [
                ["expenses" : ["$gte" : 200]],
                ["expenses" : ["$lte" : 400]]
            ]
        ]
        let expected = "query=\(encodeURL(json))"
        XCTAssertEqual(result, expected)
    }
    
    func testPredicateContains() {
        let result = encodeQuery(Query(format: "name CONTAINS[c] %@", "f"))
        let json = [
            "name" : [
                "$regex" : ".*f.*"
            ]
        ]
        let expected = "query=\(encodeURL(json))"
        XCTAssertEqual(result, expected)
    }
    
    func testPredicateEndsWith() {
        let result = encodeQuery(Query(format: "name ENDSWITH %@", "m"))
        let json = [
            "name" : [
                "$regex" : ".*m"
            ]
        ]
        let expected = "query=\(encodeURL(json))"
        XCTAssertEqual(result, expected)
    }
    
    func testPredicateLike() {
        let result = encodeQuery(Query(format: "name LIKE %@", "*m*"))
        let json = [
            "name" : [
                "$regex" : "/(*m*)/"
            ]
        ]
        let expected = "query=\(encodeURL(json))"
        XCTAssertEqual(result, expected)
    }
    
    func testPredicateCount() {
        var result = encodeQuery(Query(format: "names.@count == %@", 2))
        let json = [
            "names" : [
                "$size" : 2
            ]
        ]
        let expected = "query=\(encodeURL(json))"
        XCTAssertEqual(result, expected)
        
        result = encodeQuery(Query(format: "%@ = names.@count", 2))
        XCTAssertEqual(result, expected)
    }
    
    func testPredicateDate() {
        let date = Date()
        let result = encodeQuery(Query(format: "date == %@", date))
        let json = [
            "date" : date.timeIntervalSince1970
        ]
        let expected = "query=\(encodeURL(json))"
        XCTAssertEqual(result, expected)
    }
    
    func testPredicateNil() {
        let result = encodeQuery(Query(format: "date == %@", NSNull()))
        let json = [
            "date" : NSNull()
        ]
        let expected = "query=\(encodeURL(json))"
        XCTAssertEqual(result, expected)
    }
    
    func testPredicatePlusSign() {
        let result = encodeQuery(Query(format: "language == %@", "C++"))
        let json = [
            "language" : "C++"
        ]
        let expected = "query=\(encodeURL(json))"
        XCTAssertEqual(result, expected)
    }
    
    func testArrayContains() {
        let cache = RealmCache<Book>(persistenceId: "_kid_", schemaVersion: 0)
        let predicate = cache.translate(predicate: NSPredicate(format: "authorNames contains %@", "Victor"))
        XCTAssertEqual(predicate, NSPredicate(format: "SUBQUERY(authorNames, $item, $item.value == %@).@count > 0", "Victor"))
    }
    
    func testArrayIndex() {
        let cache = RealmCache<Book>(persistenceId: "_kid_", schemaVersion: 0)
        let predicate = cache.translate(predicate: NSPredicate(format: "authorNames[0] == %@", "Victor"))
        XCTAssertEqual(predicate, NSPredicate(format: "authorNames[0].value == %@", "Victor"))
    }
    
    func testArrayFirst() {
        let cache = RealmCache<Book>(persistenceId: "_kid_", schemaVersion: 0)
        let predicate = cache.translate(predicate: NSPredicate(format: "authorNames[first] == %@", "Victor"))
        XCTAssertEqual(predicate, NSPredicate(format: "authorNames[first].value == %@", "Victor"))
    }
    
    func testArrayLast() {
        let cache = RealmCache<Book>(persistenceId: "_kid_", schemaVersion: 0)
        let predicate = cache.translate(predicate: NSPredicate(format: "authorNames[last] == %@", "Victor"))
        XCTAssertEqual(predicate, NSPredicate(format: "authorNames[last].value == %@", "Victor"))
    }
    
    func testArraySize() {
        let cache = RealmCache<Book>(persistenceId: "_kid_", schemaVersion: 0)
        let predicate = cache.translate(predicate: NSPredicate(format: "authorNames[size] == 2"))
        XCTAssertEqual(predicate, NSPredicate(format: "authorNames[size] == 2"))
    }
    
    func testArraySubquery() {
        let cache = RealmCache<Book>(persistenceId: "_kid_", schemaVersion: 0)
        let predicate = cache.translate(predicate: NSPredicate(format: "subquery(authorNames, $authorNames, $authorNames like[c] %@).$count > 0", "Vic*"))
        XCTAssertEqual(predicate, NSPredicate(format: "subquery(authorNames, $authorNames, $authorNames.value like[c] %@).$count > 0", "Vic*"))
    }
    
    func testAscending() {
        let query = Query()
        query.ascending("name")
        let queryItems = query.urlQueryItems
        
        XCTAssertNotNil(queryItems)
        XCTAssertEqual(queryItems?.count, 1)
        XCTAssertEqual(queryItems?.filter { $0.name == "sort" }.first?.value, "{\"name\":1}")
    }
    
    func testDescending() {
        let query = Query()
        query.descending("name")
        let queryItems = query.urlQueryItems
        
        XCTAssertNotNil(queryItems)
        XCTAssertEqual(queryItems?.count, 1)
        XCTAssertEqual(queryItems?.filter { $0.name == "sort" }.first?.value, "{\"name\":-1}")
    }
    
    func testDeserialize() {
        XCTAssertNil(Query(JSON: [:]))
    }
    
    func testPredicateDeserialize() {
        XCTAssertNil(NSPredicate(JSON: [:]))
    }
    
    func testGeoPointConvertionToCLLocationCoordinate2D() {
        let geopoint = GeoPoint(latitude: 40.74, longitude: -74.56)
        let locationCoordinate2D = CLLocationCoordinate2D(geoPoint: geopoint)
        XCTAssertEqual(geopoint.latitude, locationCoordinate2D.latitude)
        XCTAssertEqual(geopoint.longitude, locationCoordinate2D.longitude)
    }
    
    func testCLLocationCoordinate2DConvertionToGeoPoint() {
        let locationCoordinate2D = CLLocationCoordinate2D(latitude: 40.74, longitude: -74.56)
        let geopoint = GeoPoint(coordinate: locationCoordinate2D)
        XCTAssertEqual(geopoint.latitude, locationCoordinate2D.latitude)
        XCTAssertEqual(geopoint.longitude, locationCoordinate2D.longitude)
    }
    
    func testMKPolyline() {
        let locationCoordinate2D = CLLocationCoordinate2D(latitude: 40.74, longitude: -74.56)
        let locationCoordinate2DArray = [locationCoordinate2D]
        let polyline = MKPolyline(coordinates: locationCoordinate2DArray, count: 1)
        let query = Query(format: "location == %@", polyline)
        guard let result = query.predicate?.mongoDBQuery else {
            XCTAssertNotNil(query.predicate?.mongoDBQuery)
            return
        }
        
        XCTAssertEqual(result.count, 1)
        
        guard let location = result["location"] as? [String : Any] else {
            XCTAssertNotNil(result["location"] as? [String : Any])
            return
        }
        
        XCTAssertEqual(location.count, 1)
        guard let geoWithin = location["$geoWithin"] else {
            XCTAssertNotNil(location["$geoWithin"])
            return
        }
        XCTAssertEqual("\(geoWithin)", "nil")
    }
    
    func testInvalidGeoPointParse() {
        XCTAssertNil(GeoPointTransform().transformFromJSON([-74.56]))
        XCTAssertNil(GeoPointTransform().transformFromJSON([]))
        XCTAssertNil(GeoPointTransform().transformFromJSON([-74.56, 40.74, 5.22]))
    }
    
}
