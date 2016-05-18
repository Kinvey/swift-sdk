//
//  Acl.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

/// This class represents the ACL (Access Control List) for a record.
@objc(KNVAcl)
public class Acl: NSObject {
    
    static let CreatorKey = "creator"
    static let GlobalReadKey = "gr"
    static let GlobalWriteKey = "gw"
    static let ReadersKey = "r"
    static let WritersKey = "w"
    
    /// The `userId` of the `User` used to create the record.
    public let creator: String
    
    /// The `userId` of the `User` used to create the record.
    public let globalRead: Bool?
    
    /// The `userId` of the `User` used to create the record.
    public let globalWrite: Bool?
    
    /// Specifies the list of user _ids that are explicitly allowed to read the entity.
    public let readers: [String]?
    
    /// Specifies the list of user _ids that are explicitly allowed to modify the entity.
    public let writers: [String]?
    
    /// Constructs an Acl instance with the `userId` of the `User` used to create the record.
    public init(
        creator: String,
        globalRead: Bool? = nil,
        globalWrite: Bool? = nil,
        readers: [String]? = nil,
        writers: [String]? = nil
    ) {
        self.creator = creator
        self.globalRead = globalRead
        self.globalWrite = globalWrite
        self.readers = readers
        self.writers = writers
    }
    
    /// Constructor used to build a new `Acl` instance from a JSON object.
    public convenience init?(json: JsonDictionary) {
        guard let creator = json[Acl.CreatorKey] as? String else {
            return nil
        }
        
        self.init(
            creator: creator,
            globalRead: json[Acl.GlobalReadKey] as? Bool,
            globalWrite: json[Acl.GlobalWriteKey] as? Bool,
            readers: json[Acl.ReadersKey] as? [String],
            writers: json[Acl.WritersKey] as? [String]
        )
    }
    
    /// The JSON representation for the `Acl` instance.
    public func toJson() -> JsonDictionary {
        var json: JsonDictionary = [
            Acl.CreatorKey : creator,
        ]
        if let globalRead = globalRead {
            json[Acl.GlobalReadKey] = globalRead
        }
        if let globalWrite = globalWrite {
            json[Acl.GlobalWriteKey] = globalWrite
        }
        if let readers = readers {
            json[Acl.ReadersKey] = readers
        }
        if let writers = writers {
            json[Acl.WritersKey] = writers
        }
        return json
    }

}
