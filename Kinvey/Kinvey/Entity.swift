//
//  Entity.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-06-14.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import ObjectMapper

public class Entity: NSObject, Persistable {
    
    public static let kinveyCollectionName: String = ""
    
    public static let kinveyObjectIdPropertyName: String = "objectId"
    public static let kinveyMetadataPropertyName: String = "metadata"
    public static let kinveyAclPropertyName: String = "acl"
    
    dynamic var objectId: String?
    dynamic var metadata: Metadata?
    dynamic var acl: Acl?
    
    public required init?(_ map: Map) {
    }
    
    public func mapping(map: Map) {
        objectId <- map[PersistableIdKey]
        metadata <- map[PersistableMetadataKey]
        acl <- map[PersistableAclKey]
    }
    
}
