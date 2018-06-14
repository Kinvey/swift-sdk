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
import ObjectMapper

class AclTransformType: TransformType {
    
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

/// This class represents the ACL (Access Control List) for a record.
public final class Acl: Object, BuilderType {
    
    /// The `userId` of the `User` used to create the record.
    @objc
    open dynamic var creator: String?
    
    /// The `userId` of the `User` used to create the record.
    open let globalRead = RealmOptional<Bool>()
    
    /// The `userId` of the `User` used to create the record.
    open let globalWrite = RealmOptional<Bool>()
    
    @objc
    fileprivate dynamic var readersValue: String?
    
    /// Specifies the list of user _ids that are explicitly allowed to read the entity.
    open var readers: [String]? {
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
    open var writers: [String]? {
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
    open override class func ignoredProperties() -> [String] {
        return ["readers", "writers"]
    }

}

extension Acl: Mappable {
    
    /// Constructor that validates if the map contains at least the creator.
    public convenience init?(map: Map) {
        var creator: String?
        creator <- map[Acl.CodingKeys.creator]
        if let creator = creator {
            self.init(creator: creator)
        } else {
            return nil
        }
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    open func mapping(map: Map) {
        creator <- ("creator", map[Acl.CodingKeys.creator])
        globalRead.value <- ("globalRead", map[Acl.CodingKeys.globalRead])
        globalWrite.value <- ("globalWrite", map[Acl.CodingKeys.globalWrite])
        readers <- ("readers", map[Acl.CodingKeys.readers])
        writers <- ("writers", map[Acl.CodingKeys.writers])
    }
    
}

extension Acl {
    
    /// Property names for Acl
    @available(*, deprecated: 3.17.0, message: "Please use Acl.CodingKeys instead")
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
