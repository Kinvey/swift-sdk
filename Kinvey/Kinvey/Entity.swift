//
//  Entity.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-06-14.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

public class Entity: Object, Persistable {
    
    public class func kinveyCollectionName() -> String {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    public class func kinveyObjectIdPropertyName() -> String {
        return "objectId"
    }
    
    public class func kinveyMetadataPropertyName() -> String? {
        return "metadata"
    }
    
    public class func kinveyAclPropertyName() -> String? {
        return "acl"
    }
    
    public dynamic var objectId: String?
    public dynamic var metadata: Metadata?
    public dynamic var acl: Acl?
    
    public required init?(_ map: Map) {
        super.init()
    }
    
    public required init() {
        super.init()
    }
    
    public required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    public required init(value: AnyObject, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    public func kinveyPropertyMapping(map: Map) {
        objectId <- ("objectId", map[PersistableIdKey])
        metadata <- ("metadata", map[PersistableMetadataKey])
        acl <- ("acl", map[PersistableAclKey])
    }
    
    public override class func primaryKey() -> String? {
        return kinveyObjectIdPropertyName()
    }
    
}
