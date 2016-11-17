//
//  KinveyDateTransform.swift
//  Kinvey
//
//  Created by Tejas on 11/11/16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import ObjectMapper


public class KinveyDateTransform : TransformType {
    
    public typealias Object = NSDate
    public typealias JSON = String
    
    let dateReadFormatter: NSDateFormatter
    let dateWriteFormatter: NSDateFormatter
    
    public init() {
        //read formatter that accounts for the timezone
        let rFormatter = NSDateFormatter()
        rFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        rFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        self.dateReadFormatter = rFormatter
        
        //write formatter for UTC
        let wFormatter = NSDateFormatter()
        wFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        wFormatter.timeZone = NSTimeZone(name: "UTC")
        wFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        
        self.dateWriteFormatter = wFormatter
    }
    
    public func transformFromJSON(value: AnyObject?) -> NSDate? {
        if let dateString = value as? String {
            
            //Extract the matching date for the following types of strings
            //yyyy-MM-dd'T'HH:mm:ss.SSS'Z' -> default date string written by this transform
            //yyyy-MM-dd'T'HH:mm:ss.SSS+ZZZZ -> date with time offset (e.g. +0400, -0500)
            //ISODate("yyyy-MM-dd'T'HH:mm:ss.SSSZ") -> backward compatible with Kinvey 1.x
            
            let match = matches(for: "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(.\\d{3})?(([+-]\\d{4})|Z)", in: dateString)
            if match.count > 0 {
                let matchedDate = dateReadFormatter.dateFromString(match[0])
                return matchedDate
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
    
    private func matches(for regex: String, in text: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let results = regex.matchesInString(text, options: [], range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substringWithRange($0.range) }
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
}
