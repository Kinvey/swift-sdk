//
//  EntitySchema.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import ObjectiveC

@objc(KNVEntitySchema)
internal class EntitySchema: NSObject {
    
    static var entitySchemas = [String : EntitySchema]()
    
    internal let persistableType: Persistable.Type
    internal let persistableClass: AnyClass
    internal let collectionName: String
    
    internal typealias ClassType = (name: (main: String, sub: String?), type: (main: AnyClass, sub: AnyClass?))
    internal typealias Type = (encoding: String, classType: ClassType?)
    internal let properties: [String : Type]
    
    class func entitySchema<T: Persistable>(type: T.Type) -> EntitySchema? {
        return entitySchemas[NSStringFromClass(type)]
    }
    
    internal class func entitySchema(type: AnyClass) -> EntitySchema? {
        return entitySchemas[NSStringFromClass(type)]
    }
    
    internal class func isTypeSupported(obj: AnyObject) -> Bool {
        return obj is NSString ||
            obj is NSNumber ||
            obj is NSArray ||
            obj is NSDictionary ||
            obj is NSNull
    }
    
    class func scanForPersistableEntities() {
        var classCount = UInt32(0)
        let classList = objc_copyClassList(&classCount)
        for i in UInt32(0) ..< classCount {
            if let aClass = classList[Int(i)] as AnyClass? where class_conformsToProtocol(aClass, Persistable.self),
                let cls = aClass as? Persistable.Type
            {
                entitySchemas[NSStringFromClass(aClass)] = EntitySchema(persistableType: cls, persistableClass: aClass, collectionName: cls.kinveyCollectionName(), properties: getProperties(aClass))
            }
        }
    }
    
    private class func getProperties(cls: AnyClass) -> [String : Type] {
        let regexClassName = try! NSRegularExpression(pattern: "@\"(\\w+)(?:<(\\w+)>)?\"", options: [])
        var propertyCount = UInt32(0)
        let properties = class_copyPropertyList(cls, &propertyCount)
        defer { free(properties) }
        var map = [String : Type]()
        for i in UInt32(0) ..< propertyCount {
            let property = properties[Int(i)]
            if let propertyName = String.fromCString(property_getName(property)) {
                var attributeCount = UInt32(0)
                let attributes = property_copyAttributeList(property, &attributeCount)
                defer { free(attributes) }
                attributeLoop : for x in UInt32(0) ..< attributeCount {
                    let attribute = attributes[Int(x)]
                    if let attributeName = String.fromCString(attribute.name) where attributeName == "T",
                        let attributeValue = String.fromCString(attribute.value)
                    {
                        if let textCheckingResult = regexClassName.matchesInString(attributeValue, options: [], range: NSMakeRange(0, attributeValue.characters.count)).first {
                            let attributeValueNSString = attributeValue as NSString
                            let propertyTypeName = attributeValueNSString.substringWithRange(textCheckingResult.rangeAtIndex(1))
                            let propertySubTypeName: String?
                            if textCheckingResult.numberOfRanges > 2 {
                                let range = textCheckingResult.rangeAtIndex(2)
                                propertySubTypeName = range.location != NSNotFound ? attributeValueNSString.substringWithRange(range) : nil
                            } else {
                                propertySubTypeName = nil
                            }
                            let anyClassType: AnyClass = NSClassFromString(propertyTypeName)!
                            let anyClassSubType: AnyClass? = propertySubTypeName != nil ? NSClassFromString(propertySubTypeName!) : nil
                            map[propertyName] = (
                                encoding: attributeValue,
                                classType: (
                                    name: (main: propertyTypeName, sub: propertySubTypeName),
                                    type: (main: anyClassType, sub: anyClassSubType)
                                )
                            )
                        } else {
                            map[propertyName] = (
                                encoding: attributeValue,
                                classType: nil
                            )
                        }
                        break attributeLoop
                    }
                }
            }
        }
        return map
    }
    
    init(persistableType: Persistable.Type, persistableClass: AnyClass, collectionName: String, properties: [String : Type]) {
        self.persistableType = persistableType
        self.persistableClass = persistableClass
        self.collectionName = collectionName
        self.properties = properties
    }
    
}

@objc(KNVRealmEntitySchema)
internal class RealmEntitySchema: NSObject {
    
    internal class func realmClassNameForClass(cls: AnyClass) -> String {
        let className = NSStringFromClass(cls)
        let classNameComponents = className.componentsSeparatedByString(".")
        return classNameComponents.count > 1 ? "\(classNameComponents[0])_K\(classNameComponents[1])" : "K\(className)"
    }
    
}
