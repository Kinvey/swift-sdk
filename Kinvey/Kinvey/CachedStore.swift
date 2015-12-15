//
//  CachedStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class CachedStoreExpiration {
    
    public enum Time {
        case Seconds, Minutes, Hours, Days, Months, Years
    }
    
    public let value: UInt
    
    public let time: Time
    
    public init(value: UInt, time: Time) {
        self.value = value
        self.time = time
    }
    
}

public class CachedStore<T: Persistable>: BaseStore<T> {

}
