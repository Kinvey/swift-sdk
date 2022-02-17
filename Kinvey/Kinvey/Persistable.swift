//
//  Persistable.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation
import RealmSwift

public typealias KinveyOptional = RealmSwift.RealmOptional

infix operator <- : DefaultPrecedence

/// Protocol that turns a NSObject into a persistable class to be used in a `DataStore`.
public protocol Persistable: JSONCodable {
    
    /// Provides the collection name to be matched with the backend.
    static func collectionName() throws -> String
    
    /// Provides property translations for queries
    static func translate(property: String) throws -> String?
    
    /// Default Constructor.
    init()
    
}

extension Persistable where Self: Entity {
    
    public func observe(_ block: @escaping (ObjectChange<Self>) -> Void) -> AnyNotificationToken? {
        let completionHandler = { (objectChange: RealmSwift.ObjectChange<Self>) in
            switch objectChange {
            case .change(let propertyChanges):
                for propertyChange in propertyChanges.1 {
                    if let newValue = propertyChange.newValue, !(newValue is NSNull) {
                        self[propertyChange.name] = newValue
                    } else {
                        self[propertyChange.name] = nil
                    }
                }
                block(.change(self))
            case .deleted:
                block(.deleted)
            case .error(let error):
                block(.error(error))
            }
        }
        guard let realmConfiguration = realmConfiguration,
            let entityIdReference = entityIdReference,
            let realm = try? Realm(configuration: realmConfiguration),
            let entity = realm.object(ofType: Self.self, forPrimaryKey: entityIdReference)
        else {
            return nil
        }
        return AnyNotificationToken(entity.observe(completionHandler))
    }
    
}

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
internal func kinveyMappingType(left: String, right: String) {
    _kinveyMappingType(left: left, right: right)
}

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
internal func kinveyMappingType<Transform: TransformType>(left: String, right: String, transform: Transform) {
    _kinveyMappingType(left: left, right: right, transform: AnyTransform(transform))
}

@inline(__always)
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
fileprivate func _kinveyMappingType(left: String, right: String, transform: AnyTransform? = nil) {
    autoreleasepool {
        guard let className = currentMappingClass,
            var classMapping = kinveyProperyMapping[className],
            classMapping[left] == nil
        else {
            return
        }
        let block = {
            if let transform = transform {
                classMapping[left] = (right, transform)
            } else {
                classMapping[left] = (right, nil)
            }
            kinveyProperyMapping[className] = classMapping
        }
        if mappingOperationQueue == OperationQueue.current {
            block()
        } else {
            mappingOperationQueue.addOperation(block)
            mappingOperationQueue.waitUntilAllOperationsAreFinished()
        }
    }
}

internal let KinveyMappingTypeKey = "Kinvey Mapping Type"

struct PropertyMap: Sequence, IteratorProtocol, ExpressibleByDictionaryLiteral {
    
    typealias Key = String
    typealias Value = (String, AnyTransform?)
    typealias Element = (Key, Value)
    
    private var map = [Key : Value]()
    private var keys = [Key]()
    private var currentIndex = 0
    
    init(dictionaryLiteral elements: (Key, Value)...) {
        for (key, value) in elements {
            self[key] = value
        }
    }
    
    subscript(key: Key) -> Value? {
        get {
            return map[key]
        }
        set {
            map[key] = newValue
            if !keys.contains(key) {
                keys.append(key)
            }
        }
    }
    
    mutating func next() -> Element? {
        if keys.startIndex <= currentIndex && currentIndex < keys.endIndex {
            let key = keys[currentIndex]
            if let value = map[key] {
                currentIndex += 1
                return (key, value)
            }
        }
        return nil
    }
    
}

extension Persistable {
    
    static func propertyMappingReverse() throws -> [String : [String]] {
        var results = [String : [String]]()
        for (key, (value, _)) in propertyMapping() {
            var properties = results[value]
            if properties == nil {
                properties = [String]()
            }
            properties!.append(key)
            results[value] = properties
        }
        let entityIdMapped = results[Entity.EntityCodingKeys.entityId] != nil
        let metadataMapped = results[Entity.EntityCodingKeys.metadata] != nil
        if !(entityIdMapped && metadataMapped) {
            let isEntity = self is Entity.Type
            let hintMessage = isEntity ? "Please call super.propertyMapping() inside your propertyMapping() method." : "Please add properties in your Persistable model class to map the missing properties."
            guard entityIdMapped else {
                throw Error.invalidOperation(description: "Property \(Entity.EntityCodingKeys.entityId) (Entity.Key.entityId) is missing in the propertyMapping() method. \(hintMessage)")
            }
            guard metadataMapped else {
                throw Error.invalidOperation(description: "Property \(Entity.EntityCodingKeys.metadata) (Entity.Key.metadata) is missing in the propertyMapping() method. \(hintMessage)")
            }
        }
        return results
    }
    
    static func newInstance<T: Persistable>(type: T.Type) -> T {
        return type.init()
    }
    
    static func propertyMapping() -> PropertyMap {
        let className = StringFromClass(cls: self as! AnyClass)
        let obj: Any
        if let objType = self as? NSObject.Type {
            obj = objType.init()
        } else {
            obj = self.init()
        }
        if let obj = obj as? BaseMappable {
            let _ = obj.toJSON()
        }
        if let kinveyMappingClassType = kinveyProperyMapping[className] {
            return kinveyMappingClassType
        }
        return [:]
    }
    
    static func propertyMapping(_ propertyName: String) -> PropertyMap.Value? {
        return propertyMapping()[propertyName]
    }
    
    internal static func entityIdProperty() throws -> String {
        return try propertyMappingReverse()[Entity.EntityCodingKeys.entityId]!.last!
    }
    
    internal static func aclProperty() throws -> String? {
        return try propertyMappingReverse()[Entity.EntityCodingKeys.acl]?.last
    }
    
    internal static func metadataProperty() throws -> String? {
        return try propertyMappingReverse()[Entity.EntityCodingKeys.metadata]?.last
    }
    
}

extension Persistable where Self: NSObject {
    
    public subscript(key: String) -> Any? {
        get {
            return self.value(forKey: key)
        }
        set {
            self.setValue(newValue, forKey: key)
        }
    }
    
    internal var entityId: String? {
        get {
            guard let entityIdProperty = try? type(of: self).entityIdProperty() else {
                return nil
            }
            return self[entityIdProperty] as? String
        }
        set {
            guard let entityIdProperty = try? type(of: self).entityIdProperty() else {
                return
            }
            self[entityIdProperty] = newValue
        }
    }
    
    internal var acl: Acl? {
        get {
            if let aclKey = try? type(of: self).aclProperty() {
                return self[aclKey] as? Acl
            }
            return nil
        }
        set {
            if let aclKey = try? type(of: self).aclProperty() {
                self[aclKey] = newValue
            }
        }
    }
    
    internal var metadata: Metadata? {
        get {
            if let kmdKey = try? type(of: self).metadataProperty() {
                return self[kmdKey] as? Metadata
            }
            return nil
        }
        set {
            if let kmdKey = try? type(of: self).metadataProperty() {
                self[kmdKey] = newValue
            }
        }
    }
    
}

extension AnyRandomAccessCollection where Element: Persistable {
    
    public subscript(idx: Int) -> Element {
        return self[self.index(self.startIndex, offsetBy: idx)]
    }
    
}

extension Dictionary where Key == String {
    
    public subscript<Key: RawRepresentable>(key: Key) -> Value? where Key.RawValue == String {
        get {
            return self[key.rawValue]
        }
        set {
            self[key.rawValue] = newValue
        }
    }
    
}

let EntityIdTmpPrefix = "tmp_"

func isNew(entityId: String?) -> Bool {
    guard let entityId = entityId else {
        return true
    }
    return entityId.hasPrefix(EntityIdTmpPrefix)
}

extension Persistable where Self: NSObject {
    
    var isNew: Bool {
        return Kinvey.isNew(entityId: entityId)
    }
    
}
