//
//  CachedStoreExpiration.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-13.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

public typealias Expiration = (Int, CachedStoreExpiration.Time)

public enum CachedStoreExpiration {
    
    public enum Time {
        case Second
        case Minute
        case Hour
        case Day
        case Month
        case Year
    }
    
    case Second(Int)
    case Minute(Int)
    case Hour(Int)
    case Day(Int)
    case Month(Int)
    case Year(Int)
    
    func date(calendar: NSCalendar) -> NSDate {
        let dateComponents = NSDateComponents()
        switch self {
        case .Second(let value):
            dateComponents.day = -value
        case .Minute(let value):
            dateComponents.minute = -value
        case .Hour(let value):
            dateComponents.hour = -value
        case .Day(let value):
            dateComponents.day = -value
        case .Month(let value):
            dateComponents.month = -value
        case .Year(let value):
            dateComponents.year = -value
        }
        let newDate = calendar.dateByAddingComponents(dateComponents, toDate: NSDate(), options: [])
        return newDate!
    }
}
