//
//  ObjectMapperSupport.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2018-06-26.
//  Copyright © 2018 Kinvey. All rights reserved.
//

import CoreLocation
import ObjectMapper
import RealmSwift

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public typealias Map = ObjectMapper.Map

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public typealias Mappable = ObjectMapper.Mappable

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public typealias StaticMappable = ObjectMapper.StaticMappable

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public typealias TransformType = ObjectMapper.TransformType

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public typealias TransformOf = ObjectMapper.TransformOf

public typealias BaseMappable = ObjectMapper.BaseMappable

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public typealias MapContext = ObjectMapper.MapContext

// Workaround regression introduced with https://github.com/tristanhimmelman/ObjectMapper/pull/1079
// These extension methods have been moved to Mappable which breaks our code because we need to call
// them on Mappable instances (e.g. StaticMappable doesn't conform to Mappable, but only to BaseMappable)
public extension BaseMappable {

    /// Initializes object from a JSON String
    init?(JSONString: String, context: MapContext? = nil) {
        if let obj: Self = Mapper(context: context).map(JSONString: JSONString) {
            self = obj
        } else {
            return nil
        }
    }

    /// Initializes object from a JSON Dictionary
    init?(JSON: [String: Any], context: MapContext? = nil) {
        if let obj: Self = Mapper(context: context).map(JSON: JSON) {
            self = obj
        } else {
            return nil
        }
    }
}

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
extension Map {

    @available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
    public subscript<Key: RawRepresentable>(key: Key) -> Map where Key.RawValue == String {
        return self[key.rawValue]
    }

}

extension JSONDecodable where Self: BaseMappable {

    public mutating func refreshMappable(from json: [String : Any]) throws {
        mapping(map: ObjectMapper.Map(mappingType: .fromJSON, JSON: json))
    }

    public static func decodeMappable(from data: Data) throws -> Self {
        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String : Any] else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Data can't be converted to a Dictionary"))
        }
        guard let _self = Self(JSON: jsonObject) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Data can't be converted to \(Self.self)"))
        }
        return _self
    }

    public static func decodeMappableArray(from data: Data) throws -> [Any] {
        guard let jsonObjectArray = try JSONSerialization.jsonObject(with: data) as? [[String : Any]] else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Data can't be converted to a Array of Dictionaries"))
        }
        return [Self](JSONArray: jsonObjectArray)
    }

    public static func decodeMappable(from dictionary: [String : Any]) throws -> Self {
        guard let _self = Self(JSON: dictionary) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Data can't be converted to \(Self.self)"))
        }
        return _self
    }

}

extension JSONEncodable where Self: BaseMappable {

    func encodeMappable() throws -> [String : Any] {
        return self.toJSON()
    }

}

/// Override operator used during the `propertyMapping(_:)` method.
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public func <- (left: inout GeoPoint, right: (String, Map)) {
    let (right, map) = right
    let transform = GeoPointTransform.shared
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    left <- (map, transform)
}

/// Override operator used during the `propertyMapping(_:)` method.
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public func <- (left: inout GeoPoint?, right: (String, Map)) {
    let (right, map) = right
    let transform = GeoPointTransform.shared
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    left <- (map, transform)
}

/// Override operator used during the `propertyMapping(_:)` method.
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public func <- <T>(left: inout T, right: (String, Map)) {
    let (right, map) = right
    kinveyMappingType(left: right, right: map.currentKey!)
    left <- map
}

/// Override operator used during the `propertyMapping(_:)` method.
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public func <- <T>(left: inout T?, right: (String, Map)) {
    let (right, map) = right
    kinveyMappingType(left: right, right: map.currentKey!)
    left <- map
}

/// Override operator used during the `propertyMapping(_:)` method.
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public func <- <T: BaseMappable>(left: inout T, right: (String, Map)) {
    let (right, map) = right
    kinveyMappingType(left: right, right: map.currentKey!)
    left <- map
}

/// Override operator used during the `propertyMapping(_:)` method.
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public func <- <T: BaseMappable>(left: inout T?, right: (String, Map)) {
    let (right, map) = right
    kinveyMappingType(left: right, right: map.currentKey!)
    left <- map
}

/// Override operator used during the `propertyMapping(_:)` method.
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public func <- <Transform: TransformType>(left: inout Transform.Object, right: (String, Map, Transform)) {
    let (right, map, transform) = right
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    left <- (map, transform)
}

/// Override operator used during the `propertyMapping(_:)` method.
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public func <- <Transform: TransformType>(left: inout Transform.Object?, right: (String, Map, Transform)) {
    let (right, map, transform) = right
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    left <- (map, transform)
}

// MARK: Default Date Transform

/// Override operator used during the `propertyMapping(_:)` method.
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public func <- (left: inout Date, right: (String, Map)) {
    let (right, map) = right
    let transform = KinveyDateTransform()
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    left <- (map, transform)
}

/// Override operator used during the `propertyMapping(_:)` method.
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public func <- (left: inout Date?, right: (String, Map)) {
    let (right, map) = right
    let transform = KinveyDateTransform()
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    left <- (map, transform)
}

/// Overload operator for `List` values
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public func <-<T: Object & BaseMappable>(lhs: List<T>, rhs: (String, Map)) {
    let (right, map) = rhs
    var list = lhs
    let transform = ListValueTransform<T>(list)
    kinveyMappingType(left: right, right: map.currentKey!, transform: transform)
    list <- (map, transform)
}

/// Override operator used during the `propertyMapping(_:)` method.
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
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

/// Override operator used during the `propertyMapping(_:)` method.
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
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
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
public func <- <T>(left: KinveyOptional<T>, right: (query: String, map: Map)) {
    kinveyMappingType(left: right.query, right: right.map.currentKey!)
    left.value <- right.map
}

/// Override operator used during the `propertyMapping(_:)` method.
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
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

/// Override operator used during the `propertyMapping(_:)` method.
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
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

/// Override operator used during the `propertyMapping(_:)` method.
@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
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

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
extension NSPredicate: StaticMappable {

    @available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
    public static func objectForMapping(map: Map) -> BaseMappable? {
        return nil
    }

    @available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
    public func mapping(map: Map) {
        if let json = mongoDBQuery {
            for (key, var value) in json {
                value <- map[key]
            }
        }
    }

}

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
class GeoPointTransform: TransformOf<GeoPoint, [CLLocationDegrees]> {

    static let shared = GeoPointTransform()

    init() {
        super.init(fromJSON: { (array) -> GeoPoint? in
            if let array = array, array.count == 2 {
                return GeoPoint(array)
            }
            return nil
        }, toJSON: { (geopoint) -> [CLLocationDegrees]? in
            if let geopoint = geopoint {
                return [geopoint.longitude, geopoint.latitude]
            }
            return nil
        })
    }

}

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
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

// MARK: String Value Transform

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
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

// MARK: Int Value Transform

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
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

// MARK: Float Value Transform

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
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

// MARK: Double Value Transform

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
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

// MARK: Bool Value Transform

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
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

class AclTransformType {

    typealias Object = [String]
    typealias JSON = String

    func transformFromJSON(_ value: Any?) -> [String]? {
        if let value = value as? String,
            let data = value.data(using: String.Encoding.utf8),
            let json = try? JSONSerialization.jsonObject(with: data),
            let array = json as? [String]
        {
            return array
        }
        return nil
    }

    func transformToJSON(_ value: [String]?) -> String? {
        if let value = value,
            let data = try? JSONSerialization.data(withJSONObject: value),
            let json = String(data: data, encoding: String.Encoding.utf8)
        {
            return json
        }
        return nil
    }

}

struct AnyTransform: ObjectMapper.TransformType {

    private let _transformFromJSON: (Any?) -> Any?
    private let _transformToJSON: (Any?) -> Any?

    init<Transform: ObjectMapper.TransformType>(_ transform: Transform) {
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
