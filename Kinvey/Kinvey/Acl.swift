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
    
    /// The `userId` of the `User` used to create the record.
    public let creator: String
    
    /// Constructs an Acl instance with the `userId` of the `User` used to create the record.
    public init(creator: String) {
        self.creator = creator
    }
    
    /// Constructor used to build an Acl instance from a JSON object.
    public convenience init(json: JsonDictionary) {
        self.init(creator: json[Acl.CreatorKey] as! String)
    }
    
    /// The JSON representation for the `Acl` instance.
    public func toJson() -> JsonDictionary {
        return [
            Acl.CreatorKey : creator
        ]
    }

}
