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
    typealias JSON = [String]
    
    func transformFromJSON(value: AnyObject?) -> [String]? {
        if let value = value as? String,
            let data = value.dataUsingEncoding(NSUTF8StringEncoding),
            let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []),
            let array = json as? Object
        {
            return array
        } else if let value = value as? [String] {
            return value
        }
        return nil
    }
    
    func transformToJSON(value: [String]?) -> [String]? {
        return value
    }

}

/// This class represents the ACL (Access Control List) for a record.
public class Acl: Object, Mappable {
    
    static let CreatorKey = "creator"
    static let GlobalReadKey = "gr"
    static let GlobalWriteKey = "gw"
    static let ReadersKey = "r"
    static let WritersKey = "w"
    
    /// The `userId` of the `User` used to create the record.
    public dynamic var creator: String?
    
    /// The `userId` of the `User` used to create the record.
    public let globalRead = RealmOptional<Bool>()
    
    /// The `userId` of the `User` used to create the record.
    public let globalWrite = RealmOptional<Bool>()
    
    private dynamic var readersValue: String?
    
    /// Specifies the list of user _ids that are explicitly allowed to read the entity.
    public var readers: [String]? {
        get {
            if let value = readersValue, let array = AclTransformType().transformFromJSON(value) {
                return array
            }
            return nil
        }
        set {
            if let newValue = newValue,
                let data = try? NSJSONSerialization.dataWithJSONObject(newValue, options: []),
                let json = String(data: data, encoding: NSUTF8StringEncoding)
            {
                readersValue = json
            } else {
                readersValue = nil
            }
        }
    }
    
    private dynamic var writersValue: String?
    
    /// Specifies the list of user _ids that are explicitly allowed to modify the entity.
    public var writers: [String]? {
        get {
            if let value = writersValue, let array = AclTransformType().transformFromJSON(value) {
                return array
            }
            return nil
        }
        set {
            if let newValue = newValue,
                let data = try? NSJSONSerialization.dataWithJSONObject(newValue, options: []),
                let json = String(data: data, encoding: NSUTF8StringEncoding)
            {
                writersValue = json
            } else {
                writersValue = nil
            }
        }
    }
    
    /// Constructs an Acl instance with the `userId` of the `User` used to create the record.
    public init(
        creator: String,
        globalRead: Bool? = nil,
        globalWrite: Bool? = nil,
        readers: [String]? = nil,
        writers: [String]? = nil
    ) {
        self.creator = creator
        self.globalRead.value = globalRead
        self.globalWrite.value = globalWrite
        super.init()
        self.readers = readers
        self.writers = writers
    }
    
    public required convenience init?(_ map: Map) {
        var creator: String?
        
        creator <- map[Acl.CreatorKey]
        
        guard let creatorValue = creator else {
            return nil
        }
        
        self.init(creator: creatorValue)
    }
    
    public required init() {
        super.init()
    }
    
    public required init(value: AnyObject, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    public required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    public func mapping(map: Map) {
        creator <- map[Acl.CreatorKey]
        globalRead.value <- map[Acl.GlobalReadKey]
        globalWrite.value <- map[Acl.GlobalWriteKey]
        readers <- (map[Acl.ReadersKey], AclTransformType())
        writers <- (map[Acl.WritersKey], AclTransformType())
    }
    
    public override class func ignoredProperties() -> [String] {
        return ["readers", "writers"]
    }

}
