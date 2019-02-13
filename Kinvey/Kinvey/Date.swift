//
//  NSDate.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

extension Date {
    
    static let dateWriteFormatter: DateFormatter = {
        let wFormatter = DateFormatter()
        wFormatter.locale = Locale(identifier: "en_US_POSIX")
        wFormatter.timeZone = TimeZone(identifier: "UTC")
        wFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return wFormatter
    }()

    public func toISO8601() -> String {
        return Date.dateWriteFormatter.string(from: self)
    }
    
}
