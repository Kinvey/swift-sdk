//
//  NSDate2StringValueConverter.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class NSDate2StringValueTransformer: NSValueTransformer, NSValueTransformerReverse {
    
    static let rfc3339DateFormatter: NSDateFormatter = {
        let rfc3339DateFormatter = NSDateFormatter()
        rfc3339DateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        rfc3339DateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        rfc3339DateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        return rfc3339DateFormatter
    }()
    
    static let rfc3339MilliSecondsDateFormatter: NSDateFormatter = {
        let rfc3339DateFormatter = NSDateFormatter()
        rfc3339DateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        rfc3339DateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"
        rfc3339DateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        return rfc3339DateFormatter
    }()
    
    override class func transformedValueClass() -> AnyClass {
        return NSString.self
    }
    
    static func reverseTransformedValueClass() -> AnyClass {
        return NSDate.self
    }
    
    override func transformedValue(value: AnyObject?) -> AnyObject? {
        guard let date = value as? NSDate else { return nil }
        return date.toString()
    }
    
    override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
        guard let string = value as? String else { return nil }
        return string.toDate()
    }
    
}
