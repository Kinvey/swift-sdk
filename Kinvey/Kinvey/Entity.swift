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
import ObjectMapper

public class Entity: RLMObject, Persistable {
    
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
    
    dynamic var objectId: String?
    dynamic var metadata: Metadata?
    dynamic var acl: Acl?
    
    public required init?(_ map: Map) {
        super.init()
    }
    
    public required override init() {
        super.init()
    }
    
    public func mapping(map: Map) {
        objectId <- map[PersistableIdKey]
        metadata <- map[PersistableMetadataKey]
        acl <- map[PersistableAclKey]
    }
    
    public override class func primaryKey() -> String? {
        return "objectId"
    }
    
}
