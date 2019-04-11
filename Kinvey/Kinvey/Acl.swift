//
//  Acl.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

/// This class represents the ACL (Access Control List) for a record.
public final class Acl: Object, BuilderType {
    
    /// The `userId` of the `User` used to create the record.
    @objc
    public dynamic var creator: String?
    
    /// The `userId` of the `User` used to create the record.
    public let globalRead = RealmOptional<Bool>()
    
    /// The `userId` of the `User` used to create the record.
    public let globalWrite = RealmOptional<Bool>()
    
    @objc
    fileprivate dynamic var readersValue: String?
    
    /// Specifies the list of user _ids that are explicitly allowed to read the entity.
    public var readers: [String]? {
        get {
            if let value = readersValue,
                let array = AclTransformType().transformFromJSON(value as AnyObject?)
            {
                return array
            }
            return nil
        }
        set {
            readersValue = AclTransformType().transformToJSON(newValue)
        }
    }
    
    @objc
    fileprivate dynamic var writersValue: String?
    
    /// Specifies the list of user _ids that are explicitly allowed to modify the entity.
    public var writers: [String]? {
        get {
            if let value = writersValue,
                let array = AclTransformType().transformFromJSON(value as AnyObject?)
            {
                return array
            }
            return nil
        }
        set {
            if let value = newValue {
                writersValue = AclTransformType().transformToJSON(value)
            } else {
                writersValue = nil
            }
        }
    }
    
    /// Constructs an Acl instance with the `userId` of the `User` used to create the record.
    public convenience init(
        creator: String,
        globalRead: Bool? = nil,
        globalWrite: Bool? = nil,
        readers: [String]? = nil,
        writers: [String]? = nil
    ) {
        self.init()
        self.creator = creator
        self.globalRead.value = globalRead
        self.globalWrite.value = globalWrite
        self.readers = readers
        self.writers = writers
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    public override class func ignoredProperties() -> [String] {
        return ["readers", "writers"]
    }

}

extension Acl: JSONDecodable {
    
    public class func decode<T>(from data: Data) throws -> T where T : JSONDecodable {
        return try decodeJSONDecodable(from: data)
    }
    
    public class func decodeArray<T>(from data: Data) throws -> [T] where T : JSONDecodable {
        return try decodeArrayJSONDecodable(from: data)
    }
    
    public class func decode<T>(from dictionary: [String : Any]) throws -> T where T : JSONDecodable {
        return try decodeJSONDecodable(from: dictionary)
    }
    
    public func refresh(from dictionary: [String : Any]) throws {
        var _self = self
        try _self.refreshJSONDecodable(from: dictionary)
    }
    
}

extension Acl: Decodable {
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let creator = try container.decode(String.self, forKey: .creator)
        self.init(creator: creator)
        globalRead.value = try container.decodeIfPresent(Bool.self, forKey: .globalRead)
        globalWrite.value = try container.decodeIfPresent(Bool.self, forKey: .globalWrite)
        readers = try container.decodeIfPresent([String].self, forKey: .readers)
        writers = try container.decodeIfPresent([String].self, forKey: .writers)
    }
    
}

extension Acl: Encodable {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(creator, forKey: .creator)
        try container.encodeIfPresent(globalRead.value, forKey: .globalRead)
        try container.encodeIfPresent(globalWrite.value, forKey: .globalWrite)
        try container.encodeIfPresent(readers, forKey: .readers)
        try container.encodeIfPresent(writers, forKey: .writers)
    }
    
}

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
extension Acl: Mappable {
    
    /// Constructor that validates if the map contains at least the creator.
    public convenience init?(map: Map) {
        var creator: String?
        creator <- (Acl.CodingKeys.creator.rawValue, map[Acl.CodingKeys.creator])
        if let creator = creator {
            self.init(creator: creator)
        } else {
            return nil
        }
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    public func mapping(map: Map) {
        creator <- ("creator", map[Acl.CodingKeys.creator])
        globalRead.value <- ("globalRead", map[Acl.CodingKeys.globalRead])
        globalWrite.value <- ("globalWrite", map[Acl.CodingKeys.globalWrite])
        readers <- ("readers", map[Acl.CodingKeys.readers])
        writers <- ("writers", map[Acl.CodingKeys.writers])
    }
    
}

extension Acl {
    
    /// Property names for Acl
    @available(*, deprecated, message: "Deprecated in version 3.17.0. Please use Acl.CodingKeys instead")
    public struct Key {
        
        static let creator = "creator"
        static let globalRead = "gr"
        static let globalWrite = "gw"
        static let readers = "r"
        static let writers = "w"
        
    }
    
}

extension Acl {
    
    /// Property names for Acl
    public enum CodingKeys: String, CodingKey {
        
        case creator = "creator"
        case globalRead = "gr"
        case globalWrite = "gw"
        case readers = "r"
        case writers = "w"
        
    }
    
}
