//
//  Persistable.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import CoreData

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
    
    mutating func kinveyPropertyMapping(map: Map)
    
}

private func kinveyMappingType(left left: String, right: String) {
    if var kinveyMappingType = NSThread.currentThread().threadDictionary[KinveyMappingTypeKey] as? [String : [String : String]],
        let className = kinveyMappingType.first?.0,
        var classMapping = kinveyMappingType[className]
    {
        classMapping[left] = right
        kinveyMappingType[className] = classMapping
        NSThread.currentThread().threadDictionary[KinveyMappingTypeKey] = kinveyMappingType
    }
}

public func <- <T>(inout left: T, right: (String, Map)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- right.1
}

public func <- <T>(inout left: T?, right: (String, Map)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- right.1
}

public func <- <T>(inout left: T!, right: (String, Map)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- right.1
}

public func <- <T: Mappable>(inout left: T, right: (String, Map)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- right.1
}

public func <- <T: Mappable>(inout left: T?, right: (String, Map)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- right.1
}

public func <- <T: Mappable>(inout left: T!, right: (String, Map)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- right.1
}

public func <- <Transform: TransformType>(inout left: Transform.Object, right: (String, Map, Transform)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- (right.1, right.2)
}

public func <- <Transform: TransformType>(inout left: Transform.Object?, right: (String, Map, Transform)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- (right.1, right.2)
}

public func <- <Transform: TransformType>(inout left: Transform.Object!, right: (String, Map, Transform)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- (right.1, right.2)
}

private var propertyMapping = [String : (String, String)]()

extension Persistable {
    
    static func kinveyPropertyMapping(propertyName: String) -> String? {
        if let type = Self.self as? NSObject.Type {
            let currentThread = NSThread.currentThread()
            currentThread.threadDictionary[KinveyMappingTypeKey] = [NSStringFromClass(type) : Dictionary<String, String>()]
            let obj = type.init() as! Self
            obj.toJSON()
            if let kinveyMappingType = currentThread.threadDictionary[KinveyMappingTypeKey] as? [String : [String : String]],
                let kinveyMappingClassType = kinveyMappingType[NSStringFromClass(type)]
            {
                return kinveyMappingClassType[propertyName]
            }
        }
        return nil
    }
    
}

private let KinveyMappingTypeKey = "Kinvey Mapping Type"

extension Persistable where Self: NSObject {
    
    public mutating func mapping(map: Map) {
        let originalThread = NSThread.currentThread()
        let runningMapping = originalThread.threadDictionary[KinveyMappingTypeKey] != nil
        if runningMapping {
            let operationQueue = NSOperationQueue()
            operationQueue.name = "Kinvey Property Mapping"
            operationQueue.maxConcurrentOperationCount = 1
            operationQueue.addOperationWithBlock {
                NSThread.currentThread().threadDictionary[KinveyMappingTypeKey] = [NSStringFromClass(Self.self) : Dictionary<String, String>()]
                self.kinveyPropertyMapping(map)
                originalThread.threadDictionary[KinveyMappingTypeKey] = NSThread.currentThread().threadDictionary[KinveyMappingTypeKey]
            }
            operationQueue.waitUntilAllOperationsAreFinished()
        } else {
            self.kinveyPropertyMapping(map)
        }
    }
    
    mutating func readMap(propertyName: String, cls: AnyClass, map: Map) {
        if let type = cls as? NSObject.Type {
            readMap(propertyName, type: type, map: map)
        }
    }
    
    mutating func readMap<T>(propertyName: String, type: T.Type, map: Map) {
        var value: T?
        value <- map
        self[propertyName] = value as? AnyObject
    }
    
    func writeMap(propertyName: String, cls: AnyClass, map: Map) {
        if let type = cls as? NSObject.Type {
            writeMap(propertyName, type: type, map: map)
        }
    }
    
    func writeMap<T>(propertyName: String, type: T.Type, map: Map) {
        var value = self[propertyName] as? Mappable
        value <- map
    }
    
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
    
    internal var kinveyMetadata: Metadata? {
        get {
            if let kmdKey = Self.kinveyMetadataPropertyName() {
                return self[kmdKey] as? Metadata
            }
            return nil
        }
        set {
            if let kmdKey = Self.kinveyMetadataPropertyName() {
                self[kmdKey] = newValue
            }
        }
    }
    
}
