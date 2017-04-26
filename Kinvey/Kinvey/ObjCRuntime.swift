//
//  ObjCRuntime.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-05-10.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import ObjectiveC

internal class ObjCRuntime: NSObject {
    
    fileprivate override init() {
    }
    
    internal class func type(_ target: AnyClass, isSubtypeOf cls: AnyClass) -> Bool {
        if target == cls {
            return true
        }
        
        if let superCls = class_getSuperclass(target) {
            return type(superCls, isSubtypeOf: cls)
        }
        return false
    }
    
    internal class func typeForPropertyName(_ cls: AnyClass, propertyName: String) -> AnyClass? {
        let regexClassName = try! NSRegularExpression(pattern: "@\"(\\w+)(?:<(\\w+)>)?\"", options: [])
        
        let property = class_getProperty(cls, propertyName)
        let attributeValueCString = property_copyAttributeValue(property, "T")
        defer { free(attributeValueCString) }
        if let attributeValue = String(validatingUTF8: attributeValueCString!),
            let textCheckingResult = regexClassName.matches(in: attributeValue, options: [], range: NSMakeRange(0, attributeValue.characters.count)).first
        {
            let attributeValueNSString = attributeValue as NSString
            let propertyTypeName = attributeValueNSString.substring(with: textCheckingResult.rangeAt(1))
            return NSClassFromString(propertyTypeName)
        }
        return nil
    }
    
    /// Returns the properties of a class and their types and subtypes, if exists
    internal class func properties(forClass cls: AnyClass) -> [String : (String?, String?)] {
        let regexClassName = try! NSRegularExpression(pattern: "@\"(\\w+)?(?:<(\\w+)>)?\"", options: [])
        var cls: AnyClass? = cls
        var results = [String : (String?, String?)]()
        while cls != nil {
            var propertyCount = UInt32(0)
            guard let properties = class_copyPropertyList(cls, &propertyCount) else { break }
            defer { free(properties) }
            for i in UInt32(0) ..< propertyCount {
                guard let property = properties[Int(i)] else { break }
                if let propertyName = String(validatingUTF8: property_getName(property))
                {
                    var attributeCount = UInt32(0)
                    guard let attributes = property_copyAttributeList(property, &attributeCount) else { break }
                    defer { free(attributes) }
                    for x in UInt32(0) ..< attributeCount {
                        let attribute = attributes[Int(x)]
                        if let attributeName = String(validatingUTF8: attribute.name),
                            attributeName == "T",
                            let attributeValue = String(validatingUTF8: attribute.value),
                            let textCheckingResult = regexClassName.matches(in: attributeValue, range: NSMakeRange(0, attributeValue.characters.count)).first
                        {
                            var tuple: (type: String?, subType: String?) = (nil, nil)
                            if let range = textCheckingResult.rangeAt(1).toRange() {
                                tuple.type = attributeValue.substring(with: range)
                            }
                            
                            if textCheckingResult.numberOfRanges > 1,
                                let range = textCheckingResult.rangeAt(2).toRange() {
                                tuple.subType = attributeValue.substring(with: range)
                            }
                            results[propertyName] = tuple
                        }
                    }
                }
            }
            if cls == Entity.self {
                cls = nil
            } else {
                cls = class_getSuperclass(cls)
            }
        }
        return results
    }
    
}
