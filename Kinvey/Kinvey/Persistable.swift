//
//  Persistable.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import CoreData
import ObjectMapper
import CoreLocation
import RealmSwift

public typealias Map = ObjectMapper.Map

public typealias Mappable = ObjectMapper.Mappable
public typealias StaticMappable = ObjectMapper.StaticMappable

public typealias KinveyOptional = RealmSwift.RealmOptional

infix operator <- : DefaultPrecedence

/// Protocol that turns a NSObject into a persistable class to be used in a `DataStore`.
public protocol Persistable: Mappable {
    
    /// Provides the collection name to be matched with the backend.
    static func collectionName() -> String
    
    /// Default Constructor.
    init()
    
}

struct AnyTransform: TransformType {
    
    private let _transformFromJSON: (Any?) -> Any?
    private let _transformToJSON: (Any?) -> Any?
    
    init<Transform: TransformType>(_ transform: Transform) {
        _transformFromJSON = { transform.transformFromJSON($0) }
        _transformToJSON = { transform.transformToJSON($0 as? Transform.Object) }
    }
    
    func transformFromJSON(_ value: Any?) -> Any? {
        return _transformFromJSON(value)
    }
    
    func transformToJSON(_ value: Any?) -> Any? {
        return _transformToJSON(value)
    }

}

internal func kinveyMappingType(left: String, right: String) {
    let currentThread = Thread.current
    if var kinveyMappingType = currentThread.threadDictionary[KinveyMappingTypeKey] as? [String : PropertyMap],
        let className = kinveyMappingType.first?.0,
        var classMapping = kinveyMappingType[className]
    {
        classMapping[left] = (right, nil)
        kinveyMappingType[className] = classMapping
        currentThread.threadDictionary[KinveyMappingTypeKey] = kinveyMappingType
    }
}

internal func kinveyMappingType<Transform: TransformType>(left: String, right: String, transform: Transform) {
    let currentThread = Thread.current
    if var kinveyMappingType = currentThread.threadDictionary[KinveyMappingTypeKey] as? [String : PropertyMap],
        let className = kinveyMappingType.first?.0,
        var classMapping = kinveyMappingType[className]
    {
        classMapping[left] = (right, AnyTransform(transform))
        kinveyMappingType[className] = classMapping
        currentThread.threadDictionary[KinveyMappingTypeKey] = kinveyMappingType
    }
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <T>(left: inout T, right: (String, Map)) {
    let (right, map) = right
    kinveyMappingType(left: right, right: map.currentKey!)
    left <- map
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <T>(left: inout T?, right: (String, Map)) {
    let (right, map) = right
    kinveyMappingType(left: right, right: map.currentKey!)
    left <- map
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <T>(left: inout T!, right: (String, Map)) {
    let (right, map) = right
    kinveyMappingType(left: right, right: map.currentKey!)
    left <- map
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <T: BaseMappable>(left: inout T, right: (String, Map)) {
    let (right, map) = right
    kinveyMappingType(left: right, right: map.currentKey!)
    left <- map
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <T: BaseMappable>(left: inout T?, right: (String, Map)) {
    let (right, map) = right
    kinveyMappingType(left: right, right: map.currentKey!)
    left <- map
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <T: BaseMappable>(left: inout T!, right: (String, Map)) {
    let (right, map) = right
    kinveyMappingType(left: right, right: map.currentKey!)
    left <- map
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <Transform: TransformType>(left: inout Transform.Object, right: (String, Map, Transform)) {
    let (right, map, transform) = right
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    left <- (map, transform)
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <Transform: TransformType>(left: inout Transform.Object?, right: (String, Map, Transform)) {
    let (right, map, transform) = right
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    left <- (map, transform)
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <Transform: TransformType>(left: inout Transform.Object!, right: (String, Map, Transform)) {
    let (right, map, transform) = right
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    left <- (map, transform)
}

// MARK: Default Date Transform

/// Override operator used during the `propertyMapping(_:)` method.
public func <- (left: inout Date, right: (String, Map)) {
    let (right, map) = right
    let transform = KinveyDateTransform()
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    left <- (map, transform)
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- (left: inout Date?, right: (String, Map)) {
    let (right, map) = right
    let transform = KinveyDateTransform()
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    left <- (map, transform)
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- (left: inout Date!, right: (String, Map)) {
    let (right, map) = right
    let transform = KinveyDateTransform()
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    left <- (map, transform)
}
  
class ListValueTransform<T: RealmSwift.Object>: TransformOf<List<T>, [JsonDictionary]> where T: BaseMappable {
    
    init(_ list: List<T>) {
        super.init(fromJSON: { (array) -> List<T>? in
            if let array = array {
                list.removeAll()
                for item in array {
                    if let item = T(JSON: item) {
                        list.append(item)
                    }
                }
                return list
            }
            return nil
        }, toJSON: { (list) -> [JsonDictionary]? in
            if let list = list {
                return list.map { $0.toJSON() }
            }
            return nil
        })
    }
    
}

/// Overload operator for `List` values
public func <-<T: BaseMappable>(lhs: List<T>, rhs: (String, Map)) {
    let (right, map) = rhs
    var list = lhs
    let transform = ListValueTransform<T>(list)
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    list <- (map, transform)
}

// MARK: String Value Transform

class StringValueTransform: TransformOf<List<StringValue>, [String]> {
    init() {
        super.init(fromJSON: { (array: [String]?) -> List<StringValue>? in
            if let array = array {
                let list = List<StringValue>()
                for item in array {
                    list.append(StringValue(item))
                }
                return list
            }
            return nil
        }, toJSON: { (list: List<StringValue>?) -> [String]? in
            if let list = list {
                return list.map { $0.value }
            }
            return nil
        })
    }
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- (left: List<StringValue>, right: (String, Map)) {
    let (right, map) = right
    let transform = StringValueTransform()
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    var list = left
    switch map.mappingType {
    case .toJSON:
        list <- (map, transform)
    case .fromJSON:
        list <- (map, transform)
        left.removeAll()
        left.append(objectsIn: list)
    }
}

// MARK: Int Value Transform

class IntValueTransform: TransformOf<List<IntValue>, [Int]> {
    init() {
        super.init(fromJSON: { (array: [Int]?) -> List<IntValue>? in
            if let array = array {
                let list = List<IntValue>()
                for item in array {
                    list.append(IntValue(item))
                }
                return list
            }
            return nil
        }, toJSON: { (list: List<IntValue>?) -> [Int]? in
            if let list = list {
                return list.map { $0.value }
            }
            return nil
        })
    }
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- (left: List<IntValue>, right: (String, Map)) {
    let (right, map) = right
    let transform = IntValueTransform()
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    var list = left
    switch map.mappingType {
    case .toJSON:
        list <- (map, transform)
    case .fromJSON:
        list <- (map, transform)
        left.removeAll()
        left.append(objectsIn: list)
    }
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <T>(left: KinveyOptional<T>, right: (query: String, map: Map)) {
    kinveyMappingType(left: right.query, right: right.map.currentKey!)
    left.value <- right.map
}

// MARK: Float Value Transform

class FloatValueTransform: TransformOf<List<FloatValue>, [Float]> {
    init() {
        super.init(fromJSON: { (array: [Float]?) -> List<FloatValue>? in
            if let array = array {
                let list = List<FloatValue>()
                for item in array {
                    list.append(FloatValue(item))
                }
                return list
            }
            return nil
        }, toJSON: { (list: List<FloatValue>?) -> [Float]? in
            if let list = list {
                return list.map { $0.value }
            }
            return nil
        })
    }
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- (left: List<FloatValue>, right: (String, Map)) {
    let (right, map) = right
    let transform = FloatValueTransform()
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    var list = left
    switch map.mappingType {
    case .toJSON:
        list <- (map, transform)
    case .fromJSON:
        list <- (map, transform)
        left.removeAll()
        left.append(objectsIn: list)
    }
}

// MARK: Double Value Transform

class DoubleValueTransform: TransformOf<List<DoubleValue>, [Double]> {
    init() {
        super.init(fromJSON: { (array: [Double]?) -> List<DoubleValue>? in
            if let array = array {
                let list = List<DoubleValue>()
                for item in array {
                    list.append(DoubleValue(item))
                }
                return list
            }
            return nil
        }, toJSON: { (list: List<DoubleValue>?) -> [Double]? in
            if let list = list {
                return list.map { $0.value }
            }
            return nil
        })
    }
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- (left: List<DoubleValue>, right: (String, Map)) {
    let (right, map) = right
    let transform = DoubleValueTransform()
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    var list = left
    switch map.mappingType {
    case .toJSON:
        list <- (map, transform)
    case .fromJSON:
        list <- (map, transform)
        left.removeAll()
        left.append(objectsIn: list)
    }
}

// MARK: Bool Value Transform

class BoolValueTransform: TransformOf<List<BoolValue>, [Bool]> {
    init() {
        super.init(fromJSON: { (array: [Bool]?) -> List<BoolValue>? in
            if let array = array {
                let list = List<BoolValue>()
                for item in array {
                    list.append(BoolValue(item))
                }
                return list
            }
            return nil
        }, toJSON: { (list: List<BoolValue>?) -> [Bool]? in
            if let list = list {
                return list.map { $0.value }
            }
            return nil
        })
    }
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- (left: List<BoolValue>, right: (String, Map)) {
    let (right, map) = right
    let transform = BoolValueTransform()
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    var list = left
    switch map.mappingType {
    case .toJSON:
        list <- (map, transform)
    case .fromJSON:
        list <- (map, transform)
        left.removeAll()
        left.append(objectsIn: list)
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
    
    static func propertyMappingReverse() -> [String : [String]] {
        var results = [String : [String]]()
        for (key, (value, _)) in propertyMapping() {
            var properties = results[value]
            if properties == nil {
                properties = [String]()
            }
            properties!.append(key)
            results[value] = properties
        }
        let entityIdMapped = results[Entity.Key.entityId] != nil
        let metadataMapped = results[Entity.Key.metadata] != nil
        if !(entityIdMapped && metadataMapped) {
            let isEntity = self is Entity.Type
            let hintMessage = isEntity ? "Please call super.propertyMapping() inside your propertyMapping() method." : "Please add properties in your Persistable model class to map the missing properties."
            guard entityIdMapped else {
                fatalError("Property \(Entity.Key.entityId) (Entity.Key.entityId) is missing in the propertyMapping() method. \(hintMessage)")
            }
            guard metadataMapped else {
                fatalError("Property \(Entity.Key.metadata) (Entity.Key.metadata) is missing in the propertyMapping() method. \(hintMessage)")
            }
        }
        return results
    }
    
    static func propertyMapping() -> PropertyMap {
        let currentThread = Thread.current
        let className = StringFromClass(cls: self as! AnyClass)
        currentThread.threadDictionary[KinveyMappingTypeKey] = [className : PropertyMap()]
        defer {
            currentThread.threadDictionary.removeObject(forKey: KinveyMappingTypeKey)
        }
        let obj = self.init()
        let _ = obj.toJSON()
        if let kinveyMappingType = currentThread.threadDictionary[KinveyMappingTypeKey] as? [String : PropertyMap],
            let kinveyMappingClassType = kinveyMappingType[className]
        {
            return kinveyMappingClassType
        }
        return [:]
    }
    
    static func propertyMapping(_ propertyName: String) -> PropertyMap.Value? {
        return propertyMapping()[propertyName]
    }
    
    internal static func entityIdProperty() -> String {
        return propertyMappingReverse()[Entity.Key.entityId]!.last!
    }
    
    internal static func aclProperty() -> String? {
        return propertyMappingReverse()[Entity.Key.acl]?.last
    }
    
    internal static func metadataProperty() -> String? {
        return propertyMappingReverse()[Entity.Key.metadata]?.last
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
            return self[type(of: self).entityIdProperty()] as? String
        }
        set {
            self[type(of: self).entityIdProperty()] = newValue
        }
    }
    
    internal var acl: Acl? {
        get {
            if let aclKey = type(of: self).aclProperty() {
                return self[aclKey] as? Acl
            }
            return nil
        }
        set {
            if let aclKey = type(of: self).aclProperty() {
                self[aclKey] = newValue
            }
        }
    }
    
    internal var metadata: Metadata? {
        get {
            if let kmdKey = type(of: self).metadataProperty() {
                return self[kmdKey] as? Metadata
            }
            return nil
        }
        set {
            if let kmdKey = type(of: self).metadataProperty() {
                self[kmdKey] = newValue
            }
        }
    }
    
}

extension AnyRandomAccessCollection where Element: Persistable {
    
    public subscript(idx: Int) -> Element {
        return self[Int64(idx)]
    }
    
    public subscript(idx: Int64) -> Element {
        return self[index(startIndex, offsetBy: idx)]
    }
    
}
