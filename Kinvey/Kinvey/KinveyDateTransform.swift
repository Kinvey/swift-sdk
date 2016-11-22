//
//  KinveyDateTransform.swift
//  Kinvey
//
//  Created by Tejas on 11/11/16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation


public class KinveyDateTransform : TransformType {
    
    public typealias Object = NSDate
    public typealias JSON = String
    
    //read formatter that accounts for the timezone
    lazy var dateReadFormatter: NSDateFormatter = {
        let rFormatter = NSDateFormatter()
        rFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        rFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return rFormatter
    }()
    
    //read formatter that accounts for the timezone
    lazy var dateReadFormatterWithoutMilliseconds: NSDateFormatter = {
        let rFormatter = NSDateFormatter()
        rFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        rFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return rFormatter
    }()
    
    //write formatter for UTC
    lazy var dateWriteFormatter: NSDateFormatter = {
        let wFormatter = NSDateFormatter()
        wFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        wFormatter.timeZone = NSTimeZone(name: "UTC")
        wFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return wFormatter
    }()
    
    public func transformFromJSON(value: AnyObject?) -> NSDate? {
        if let dateString = value as? String {
            
            //Extract the matching date for the following types of strings
            //yyyy-MM-dd'T'HH:mm:ss.SSS'Z' -> default date string written by this transform
            //yyyy-MM-dd'T'HH:mm:ss.SSS+ZZZZ -> date with time offset (e.g. +0400, -0500)
            //ISODate("yyyy-MM-dd'T'HH:mm:ss.SSSZ") -> backward compatible with Kinvey 1.x
            
            let matches = self.matches(for: "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(.\\d{3})?([+-]\\d{4}|Z)", in: dateString)
            if let match = matches.first {
                if match.milliseconds != nil {
                    return dateReadFormatter.dateFromString(match.match)
                } else {
                    return dateReadFormatterWithoutMilliseconds.dateFromString(match.match)
                }
            }
        }
        return nil
    }
    
    public func transformToJSON(value: NSDate?) -> String? {
        if let date = value {
            return dateWriteFormatter.stringFromDate(date)
        }
        return nil
    }
    
    typealias TextCheckingResultTuple = (match: String, milliseconds: String?, timezone: String)
    
    private func matches(for regex: String, in text: String) -> [TextCheckingResultTuple] {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let results = regex.matchesInString(text, options: [], range: NSRange(location: 0, length: nsString.length))
            return results.map {
                TextCheckingResultTuple(
                    match: nsString.substringWithRange($0.rangeAtIndex(0)),
                    milliseconds: $0.rangeAtIndex(1).location != NSNotFound ? nsString.substringWithRange($0.rangeAtIndex(1)) : nil,
                    timezone: nsString.substringWithRange($0.rangeAtIndex(2))
                )
            }
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
}
