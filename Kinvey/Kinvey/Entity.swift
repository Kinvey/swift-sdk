//
//  Entity.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-06-14.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

public typealias List<T: RealmSwift.Object> = RealmSwift.List<T>
public typealias Object = RealmSwift.Object

internal func StringFromClass(cls: AnyClass) -> String {
    var className = NSStringFromClass(cls)
    let regex = try! NSRegularExpression(pattern: "(?:RLM.+_(.+))|(?:RLM:\\S* (.*))") // regex to catch Realm classnames like `RLMStandalone_`, `RLMUnmanaged_`, `RLMAccessor_` or `RLM:Unmanaged `
    var nMatches = regex.numberOfMatches(in: className, range: NSRange(location: 0, length: className.count))
    while nMatches > 0 {
        let classObj: AnyClass! = NSClassFromString(className)!
        let superClass: AnyClass! = class_getSuperclass(classObj)
        className = NSStringFromClass(superClass)
        nMatches = regex.numberOfMatches(in: className, range: NSRange(location: 0, length: className.count))
    }
    return className
}

public enum ObjectChange<T: Entity> {
    
    case change(T)
    case deleted
    case error(Swift.Error)
    
}

/// Base class for entity classes that are mapped to a collection in Kinvey.
open class Entity: Object, Persistable {
    
    /// Property names for the `Entity` class
    @available(*, deprecated: 3.17.0, message: "Please use Entity.CodingKeys instead")
    public struct Key {
        
        /// Key to map the `_id` column in your Persistable implementation class.
        @available(*, deprecated: 3.17.0, message: "Please use Entity.CodingKeys.entityId instead")
        public static let entityId = "_id"
        
        /// Key to map the `_acl` column in your Persistable implementation class.
        @available(*, deprecated: 3.17.0, message: "Please use Entity.CodingKeys.acl instead")
        public static let acl = "_acl"
        
        /// Key to map the `_kmd` column in your Persistable implementation class.
        @available(*, deprecated: 3.17.0, message: "Please use Entity.CodingKeys.metadata instead")
        public static let metadata = "_kmd"
        
    }
    
    /// This function can be used to validate JSON prior to mapping. Return nil to cancel mapping at this point
    @available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    public required init?(map: Map) {
        super.init()
    }
    
    /// Override this method and return the name of the collection for Kinvey.
    open class func collectionName() throws -> String {
        throw Error.invalidOperation(description: "Method \(#function) must be overridden")
    }
    
    /// The `_id` property mapped in the Kinvey backend.
    @objc
    public dynamic var entityId: String?
    
    /// The `_kmd` property mapped in the Kinvey backend.
    @objc
    public dynamic var metadata: Metadata?
    
    /// The `_acl` property mapped in the Kinvey backend.
    @objc
    public dynamic var acl: Acl?
    
    internal var realmConfiguration: Realm.Configuration?
    internal var reference: ThreadSafeReference<Entity>?
    
    /// Default Constructor.
    public required init() {
        super.init()
    }

    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    public required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }

    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    public required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: EntityCodingKeys.self)
        entityId = try container.decodeIfPresent(String.self, forKey: .entityId)
        metadata = try container.decodeIfPresent(Metadata.self, forKey: .metadata)
        acl = try container.decodeIfPresent(Acl.self, forKey: .acl)
    }
    
    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EntityCodingKeys.self)
        try container.encodeIfPresent(entityId, forKey: .entityId)
        try container.encodeIfPresent(metadata, forKey: .metadata)
        try container.encodeIfPresent(acl, forKey: .acl)
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    open override class func primaryKey() -> String? {
        return try? entityIdProperty()
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    open override class func ignoredProperties() -> [String] {
        var properties = [String]()
        for (propertyName, (type, subType)) in ObjCRuntime.properties(forClass: self) {
            if let type = type,
                let typeClass = NSClassFromString(type),
                !(ObjCRuntime.type(typeClass, isSubtypeOf: NSDate.self) ||
                ObjCRuntime.type(typeClass, isSubtypeOf: NSData.self) ||
                ObjCRuntime.type(typeClass, isSubtypeOf: NSString.self) ||
                ObjCRuntime.type(typeClass, isSubtypeOf: RLMObjectBase.self) ||
                ObjCRuntime.type(typeClass, isSubtypeOf: RLMOptionalBase.self) ||
                ObjCRuntime.type(typeClass, isSubtypeOf: RLMListBase.self) ||
                ObjCRuntime.type(typeClass, isSubtypeOf: RLMCollection.self))
            {
                properties.append(propertyName)
            } else if let subType = subType,
                let _ = NSProtocolFromString(subType)
            {
                properties.append(propertyName)
            }
        }
        return properties
    }
    
    /// Override this method to tell how to map your own objects.
    @available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    open func propertyMapping(_ map: Map) {
        entityId <- ("entityId", map[EntityCodingKeys.entityId])
        metadata <- ("metadata", map[EntityCodingKeys.metadata])
        acl <- ("acl", map[EntityCodingKeys.acl])
    }
    
    open class func decodeArray<T>(from data: Data) throws -> [T] where T : JSONDecodable {
        return try decodeArrayJSONDecodable(from: data)
    }
    
    open class func decode<T>(from data: Data) throws -> T where T: JSONDecodable {
        return try decodeJSONDecodable(from: data)
    }
    
    open class func decode<T>(from dictionary: [String : Any]) throws -> T where T : JSONDecodable {
        return try decodeJSONDecodable(from: dictionary)
    }
    
    open func refresh(from dictionary: [String : Any]) throws {
        var _self = self
        try _self.refreshJSONDecodable(from: dictionary)
    }
    
    open func encode() throws -> [String : Any] {
        return try encodeJSONEncodable()
    }
    
}

@available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
extension Entity: Mappable {
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    @available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    public func mapping(map: Map) {
        let className = StringFromClass(cls: type(of: self))
        if kinveyProperyMapping[className] == nil {
            currentMappingClass = className
            mappingOperationQueue.addOperation {
                if kinveyProperyMapping[className] == nil {
                    kinveyProperyMapping[className] = PropertyMap()
                }
                self.propertyMapping(map)
            }
            mappingOperationQueue.waitUntilAllOperationsAreFinished()
            currentMappingClass = nil
        } else {
            self.propertyMapping(map)
        }
    }
    
}

extension Entity {
    
    /// Property names for the `Entity` class
    public enum EntityCodingKeys: String, CodingKey {
        
        /// Key to map the `_id` column in your Persistable implementation class.
        case entityId = "_id"
        
        /// Key to map the `_acl` column in your Persistable implementation class.
        case acl = "_acl"
        
        /// Key to map the `_kmd` column in your Persistable implementation class.
        case metadata = "_kmd"
        
    }
    
    public subscript<Key: RawRepresentable>(key: Key) -> Any? where Key.RawValue == String {
        return self[key.rawValue]
    }
    
}

extension Entity /* Hashable */ {
    
    open override var hashValue: Int {
        return entityId?.hashValue ?? 0
    }
    
    // Obj-C
    open override var hash: Int {
        return hashValue
    }
    
}

extension Entity /* Equatable */ {
    
    open static func == (lhs: Entity, rhs: Entity) -> Bool {
        return lhs.entityId == rhs.entityId
    }
    
    // Obj-C
    open override func isEqual(_ object: Any?) -> Bool {
        guard let otherEntity = object as? Entity else {
            return false
        }
        return self == otherEntity
    }
    
}

let mappingOperationQueue: OperationQueue = {
    let operationQueue = OperationQueue()
    operationQueue.name = "Kinvey Property Mapping"
    operationQueue.maxConcurrentOperationCount = 1
    return operationQueue
}()
var kinveyProperyMapping = [String : PropertyMap]()
var currentMappingClass: String?

/// Wrapper type for string values that needs to be stored locally in the device
open class StringValue: Object, ExpressibleByStringLiteral {
    
    /// String value for the wrapper
    @objc
    public dynamic var value = ""
    
    /// Constructor for the `ExpressibleByUnicodeScalarLiteral` protocol
    public convenience required init(unicodeScalarLiteral value: String) {
        self.init()
        self.value = value
    }
    
    /// Constructor for the `ExpressibleByExtendedGraphemeClusterLiteral` protocol
    public convenience required init(extendedGraphemeClusterLiteral value: String) {
        self.init()
        self.value = value
    }
    
    /// Constructor for the `ExpressibleByStringLiteral` protocol
    public convenience required init(stringLiteral value: String) {
        self.init()
        self.value = value
    }
    
    /// Constructor that takes a string value to wrap
    public convenience init(_ value: String) {
        self.init()
        self.value = value
    }
    
}

/**
 Wrapper type for integer values that needs to be stored locally in the device
 */
open class IntValue: Object, ExpressibleByIntegerLiteral {
    
    /// Integer value for the wrapper
    @objc
    public dynamic var value = 0
    
    /// Constructor for the `ExpressibleByIntegerLiteral` protocol
    public convenience required init(integerLiteral value: Int) {
        self.init()
        self.value = value
    }
    
    /// Constructor that takes an integer value to wrap
    public convenience init(_ value: Int) {
        self.init()
        self.value = value
    }
    
}

/**
 Wrapper type for float values that needs to be stored locally in the device
 */
open class FloatValue: Object, ExpressibleByFloatLiteral {
    
    /// Float value for the wrapper
    @objc
    public dynamic var value = Float(0)
    
    /// Constructor for the `ExpressibleByFloatLiteral` protocol
    public convenience required init(floatLiteral value: Float) {
        self.init()
        self.value = value
    }
    
    /// Constructor that takes a float value to wrap
    public convenience init(_ value: Float) {
        self.init()
        self.value = value
    }
    
}

/**
 Wrapper type for double values that needs to be stored locally in the device
 */
open class DoubleValue: Object, ExpressibleByFloatLiteral {
    
    /// Double value for the wrapper
    @objc
    public dynamic var value = 0.0
    
    /// Constructor for the `ExpressibleByFloatLiteral` protocol
    public convenience required init(floatLiteral value: Double) {
        self.init()
        self.value = value
    }
    
    /// Constructor that takes a double value to wrap
    public convenience init(_ value: Double) {
        self.init()
        self.value = value
    }
    
}

/**
 Wrapper type for boolean values that needs to be stored locally in the device
 */
open class BoolValue: Object, ExpressibleByBooleanLiteral {
    
    /// Boolean value for the wrapper
    @objc
    public dynamic var value = false
    
    /// Constructor for the `ExpressibleByBooleanLiteral` protocol
    public convenience required init(booleanLiteral value: Bool) {
        self.init()
        self.value = value
    }
    
    /// Constructor that takes a boolean value to wrap
    public convenience init(_ value: Bool) {
        self.init()
        self.value = value
    }
    
}
