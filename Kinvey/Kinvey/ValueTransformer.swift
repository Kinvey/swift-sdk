//
//  ValueTransformer.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import ObjectiveC

protocol NSValueTransformerReverse {
    
    static func reverseTransformedValueClass() -> AnyClass
    
    func transformedValue(value: AnyObject?) -> AnyObject?
    func reverseTransformedValue(value: AnyObject?) -> AnyObject?
    func transformValue<T>(value: AnyObject?, destinationType: T.Type) -> T?
    
}

extension NSValueTransformerReverse where Self: NSValueTransformer {
    
    func isReverse() -> Bool {
        return false
    }
    
    static func allowsReverseTransformation() -> Bool {
        return true
    }
    
    func transformValue<T>(value: AnyObject?, destinationType: T.Type) -> T? {
        let valueTransformer = (self as NSValueTransformer)
        return valueTransformer.dynamicType.transformedValueClass() == destinationType ? valueTransformer.transformedValue(value) as? T : valueTransformer.reverseTransformedValue(value) as? T
    }
    
}

class ValueTransformer: NSValueTransformer {
    
    private static let separator = "->"
    private static var classTransformer = [String : NSValueTransformerReverse]()
    private static var reverseClassTransformer = [String : NSValueTransformerReverse]()
    
    private class func valueTransformerName(fromClass fromClass: String, toClass: String) -> String {
        return "\(fromClass)\(separator)\(toClass)"
    }
    
    class func setValueTransformer<T: NSValueTransformer where T: NSValueTransformerReverse>(transformer: T) {
        let transformedValueClass = NSStringFromClass(T.transformedValueClass())
        let reverseTransformedValueClass = NSStringFromClass(T.reverseTransformedValueClass())
        self.classTransformer[valueTransformerName(fromClass: transformedValueClass, toClass: reverseTransformedValueClass)] = transformer
        self.reverseClassTransformer[valueTransformerName(fromClass: reverseTransformedValueClass, toClass: transformedValueClass)] = transformer
        setValueTransformer(transformer, forName: NSStringFromClass(transformer.dynamicType.self))
    }
    
    class func valueTransformer(fromClass fromClass: AnyClass, toClass: AnyClass) -> NSValueTransformerReverse? {
        var fromClass = NSStringFromClass(fromClass)
        let toClass = NSStringFromClass(toClass)
        var valueTransformer: NSValueTransformerReverse?
        repeat {
            valueTransformer = classTransformer[valueTransformerName(fromClass: fromClass, toClass: toClass)] ?? reverseClassTransformer[valueTransformerName(fromClass: fromClass, toClass: toClass)]
            if let cls = NSClassFromString(fromClass), let superClass = class_getSuperclass(cls) {
                fromClass = NSStringFromClass(superClass)
            } else {
                break
            }
        } while (valueTransformer == nil)
        return valueTransformer
    }
    
}
