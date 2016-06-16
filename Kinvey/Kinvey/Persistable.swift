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

/// Protocol that turns a NSObject into a persistable class to be used in a `DataStore`.
public protocol Persistable: Mappable {
    
    /// Provides the collection name to be matched with the backend.
    static func kinveyCollectionName() -> String
    
    /// Provides the object id property name.
    static func kinveyObjectIdPropertyName() -> String
    
    /// Provides the metadata property name.
    static func kinveyMetadataPropertyName() -> String?
    
    /// Provides the ACL property name.
    static func kinveyAclPropertyName() -> String?
    
}

extension Persistable where Self: NSObject {
    
    public subscript(key: String) -> AnyObject? {
        get {
            return self.valueForKey(key)
        }
        set {
            self.setValue(newValue, forKey: key)
        }
    }
    
    internal var kinveyObjectId: String? {
        get {
            return self[Self.kinveyObjectIdPropertyName()] as? String
        }
        set {
            self[Self.kinveyObjectIdPropertyName()] = newValue
        }
    }
    
    internal var kinveyAcl: Acl? {
        get {
            if let aclKey = Self.kinveyAclPropertyName() {
                return self[aclKey] as? Acl
            }
            return nil
        }
        set {
            if let aclKey = Self.kinveyAclPropertyName() {
                self[aclKey] = newValue
            }
        }
    }
    
    internal static func fromJson(json: JsonDictionary) -> Self? {
        return Mapper().map(json)
    }
    
}
