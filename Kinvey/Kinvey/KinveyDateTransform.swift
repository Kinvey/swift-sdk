//
//  KinveyDateTransform.swift
//  Kinvey
//
//  Created by Tejas on 11/11/16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import ObjectMapper

/// Default TransformType for `Date` types
open class KinveyDateTransform : TransformType {
    
    public typealias Object = Date
    public typealias JSON = String
    
    /// Default Constructor
    public init() {}
    
    //read formatter that accounts for the timezone
    lazy var dateReadFormatter: DateFormatter = {
        let rFormatter = DateFormatter()
        rFormatter.locale = Locale(identifier: "en_US_POSIX")
        rFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return rFormatter
    }()
    
    //read formatter that accounts for the timezone
    lazy var dateReadFormatterWithoutMilliseconds: DateFormatter = {
        let rFormatter = DateFormatter()
        rFormatter.locale = Locale(identifier: "en_US_POSIX")
        rFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return rFormatter
    }()
    
    //write formatter for UTC
    lazy var dateWriteFormatter: DateFormatter = {
        let wFormatter = DateFormatter()
        wFormatter.locale = Locale(identifier: "en_US_POSIX")
        wFormatter.timeZone = TimeZone(identifier: "UTC")
        wFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return wFormatter
    }()
    
    /// Converts any value to `Date`, if possible
    open func transformFromJSON(_ value: Any?) -> Date? {
        if let dateString = value as? String {
            
            //Extract the matching date for the following types of strings
            //yyyy-MM-dd'T'HH:mm:ss.SSS'Z' -> default date string written by this transform
            //yyyy-MM-dd'T'HH:mm:ss.SSS+ZZZZ -> date with time offset (e.g. +0400, -0500)
            //ISODate("yyyy-MM-dd'T'HH:mm:ss.SSSZ") -> backward compatible with Kinvey 1.x
            
            let matches = self.matches(for: "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(.\\d{3})?([+-]\\d{4}|Z)", in: dateString)
            if let match = matches.first {
                if match.milliseconds != nil {
                    return dateReadFormatter.date(from: match.match)
                } else {
                    return dateReadFormatterWithoutMilliseconds.date(from: match.match)
                }
            }
        }
        return nil
    }
    
    /// Converts any `Date` to `String`, if possible
    open func transformToJSON(_ value: Date?) -> String? {
        if let date = value {
            return dateWriteFormatter.string(from: date)
        }
        return nil
    }
    
    typealias TextCheckingResultTuple = (match: String, milliseconds: String?, timezone: String)
    
    fileprivate func matches(for regex: String, in text: String) -> [TextCheckingResultTuple] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map {
                TextCheckingResultTuple(
                    match: nsString.substring(with: $0.range),
                    milliseconds: $0.range(at: 1).location != NSNotFound ? nsString.substring(with: $0.range(at: 1)) : nil,
                    timezone: nsString.substring(with: $0.range(at: 2))
                )
            }
        } catch let error {
            log.error("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
}
