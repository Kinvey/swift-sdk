//
//  String.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

fileprivate class DateFormatters {
    
    lazy var rfc3339DateFormatter: DateFormatter = {
        let rfc3339DateFormatter = DateFormatter()
        rfc3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        rfc3339DateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        rfc3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return rfc3339DateFormatter
    }()
    
    lazy var rfc3339MilliSecondsDateFormatter: DateFormatter = {
        let rfc3339DateFormatter = DateFormatter()
        rfc3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        rfc3339DateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"
        rfc3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return rfc3339DateFormatter
    }()
    
}

fileprivate let dateFormatters = DateFormatters()

extension String {
    
    /// Converts a `String` to `Date`, if possible
    public func toDate() -> Date? {
        switch self.characters.count {
            case 20:
                return dateFormatters.rfc3339DateFormatter.date(from: self)
            case 24:
                return dateFormatters.rfc3339MilliSecondsDateFormatter.date(from: self)
            default:
                return nil
        }
    }
    
    func substring(with rangeInt: Range<Int>) -> String {
        let startIndex = index(self.startIndex, offsetBy: rangeInt.lowerBound)
        let endIndex = index(self.startIndex, offsetBy: rangeInt.upperBound)
        return String(self[startIndex..<endIndex])
    }
    
    func substring(with range: NSRange) -> String {
        return substring(with: range.location ..< range.location + range.length)
    }
    
}
