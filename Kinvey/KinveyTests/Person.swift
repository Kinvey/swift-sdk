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
import Realm

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
    
    override func propertyMapping(_ map: Kinvey.Map) {
        super.propertyMapping(map)
        
        personId <- ("personId", map[Entity.EntityCodingKeys.entityId])
        name <- ("name", map["name"])
        age <- ("age", map["age"])
        address <- ("address", map["address"], AddressTransform())
        geolocation <- ("geolocation", map["geolocation"])
    }
    
}

class PersonCodable: Entity, Codable {
    
    @objc
    dynamic var personId: String?
    
    @objc
    dynamic var name: String?
    
    @objc
    dynamic var age: Int = 0
    
    @objc
    dynamic var geolocation: GeoPoint?
    
    @objc
    dynamic var address: AddressCodable?
    
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
    
    enum CodingKeys: String, CodingKey {
        
        case personId = "_id"
        case name
        case age
        case address
        case geolocation
        
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        personId = try container.decodeIfPresent(String.self, forKey: .personId)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        age = try container.decode(Int.self, forKey: .age)
        address = try container.decodeIfPresent(AddressCodable.self, forKey: .address)
        geolocation = try container.decodeIfPresent(GeoPoint.self, forKey: .geolocation)
    }
    
    required init() {
        super.init()
    }
    
    @available(swift, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    required init?(map: Map) {
        super.init(map: map)
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = try encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(personId, forKey: .personId)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(age, forKey: .age)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(geolocation, forKey: .geolocation)
        
        try super.encode(to: encoder)
    }
    
}

class PersonCustomParser: Entity {
    
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
    
    override class func decode<T>(from dictionary: [String : Any]) throws -> T where T: JSONDecodable {
        let person = PersonCustomParser()
        person.entityId = dictionary["_id"] as? String
        person.personId = person.entityId
        person.name = dictionary["name"] as? String
        if let age = dictionary["age"] as? Int {
            person.age = age
        }
        return person as! T
    }
    
}

class PersonWithDifferentClassName: Entity {
    
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
    
    override func propertyMapping(_ map: Kinvey.Map) {
        super.propertyMapping(map)
        
        personId <- ("personId", map[Entity.EntityCodingKeys.entityId])
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

class AddressCodable: Entity, Codable {
    
    @objc
    dynamic var city: String?
    
    enum CodingKeys: String, CodingKey {
        
        case city
        
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = try encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(city, forKey: .city)
    }
    
}
