//
//  JSONParser.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-09.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public typealias JSONCodable = JSONDecodable & JSONEncodable

public protocol JSONDecodable {
    
    static func decode<T>(from data: Data) throws -> T where T: JSONDecodable
    static func decodeArray<T>(from data: Data) throws -> [T] where T: JSONDecodable
    static func decode<T>(from dictionary: [String : Any]) throws -> T where T: JSONDecodable
    mutating func refresh(from dictionary: [String : Any]) throws
    
}

extension JSONDecodable {
    
    public mutating func refreshJSONDecodable(from dictionary: [String : Any]) throws {
        switch self {
        case var selfMappable as (JSONDecodable & BaseMappable):
            try selfMappable.refreshMappable(from: dictionary)
        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Your \(self) subclass must implement Swift.Codable or ObjectMapper.Mappable"))
        }
    }
    
    public static func decodeJSONDecodable<T>(from data: Data) throws -> T where T: JSONDecodable {
        switch self {
        case let decodableType as (JSONDecodable & Decodable).Type:
            return try decodableType.decodeDecodable(from: data) as! T
        case let baseMappableType as (JSONDecodable & BaseMappable).Type:
            return try baseMappableType.decodeMappable(from: data) as! T
        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Your \(self) subclass must implement Swift.Codable or ObjectMapper.Mappable"))
        }
    }
    
    public static func decodeArrayJSONDecodable<T>(from data: Data) throws -> [T] where T : JSONDecodable {
        switch self {
        case let decodableType as (JSONDecodable & Decodable).Type:
            return try decodableType.decodeDecodableArray(from: data) as! [T]
        case let baseMappableType as (JSONDecodable & BaseMappable).Type:
            return try baseMappableType.decodeMappableArray(from: data) as! [T]
        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Your \(self) subclass must implement Swift.Codable or ObjectMapper.Mappable"))
        }
    }
    
    public static func decodeJSONDecodable<T>(from dictionary: [String : Any]) throws -> T where T: JSONDecodable {
        switch self {
        case let decodableType as (JSONDecodable & Decodable).Type:
            return try decodableType.decodeDecodable(from: dictionary) as! T
        case let baseMappableType as (JSONDecodable & BaseMappable).Type:
            return try baseMappableType.decodeMappable(from: dictionary) as! T
        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Your \(self) subclass must implement Swift.Codable or ObjectMapper.Mappable"))
        }
    }
    
}

extension JSONDecodable where Self: JSONEncodable {
    
    public mutating func refresh(from _self: Self) throws {
        try refresh(from: try _self.encode())
    }
    
}

extension JSONDecodable where Self: Decodable {
    
    static func decodeDecodable(from data: Data) throws -> Self {
        return try JSONDecoder().decode(Self.self, from: data)
    }
    
    static func decodeDecodableArray(from data: Data) throws -> [Any] {
        return try JSONDecoder().decode([Self].self, from: data)
    }
    
    static func decodeDecodable(from dictionary: [String : Any]) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return try JSONDecoder().decode(Self.self, from: data)
    }
    
}

public protocol JSONEncodable {
    
    func encode() throws -> [String : Any]
    
}

extension JSONEncodable {
    
    public func encodeJSONEncodable() throws -> [String : Any] {
        switch self {
        case let selfEncodable as (JSONEncodable & Encodable):
            return try selfEncodable.encodeEncodable()
        case let selfMappable as (JSONEncodable & BaseMappable):
            return try selfMappable.encodeMappable()
        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Your \(self) subclass must implement Swift.Codable or ObjectMapper.Mappable"))
        }
    }
    
}

extension JSONEncodable where Self: Encodable {
    
    func encodeEncodable() throws -> [String : Any] {
        return try DictionaryEncoder().encode(self)
    }
    
}

public protocol JSONParser {
    
    func parseDictionary(from data: Data) throws -> JsonDictionary
    func parseDictionaries(from data: Data) throws -> [JsonDictionary]
    
    func parseObject<T>(_ type: T.Type, from data: Data) throws -> T where T: JSONDecodable
    func parseObjects<T>(_ type: T.Type, from data: Data) throws -> [T] where T: JSONDecodable
    
    func parseUser<UserType: User>(_ type: UserType.Type, from data: Data) throws -> UserType
    func parseUsers<UserType: User>(_ type: UserType.Type, from data: Data) throws -> [UserType]
    
    func parseUser<UserType: User>(_ type: UserType.Type, from dictionary: [String : Any]) throws -> UserType
    func parseObject<T>(_ type: T.Type, from dictionary: [String : Any]) throws -> T where T: JSONDecodable
    
    func toJSON<UserType: User>(_ user: UserType) throws -> [String : Any]
    func toJSON<T>(_ object: T) throws -> [String : Any] where T: JSONEncodable

}

class DefaultJSONParser: JSONParser {
    
    let client: Client
    
    init(client: Client) {
        self.client = client
    }

    func parseDictionary(from data: Data) throws -> JsonDictionary {
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        guard let object = jsonObject as? [String : Any] else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "JSON Parser returned \(type(of: jsonObject)) when \([String : Any].self) should be returned"))
        }
        return object
    }

    func parseDictionaries(from data: Data) throws -> [JsonDictionary] {
        let jsonObjectArray = try JSONSerialization.jsonObject(with: data)
        guard let array = jsonObjectArray as? [[String : Any]] else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "JSON Parser returned \(type(of: jsonObjectArray)) when \([[String : Any]].self) should be returned"))
        }
        return array
    }

    func parseObject<T>(_ type: T.Type, from data: Data) throws -> T where T: JSONDecodable {
        return try type.decode(from: data)
    }

    func parseObjects<T>(_ type: T.Type, from data: Data) throws -> [T] where T: JSONDecodable {
        return try type.decodeArray(from: data)
    }

    func parseUser<UserType>(_ type: UserType.Type, from data: Data) throws -> UserType where UserType : User {
        return try parseObject(client.userType, from: data) as! UserType
    }

    func parseUsers<UserType>(_ type: UserType.Type, from data: Data) throws -> [UserType] where UserType : User {
        return try parseObjects(client.userType, from: data) as! [UserType]
    }

    func parseUser<UserType>(_ type: UserType.Type, from dictionary: [String : Any]) throws -> UserType where UserType : User {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return try parseUser(client.userType, from: data) as! UserType
    }

    func parseObject<T>(_ type: T.Type, from dictionary: [String : Any]) throws -> T where T: JSONDecodable {
        return try type.decode(from: dictionary)
    }

    func toJSON<UserType>(_ user: UserType) throws -> [String : Any] where UserType : User {
        return try user.encode()
    }

    func toJSON<T>(_ object: T) throws -> [String : Any] where T: JSONEncodable {
        return try object.encode()
    }

}

class DictionaryEncoder {
    
    func encode<T: Encodable>(_ value: T) throws -> [String : Any] {
        let encoder = _DictionaryEncoder()
        try value.encode(to: encoder)
        return encoder.dictionary
    }
    
}

protocol DictionaryEncodingContainer {
    
    var dictionary: [String : Any] { get }
    
}

extension _DictionaryEncoder: DictionaryEncodingContainer {
    
    var dictionary: [String : Any] {
        return container?.dictionary ?? [:]
    }
    
}

class _DictionaryEncoder: Encoder {
    
    let codingPath = [CodingKey]()
    
    let userInfo = [CodingUserInfoKey : Any]()
    
    private var container: DictionaryEncodingContainer?
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        var storage = self.container?.dictionary ?? [:]
        let container = KeyedContainer<Key>(
            codingPath: self.codingPath,
            userInfo: self.userInfo,
            storage: &storage
        )
        self.container = container
        
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("Method not implemented")
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("Method not implemented")
    }
    
}

extension _DictionaryEncoder {
    
    class KeyedContainer<Key> where Key: CodingKey {
        
        private var storage: [String : Any]
        
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        
        func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
            return self.codingPath + [key]
        }
        
        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], storage: inout [String : Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.storage = storage
        }
    }
    
}

extension _DictionaryEncoder.KeyedContainer: DictionaryEncodingContainer {
    
    var dictionary: [String : Any] {
        return storage
    }
    
}

extension _DictionaryEncoder.KeyedContainer: KeyedEncodingContainerProtocol {
    
    func encodeNil(forKey key: Key) throws {
        fatalError("Method not implemented")
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError("Method not implemented")
    }
    
    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        fatalError("Method not implemented")
    }
    
    func superEncoder() -> Encoder {
        fatalError("Method not implemented")
    }
    
    func superEncoder(forKey key: Key) -> Encoder {
        fatalError("Method not implemented")
    }
    
    func encode(_ value: Bool, forKey key: Key) throws {
        storage[key.stringValue] = value
    }
    
    func encode(_ value: String, forKey key: Key) throws {
        storage[key.stringValue] = value
    }
    
    func encode(_ value: Double, forKey key: Key) throws {
        storage[key.stringValue] = value
    }
    
    func encode(_ value: Float, forKey key: Key) throws {
        storage[key.stringValue] = value
    }
    
    func encode(_ value: Int, forKey key: Key) throws {
        storage[key.stringValue] = value
    }
    
    func encode(_ value: Int8, forKey key: Key) throws {
        storage[key.stringValue] = value
    }
    
    func encode(_ value: Int16, forKey key: Key) throws {
        storage[key.stringValue] = value
    }
    
    func encode(_ value: Int32, forKey key: Key) throws {
        storage[key.stringValue] = value
    }
    
    func encode(_ value: Int64, forKey key: Key) throws {
        storage[key.stringValue] = value
    }
    
    func encode(_ value: UInt, forKey key: Key) throws {
        storage[key.stringValue] = value
    }
    
    func encode(_ value: UInt8, forKey key: Key) throws {
        storage[key.stringValue] = value
    }
    
    func encode(_ value: UInt16, forKey key: Key) throws {
        storage[key.stringValue] = value
    }
    
    func encode(_ value: UInt32, forKey key: Key) throws {
        storage[key.stringValue] = value
    }
    
    func encode(_ value: UInt64, forKey key: Key) throws {
        storage[key.stringValue] = value
    }
    
    func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        let encoder = _DictionaryEncoder()
        try value.encode(to: encoder)
        storage[key.stringValue] = encoder.dictionary
    }
    
}
