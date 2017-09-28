//
//  Person.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-05.
//  Copyright © 2016 Kinvey. All rights reserved.
//

@testable import Kinvey
import ObjectMapper
import CoreLocation

protocol PersonDelegate {
}

@objc
protocol PersonObjCDelegate {
}

struct PersonStruct {
    var test: String
}

enum PersonEnum {
    case test
}

@objc
enum PersonObjCEnum: Int {
    case test
}

class Person: Entity {
    
    @objc
    dynamic var personId: String?
    
    @objc
    dynamic var name: String?
    
    @objc
    dynamic var age: Int = 0
    
    @objc
    dynamic var geolocation: GeoPoint?
    
    @objc
    dynamic var address: Address?
    
    //testing properties that must be ignored
    var personDelegate: PersonDelegate?
    var personObjCDelegate: PersonObjCDelegate?
    weak var weakPersonObjCDelegate: PersonObjCDelegate?
    var personStruct: PersonStruct?
    var personEnum: PersonEnum?
    var personObjCEnum: PersonObjCEnum?
    
    override class func collectionName() -> String {
        return "Person"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        personId <- ("personId", map[PersistableIdKey])
        name <- ("name", map["name"])
        age <- ("age", map["age"])
        address <- ("address", map["address"], AddressTransform())
        geolocation <- ("geolocation", map["geolocation"])
    }
    
}

extension Person {
    convenience init(_ block: (Person) -> Void) {
        self.init()
        block(self)
    }
}

class AddressTransform: TransformType {
    
    typealias Object = Address
    typealias JSON = [String : Any]
    
    func transformFromJSON(_ value: Any?) -> Object? {
        var jsonDict: [String : AnyObject]? = nil
        if let value = value as? String,
            let data = value.data(using: String.Encoding.utf8),
            let json = try? JSONSerialization.jsonObject(with: data)
        {
            jsonDict = json as? [String : AnyObject]
        } else {
            jsonDict = value as? [String : AnyObject]
        }
        if let jsonDict = jsonDict {
            let address = Address()
            address.city = jsonDict["city"] as? String
            return address
        }
        return nil
    }
    
    func transformToJSON(_ value: Object?) -> JSON? {
        if let value = value {
            var json = [String : Any]()
            if let city = value.city {
                json["city"] = city
            }
            return json
        }
        return nil
    }
    
}

class Address: Entity {
    
    @objc
    dynamic var city: String?
    
}
