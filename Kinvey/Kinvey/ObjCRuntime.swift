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
        guard let property = class_getProperty(cls, propertyName) else {
            return nil
        }
        let attributeValueCString = property_copyAttributeValue(property, "T")
        defer { free(attributeValueCString) }
        if let attributeValueCString = attributeValueCString,
            let attributeValue = String(validatingUTF8: attributeValueCString),
            let regexClassName = try? NSRegularExpression(pattern: "@\"(\\w+)(?:<(\\w+)>)?\""),
            let textCheckingResult = regexClassName.matches(in: attributeValue, range: NSRange(location: 0, length: attributeValue.count)).first
        {
            let attributeValueNSString = attributeValue as NSString
            let propertyTypeName = attributeValueNSString.substring(with: textCheckingResult.range(at: 1))
            return NSClassFromString(propertyTypeName)
        }
        return nil
    }
    
    static let regexClassName = try! NSRegularExpression(pattern: "@\"(\\w+)?(?:<(\\w+)>)?\"")
    
    private class func attribute(attribute: objc_property_attribute_t, propertyName: String, results: inout [String : (String?, String?)]) {
        guard let attributeName = String(validatingUTF8: attribute.name),
            attributeName == "T",
            let attributeValue = String(validatingUTF8: attribute.value),
            let textCheckingResult = regexClassName.matches(in: attributeValue, range: NSRange(location: 0, length: attributeValue.count)).first
            else {
                return
        }
        var tuple: (type: String?, subType: String?) = (nil, nil)
        if let range = Range(textCheckingResult.range(at: 1)) {
            tuple.type = attributeValue.substring(with: range)
        }
        
        if textCheckingResult.numberOfRanges > 1,
            let range = Range(textCheckingResult.range(at: 2)) {
            tuple.subType = attributeValue.substring(with: range)
        }
        results[propertyName] = tuple
    }
    
    private class func attributes(property: objc_property_t, results: inout [String : (String?, String?)]) {
        guard let propertyName = String(validatingUTF8: property_getName(property)) else {
            return
        }
        var attributeCount = UInt32(0)
        guard let attributes = property_copyAttributeList(property, &attributeCount) else {
            return
        }
        defer { free(attributes) }
        for x in 0 ..< Int(attributeCount) {
            attribute(attribute: attributes[x], propertyName: propertyName, results: &results)
        }
    }
    
    /// Returns the properties of a class and their types and subtypes, if exists
    internal class func properties(forClass cls: AnyClass) -> [String : (String?, String?)] {
        var cls: AnyClass? = cls
        var results = [String : (String?, String?)]()
        var propertyCount = UInt32(0)
        while cls != nil {
            if let properties = class_copyPropertyList(cls, &propertyCount) {
                defer { free(properties) }
                for i in 0 ..< Int(propertyCount) {
                    attributes(property: properties[i], results: &results)
                }
                if cls == Entity.self {
                    cls = nil
                } else {
                    cls = class_getSuperclass(cls)
                }
            } else {
                cls = class_getSuperclass(cls)
            }
        }
        return results
    }
    
}
