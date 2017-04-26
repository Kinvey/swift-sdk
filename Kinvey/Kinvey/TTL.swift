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
    case second
    
    /// Time unit that represents minutes.
    case minute
    
    /// Time unit that represents hours.
    case hour
    
    /// Time unit that represents days.
    case day
    
    /// Time unit that represents weeks.
    case week
}

extension TimeUnit {
    
    var timeInterval: TimeInterval {
        switch self {
        case .second: return 1
        case .minute: return 60
        case .hour: return 60 * TimeUnit.minute.timeInterval
        case .day: return 24 * TimeUnit.hour.timeInterval
        case .week: return 7 * TimeUnit.day.timeInterval
        }
    }
    
    func toTimeInterval(_ value: Int) -> TimeInterval {
        return TimeInterval(value) * timeInterval
    }
    
}

public typealias TTL = (Int, TimeUnit)

extension Int {
    
    internal var seconds: TTL { return TTL(self, .second) }
    internal var minutes: TTL { return TTL(self, .minute) }
    internal var hours: TTL { return TTL(self, .hour) }
    internal var days: TTL { return TTL(self, .day) }
    internal var weeks: TTL { return TTL(self, .week) }
    
}
