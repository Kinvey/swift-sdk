//
//  CachedStoreExpiration.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-13.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

public enum TimeUnit {
    case Second
    case Minute
    case Hour
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
    
    public var seconds: TTL { return TTL(self, .Second) }
    public var minutes: TTL { return TTL(self, .Minute) }
    public var hours: TTL { return TTL(self, .Hour) }
    public var days: TTL { return TTL(self, .Day) }
    
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
