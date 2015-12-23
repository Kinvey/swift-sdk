//
//  CachedStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

public enum CachedStoreExpiration {
    
    enum Time {
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
                dateComponents.day = value
            case .Minute(let value):
                dateComponents.minute = value
            case .Hour(let value):
                dateComponents.hour = value
            case .Day(let value):
                dateComponents.day = value
            case .Month(let value):
                dateComponents.month = value
            case .Year(let value):
                dateComponents.year = value
        }
        let newDate = calendar.dateByAddingComponents(dateComponents, toDate: NSDate(), options: [])
        return newDate!
    }
}

class CachedStore<T: Persistable>: CachedBaseStore<T> {
    
    let expiration: CachedStoreExpiration
    let calendar: NSCalendar
    
    typealias Expiration = (Int, CachedStoreExpiration.Time)
    
    internal convenience init(expiration: Expiration, calendar: NSCalendar = NSCalendar.currentCalendar(), client: Client = Kinvey.sharedClient()) {
        var _expiration: CachedStoreExpiration
        switch expiration.1 {
            case .Second:
                _expiration = CachedStoreExpiration.Second(expiration.0)
            case .Minute:
                _expiration = CachedStoreExpiration.Minute(expiration.0)
            case .Hour:
                _expiration = CachedStoreExpiration.Hour(expiration.0)
            case .Day:
                _expiration = CachedStoreExpiration.Day(expiration.0)
            case .Month:
                _expiration = CachedStoreExpiration.Month(expiration.0)
            case .Year:
                _expiration = CachedStoreExpiration.Year(expiration.0)
        }
        self.init(expiration: _expiration, client: client)
    }
    
    internal init(expiration: CachedStoreExpiration, calendar: NSCalendar = NSCalendar.currentCalendar(), client: Client = Kinvey.sharedClient()) {
        self.expiration = expiration
        self.calendar = calendar
        super.init(client: client)
    }
    
    internal override var expirationDate: NSDate {
        get {
            return expiration.date(calendar)
        }
    }

}
