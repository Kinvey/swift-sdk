//
//  WritePolicy.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-27.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/// Policy that describes how a write operation should perform.
public enum WritePolicy {
    
    /// Writes in the local cache first and then try to write trought the network (backend).
    case localThenNetwork
    
    /// Writes in the local cache first but does not call the callback and then try to write trought the network (backend).
    case silentLocalThenNetwork
    
    /// Doesn't hit the network, forcing to write the data only in the local cache.
    case forceLocal
    
    /// Doesn't hit the local cache, forcing to write the data only trought the network (backend).
    case forceNetwork
    
}
