//
//  KinveyDateTransform.swift
//  Kinvey
//
//  Created by Tejas on 11/11/16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import ObjectMapper


class KinveyDateTransform : TransformType {
    
    public typealias Object = Date
    public typealias JSON = String
    
    let dateReadFormatter: DateFormatter
    let dateWriteFormatter: DateFormatter
    
    public init() {
        //read formatter that accounts for the timezone
        let rFormatter = DateFormatter()
        rFormatter.locale = Locale(identifier: "en_US_POSIX")
        rFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        self.dateReadFormatter = rFormatter
        
        //write formatter for UTC
        let wFormatter = DateFormatter()
        wFormatter.locale = Locale(identifier: "en_US_POSIX")
        wFormatter.timeZone = TimeZone(identifier: "UTC")
        wFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        
        self.dateWriteFormatter = wFormatter
    }
    
    open func transformFromJSON(_ value: Any?) -> Date? {
        if let dateString = value as? String {
            
            //Extract the matching date for the following types of strings
            //yyyy-MM-dd'T'HH:mm:ss.SSS'Z' -> default date string written by this transform
            //yyyy-MM-dd'T'HH:mm:ss.SSS+ZZZZ -> date with time offset (e.g. +0400, -0500)
            //ISODate("yyyy-MM-dd'T'HH:mm:ss.SSSZ") -> backward compatible with Kinvey 1.x
            
            let match = matches(for: "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(.\\d{3})?(([+-]\\d{4})|Z)", in: dateString)
            if match.count > 0 {
                let matchedDate = dateReadFormatter.date(from: match[0])
                return matchedDate
            }
        }
        return nil
    }
    
    open func transformToJSON(_ value: Date?) -> String? {
        if let date = value {
            return dateWriteFormatter.string(from: date)
        }
        return nil
    }
    
    fileprivate func matches(for regex: String, in text: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
}
