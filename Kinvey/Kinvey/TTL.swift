//
//  CachedStoreExpiration.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-13.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/// Describes a unit to be used in a time perspective.
public enum TimeUnit {
    
    /// Time unit that represents seconds.
    case Second
    
    /// Time unit that represents minutes.
    case Minute
    
    /// Time unit that represents hours.
    case Hour
    
    /// Time unit that represents days.
    case Day
}

extension TimeUnit {
    
    var timeInterval: NSTimeInterval {
        switch self {
        case .Second: return 1
        case .Minute: return 60
        case .Hour: return 60 * Minute.timeInterval
        case .Day: return 24 * Hour.timeInterval
        }
    }
    
    func toTimeInterval(value: Int) -> NSTimeInterval {
        return NSTimeInterval(value) * timeInterval
    }
    
}

public typealias TTL = (Int, TimeUnit)

extension Int {
    
    internal var seconds: TTL { return TTL(self, .Second) }
    internal var minutes: TTL { return TTL(self, .Minute) }
    internal var hours: TTL { return TTL(self, .Hour) }
    internal var days: TTL { return TTL(self, .Day) }
    
    var secondsDate : NSDate { return date(.Second) }
    var minutesDate : NSDate { return date(.Minute) }
    var hoursDate   : NSDate { return date(.Hour) }
    var daysDate    : NSDate { return date(.Day) }
    
    internal func date(timeUnit: TimeUnit, calendar: NSCalendar = NSCalendar.currentCalendar()) -> NSDate {
        let dateComponents = NSDateComponents()
        switch timeUnit {
        case .Second:
            dateComponents.day = -self
        case .Minute:
            dateComponents.minute = -self
        case .Hour:
            dateComponents.hour = -self
        case .Day:
            dateComponents.day = -self
        }
        let newDate = calendar.dateByAddingComponents(dateComponents, toDate: NSDate(), options: [])
        return newDate!
    }
    
}
