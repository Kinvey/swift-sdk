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

// swiftlint:disable class_delegate_protocol
protocol PersonDelegate {
}
// swiftlint:enable class_delegate_protocol

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
    dynamic var personId: String? {
        didSet {
            entityId = personId
        }
    }
    
    @objc
    dynamic var name: String?
    
    @objc
    dynamic var age: Int = 0
    
    @objc
    dynamic var geolocation: GeoPoint?
    
    @objc
    dynamic var address: Address?
    
    //testing properties that must be ignored
    // swiftlint:disable weak_delegate
    var personDelegate: PersonDelegate?
    var personObjCDelegate: PersonObjCDelegate?
    // swiftlint:enable weak_delegate
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
        address <- ("address", map["address"], AddressTransform.shared)
        geolocation <- ("geolocation", map[GeoPoint.CodingKey])
    }
    
}

class Reference: Object, Codable {
    
    @objc
    dynamic var entityId: String?
    
    override class func primaryKey() -> String {
        return NSExpression(forKeyPath: \Reference.entityId).keyPath
    }
    
}

extension Reference {
    
    convenience init(_ entityId: String) {
        self.init()
        self.entityId = entityId
    }
    
}

class EntityWithRefenceCodable: Entity, Codable {
    
    override class func collectionName() -> String {
        return "EntityWithRefence"
    }
    
    @objc
    dynamic var reference: Reference?
    
    let references = List<Reference>()
    
    enum CodingKeys: String, CodingKey {
        case reference
        case references
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reference = try container.decodeIfPresent(Reference.self, forKey: .reference)
        if let references = try container.decodeIfPresent(List<Reference>.self, forKey: .references) {
            self.references.removeAll()
            self.references.append(objectsIn: references)
        }
    }
    
    required init() {
        super.init()
    }
    
    @available(swift, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    required init?(map: Map) {
        super.init(map: map)
    }

    override func encode(to encoder: Encoder) throws {
        var container = try encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(reference, forKey: .reference)
        try container.encodeIfPresent(references, forKey: .references)
        
        try super.encode(to: encoder)
    }
    
}

class PersonCodableCascadeDeletable: PersonCodable, CascadeDeletable {
    
    func cascadeDelete(executor: CascadeDeleteExecutor) throws {
        try executor.cascadeDelete(geolocation)
        try executor.cascadeDelete(reference)
        try executor.cascadeDelete(references)
        try executor.cascadeDelete(address)
        try executor.cascadeDelete(addresses)
        try executor.cascadeDelete(stringValues)
        try executor.cascadeDelete(intValues)
        try executor.cascadeDelete(floatValues)
        try executor.cascadeDelete(doubleValues)
        try executor.cascadeDelete(boolValues)
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
    dynamic var date: Date?
    
    @objc
    dynamic var geolocation: GeoPoint?
    
    @objc
    dynamic var reference: Reference?
    
    let references = List<Reference>()
    
    @objc
    dynamic var address: AddressCodable?
    
    let addresses = List<AddressCodable>()
    let stringValues = List<StringValue>()
    let intValues = List<IntValue>()
    let floatValues = List<FloatValue>()
    let doubleValues = List<DoubleValue>()
    let boolValues = List<BoolValue>()
    
    //testing properties that must be ignored
    // swiftlint:disable weak_delegate
    var personDelegate: PersonDelegate?
    var personObjCDelegate: PersonObjCDelegate?
    // swiftlint:enable weak_delegate
    weak var weakPersonObjCDelegate: PersonObjCDelegate?
    var personStruct: PersonStruct?
    var personEnum: PersonEnum?
    var personObjCEnum: PersonObjCEnum?
    
    override class func collectionName() -> String {
        return "Person"
    }
    
    override class func translate(property: String) -> String? {
        guard let codingKey = CodingKeys(rawValue: property) else {
            return nil
        }
        switch codingKey {
        case .personId:
            return NSExpression(forKeyPath: \PersonCodable.personId).keyPath
        default:
            return nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        
        case personId = "_id"
        case name
        case age
        case date
        case address
        case addresses
        case geolocation
        case reference
        case references
        case stringValues
        case intValues
        case floatValues
        case doubleValues
        case boolValues
        
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        personId = try container.decodeIfPresent(String.self, forKey: .personId)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        age = try container.decode(Int.self, forKey: .age)
        date = try container.decodeIfPresent(Date.self, forKey: .date)
        address = try container.decodeIfPresent(AddressCodable.self, forKey: .address)
        if let addresses = try container.decodeIfPresent(List<AddressCodable>.self, forKey: .addresses) {
            self.addresses.removeAll()
            self.addresses.append(objectsIn: addresses)
        }
        if let stringValues = try container.decodeIfPresent(List<StringValue>.self, forKey: .stringValues) {
            self.stringValues.removeAll()
            self.stringValues.append(objectsIn: stringValues)
        }
        if let intValues = try container.decodeIfPresent(List<IntValue>.self, forKey: .intValues) {
            self.intValues.removeAll()
            self.intValues.append(objectsIn: intValues)
        }
        if let floatValues = try container.decodeIfPresent(List<FloatValue>.self, forKey: .floatValues) {
            self.floatValues.removeAll()
            self.floatValues.append(objectsIn: floatValues)
        }
        if let doubleValues = try container.decodeIfPresent(List<DoubleValue>.self, forKey: .doubleValues) {
            self.doubleValues.removeAll()
            self.doubleValues.append(objectsIn: doubleValues)
        }
        if let boolValues = try container.decodeIfPresent(List<BoolValue>.self, forKey: .boolValues) {
            self.boolValues.removeAll()
            self.boolValues.append(objectsIn: boolValues)
        }
        geolocation = try container.decodeIfPresent(GeoPoint.self, forKey: .geolocation)
        reference = try container.decodeIfPresent(Reference.self, forKey: .reference)
        if let references = try container.decodeIfPresent(List<Reference>.self, forKey: .references) {
            self.references.removeAll()
            self.references.append(objectsIn: references)
        }
    }
    
    required init() {
        super.init()
    }
    
    @available(swift, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    required init?(map: Map) {
        super.init(map: map)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(personId, forKey: .personId)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(age, forKey: .age)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(addresses, forKey: .addresses)
        try container.encodeIfPresent(stringValues, forKey: .stringValues)
        try container.encodeIfPresent(intValues, forKey: .intValues)
        try container.encodeIfPresent(floatValues, forKey: .floatValues)
        try container.encodeIfPresent(doubleValues, forKey: .doubleValues)
        try container.encodeIfPresent(boolValues, forKey: .boolValues)
        try container.encodeIfPresent(geolocation, forKey: .geolocation)
        try container.encodeIfPresent(reference, forKey: .reference)
        
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
    // swiftlint:disable weak_delegate
    var personDelegate: PersonDelegate?
    var personObjCDelegate: PersonObjCDelegate?
    // swiftlint:enable weak_delegate
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
    // swiftlint:disable weak_delegate
    var personDelegate: PersonDelegate?
    var personObjCDelegate: PersonObjCDelegate?
    // swiftlint:enable weak_delegate
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
        address <- ("address", map["address"], AddressTransform.shared)
        geolocation <- ("geolocation", map["geolocation"])
    }
    
}

extension Person {
    convenience init(_ block: (Person) -> Void) {
        self.init()
        block(self)
    }
}

class AddressTransform: Kinvey.TransformType {
    
    static let shared = AddressTransform()
    
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

class AddressCodable: Object, Codable {
    
    @objc
    dynamic var city: String?
    
}

class Issue311_MyModel: Kinvey.Entity {
    
    @objc dynamic var someSimpleProperty: String?
    @objc dynamic var someComplexProperty: Issue311_ComplexType?
    
    override static func collectionName() -> String {
        return "MyModel"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        self.someSimpleProperty <- ("someSimpleProperty", map["someSimpleProperty"])
        self.someComplexProperty <- ("someComplexProperty", map["someComplexProperty"])
    }
}

final class Issue311_ComplexType: Kinvey.Object, Kinvey.Mappable {
    
    @objc dynamic var someSimpleProperty: String?
    let someListProperty = Kinvey.List<StringValue>()
    
    convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        self.someSimpleProperty <- ("someSimpleProperty", map["someSimpleProperty"])
        self.someListProperty <- ("someListProperty", map["someListProperty"])
    }
}

class Issue311_MyModelCodable: Kinvey.Entity, Codable {
    
    @objc dynamic var someSimpleProperty: String?
    @objc dynamic var someComplexProperty: Issue311_ComplexTypeCodable?
    
    override static func collectionName() -> String {
        return "MyModel"
    }
    
    enum CodingKeys: String, CodingKey {

        case someSimpleProperty
        case someComplexProperty

    }

    required init() {
        super.init()
    }

    @available(*, deprecated)
    required init?(map: Map) {
        super.init(map: map)
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        someSimpleProperty = try container.decodeIfPresent(String.self, forKey: .someSimpleProperty)
        someComplexProperty = try container.decodeIfPresent(Issue311_ComplexTypeCodable.self, forKey: .someComplexProperty)
    }

    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)

        var container = try encoder.container(keyedBy: CodingKeys.self)
        try container.encode(someSimpleProperty, forKey: .someSimpleProperty)
        try container.encode(someComplexProperty, forKey: .someComplexProperty)
    }
}

final class Issue311_ComplexTypeCodable: Kinvey.Object, Codable {
    
    @objc dynamic var someSimpleProperty: String?
    let someListProperty = Kinvey.List<StringValue>()
    
    enum CodingKeys: String, CodingKey {
        
        case someSimpleProperty
        case someListProperty
        
    }
    
    convenience init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        someSimpleProperty = try container.decodeIfPresent(String.self, forKey: .someSimpleProperty)
        if let someListProperty = try container.decodeIfPresent(Kinvey.List<StringValue>.self, forKey: .someListProperty) {
            self.someListProperty.removeAll()
            self.someListProperty.append(objectsIn: someListProperty)
        }
    }
    
}
