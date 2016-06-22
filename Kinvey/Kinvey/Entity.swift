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
    
    public func mapping(map: Map) {
        objectId <- map[PersistableIdKey]
        metadata <- map[PersistableMetadataKey]
        acl <- map[PersistableAclKey]
    }
    
    public class func kinveyPropertyMapping() -> [String : String] {
        //TODO
        let propertyDefaultValues = ObjCRuntime.propertyDefaultValues(self)
        let obj = self.init()
        obj.setValuesForKeysWithDictionary(propertyDefaultValues)
        let result = obj.toJSON()
        for keyPair in result {
            for keyPair2 in propertyDefaultValues {
                if unsafeAddressOf(keyPair.1) == unsafeAddressOf(keyPair2.1) {
                    print("\(keyPair.0) <- \(keyPair2.0)")
                    break
                }
            }
        }
        return [:]
    }
    
    public override class func primaryKey() -> String? {
        return kinveyObjectIdPropertyName()
    }
    
}
