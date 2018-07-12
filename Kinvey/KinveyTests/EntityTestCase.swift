//
//  EntityTestCase.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-05-17.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey
import Nimble

class EntityTestCase: XCTestCase {
    
    func testCollectionName() {
        expect {
            try Entity.collectionName()
        }.to(throwError())
    }
    
    func testBoolValue() {
        let value = true
        XCTAssertEqual(BoolValue(booleanLiteral: true).value, value)
        XCTAssertEqual(BoolValue(true).value, value)
    }
    
    func testDoubleValue() {
        let value: Double = 3.14159
        XCTAssertEqual(DoubleValue(floatLiteral: value).value, value)
        XCTAssertEqual(DoubleValue(value).value, value)
    }
    
    func testFloatValue() {
        let value: Float = 3.14159
        XCTAssertEqual(FloatValue(floatLiteral: value).value, value)
        XCTAssertEqual(FloatValue(value).value, value)
    }
    
    func testIntValue() {
        let value = 314159
        XCTAssertEqual(IntValue(integerLiteral: value).value, value)
        XCTAssertEqual(IntValue(value).value, value)
    }
    
    func testStringValue() {
        let value = "314159"
        XCTAssertEqual(StringValue(unicodeScalarLiteral: value).value, value)
        XCTAssertEqual(StringValue(extendedGraphemeClusterLiteral: value).value, value)
        XCTAssertEqual(StringValue(stringLiteral: value).value, value)
        XCTAssertEqual(StringValue(value).value, value)
    }
    
    func testGeoPointValidationParse() {
        let latitude = 42.3133521
        let longitude = -71.1271963
        XCTAssertNotNil(GeoPoint(JSON: ["latitude" : latitude, "longitude" : longitude]))
        XCTAssertNil(GeoPoint(JSON: ["latitude" : latitude]))
        XCTAssertNil(GeoPoint(JSON: ["longitude" : longitude]))
    }
    
    func testGeoPointMapping() {
        var geoPoint = GeoPoint()
        let latitude = 42.3133521
        let longitude = -71.1271963
        geoPoint <- ("geoPoint", Map(mappingType: .fromJSON, JSON: ["location" : [longitude, latitude]])["location"])
        XCTAssertEqual(geoPoint.latitude, latitude)
        XCTAssertEqual(geoPoint.longitude, longitude)
    }
    
    func testGeoPointMappingForce() {
        var geoPoint: GeoPoint!
        let latitude = 42.3133521
        let longitude = -71.1271963
        geoPoint <- ("geoPoint", Map(mappingType: .fromJSON, JSON: ["location" : [longitude, latitude]])["location"])
        XCTAssertEqual(geoPoint.latitude, latitude)
        XCTAssertEqual(geoPoint.longitude, longitude)
    }
    
    func testGeoPointMappingOptional() {
        var geoPoint: GeoPoint?
        let latitude = 42.3133521
        let longitude = -71.1271963
        geoPoint <- ("geoPoint", Map(mappingType: .fromJSON, JSON: ["location" : [longitude, latitude]])["location"])
        XCTAssertEqual(geoPoint?.latitude, latitude)
        XCTAssertEqual(geoPoint?.longitude, longitude)
    }
    
    func testPropertyType() {
        var clazz: AnyClass? = ObjCRuntime.typeForPropertyName(Person.self, propertyName: "name")
        XCTAssertNotNil(clazz)
        if let clazz = clazz {
            let clazzName = NSStringFromClass(clazz)
            XCTAssertEqual(clazzName, "NSString")
        }
        
        clazz = ObjCRuntime.typeForPropertyName(Person.self, propertyName: "geolocation")
        XCTAssertNotNil(clazz)
        if let clazz = clazz {
            let clazzName = NSStringFromClass(clazz)
            XCTAssertEqual(clazzName, "Kinvey.GeoPoint")
        }
        
        clazz = ObjCRuntime.typeForPropertyName(Person.self, propertyName: "address")
        XCTAssertNotNil(clazz)
        if let clazz = clazz {
            let clazzName = NSStringFromClass(clazz)
            let testBundleName = type(of: self).description().components(separatedBy: ".").first!
            XCTAssertEqual(clazzName, "\(testBundleName).Address")
        }
        
        clazz = ObjCRuntime.typeForPropertyName(Person.self, propertyName: "age")
        XCTAssertNil(clazz)
    }
    
    func testEntityHashable() {
        let entityId = UUID().uuidString
        let entity1 = Person { $0.entityId = entityId }
        let entity2 = Person { $0.entityId = entityId }
        let entity3 = Person { $0.entityId = UUID().uuidString }
        XCTAssertEqual(entity1.hash, entity2.hash)
        XCTAssertEqual(entity1.hashValue, entity2.hashValue)
        XCTAssertNotEqual(entity1.hash, entity3.hash)
        XCTAssertNotEqual(entity2.hash, entity3.hash)
        XCTAssertNotEqual(entity1.hashValue, entity3.hashValue)
        XCTAssertNotEqual(entity2.hashValue, entity3.hashValue)
    }
    
    func testEntityEquatable() {
        let entityId = UUID().uuidString
        let entity1 = Person { $0.entityId = entityId }
        let entity2 = Person { $0.entityId = entityId }
        let entity3 = Person { $0.entityId = UUID().uuidString }
        let set = Set<Person>([entity1])
        XCTAssertEqual(entity1, entity2)
        XCTAssertNotEqual(entity1, entity3)
        XCTAssertNotEqual(entity2, entity3)
        XCTAssertTrue(entity1 == entity2)
        XCTAssertFalse(entity1 == entity3)
        XCTAssertFalse(entity2 == entity3)
        XCTAssertTrue(entity1.isEqual(entity2))
        XCTAssertFalse(entity1.isEqual(entity3))
        XCTAssertFalse(entity2.isEqual(entity3))
        XCTAssertTrue(set.contains(entity2))
        XCTAssertFalse(set.contains(entity3))
    }
    
}
