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
    static func collectionName() -> String
    
    init()
    
    mutating func propertyMapping(map: Map)
    
}

private func kinveyMappingType(left left: String, right: String) {
    let currentThread = NSThread.currentThread()
    if var kinveyMappingType = currentThread.threadDictionary[KinveyMappingTypeKey] as? [String : [String : String]],
        let className = kinveyMappingType.first?.0,
        var classMapping = kinveyMappingType[className]
    {
        classMapping[left] = right
        kinveyMappingType[className] = classMapping
        currentThread.threadDictionary[KinveyMappingTypeKey] = kinveyMappingType
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

internal let KinveyMappingTypeKey = "Kinvey Mapping Type"

extension Persistable {
    
    static func propertyMappingReverse() -> [String : [String]] {
        var results = [String : [String]]()
        for keyPair in propertyMapping() {
            var properties = results[keyPair.1]
            if properties == nil {
                properties = [String]()
            }
            properties!.append(keyPair.0)
            results[keyPair.1] = properties
        }
        return results
    }
    
    static func propertyMapping() -> [String : String] {
        let currentThread = NSThread.currentThread()
        let className = StringFromClass(self as! AnyClass)
        currentThread.threadDictionary[KinveyMappingTypeKey] = [className : Dictionary<String, String>()]
        let obj = self.init()
        obj.toJSON()
        if let kinveyMappingType = currentThread.threadDictionary[KinveyMappingTypeKey] as? [String : [String : String]],
            let kinveyMappingClassType = kinveyMappingType[className]
        {
            return kinveyMappingClassType
        }
        return [:]
    }
    
    static func propertyMapping(propertyName: String) -> String? {
        return propertyMapping()[propertyName]
    }
    
    internal static func entityIdProperty() -> String {
        return propertyMappingReverse()[PersistableIdKey]!.last!
    }
    
    internal static func aclProperty() -> String? {
        return propertyMappingReverse()[PersistableAclKey]?.last
    }
    
    internal static func metadataProperty() -> String? {
        return propertyMappingReverse()[PersistableMetadataKey]?.last
    }
    
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
    
    internal var entityId: String? {
        get {
            return self[self.dynamicType.entityIdProperty()] as? String
        }
        set {
            self[self.dynamicType.entityIdProperty()] = newValue
        }
    }
    
    internal var acl: Acl? {
        get {
            if let aclKey = self.dynamicType.aclProperty() {
                return self[aclKey] as? Acl
            }
            return nil
        }
        set {
            if let aclKey = self.dynamicType.aclProperty() {
                self[aclKey] = newValue
            }
        }
    }
    
    internal var metadata: Metadata? {
        get {
            if let kmdKey = self.dynamicType.metadataProperty() {
                return self[kmdKey] as? Metadata
            }
            return nil
        }
        set {
            if let kmdKey = self.dynamicType.metadataProperty() {
                self[kmdKey] = newValue
            }
        }
    }
    
}
