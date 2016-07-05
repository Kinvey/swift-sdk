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

internal func StringFromClass(cls: AnyClass) -> String {
    var className = NSStringFromClass(cls)
    while className.hasPrefix("RLMStandalone_") {
        let classObj: AnyClass! = NSClassFromString(className)!
        let superClass: AnyClass! = class_getSuperclass(classObj)
        className = NSStringFromClass(superClass)
    }
    return className
}

public class Entity: Object, Persistable {
    
    public class func collectionName() -> String {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    public dynamic var entityId: String?
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
    
    public func propertyMapping(map: Map) {
        entityId <- ("entityId", map[PersistableIdKey])
        metadata <- ("metadata", map[PersistableMetadataKey])
        acl <- ("acl", map[PersistableAclKey])
    }
    
    public override class func primaryKey() -> String? {
        return entityIdProperty()
    }
    
    public func mapping(map: Map) {
        let originalThread = NSThread.currentThread()
        let runningMapping = originalThread.threadDictionary[KinveyMappingTypeKey] != nil
        if runningMapping {
            let operationQueue = NSOperationQueue()
            operationQueue.name = "Kinvey Property Mapping"
            operationQueue.maxConcurrentOperationCount = 1
            operationQueue.addOperationWithBlock {
                let className = StringFromClass(self.dynamicType)
                NSThread.currentThread().threadDictionary[KinveyMappingTypeKey] = [className : Dictionary<String, String>()]
                self.propertyMapping(map)
                originalThread.threadDictionary[KinveyMappingTypeKey] = NSThread.currentThread().threadDictionary[KinveyMappingTypeKey]
            }
            operationQueue.waitUntilAllOperationsAreFinished()
        } else {
            self.propertyMapping(map)
        }
    }
    
}
