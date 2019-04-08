//
//  StoreType.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-27.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/// Defines the behavior of a DataStore instance.
public enum StoreType {
    
    /// Ready to work completly offline and synchronize with the server manually calling methods like `pull`, `push`, `sync` (push + pull) and `purge`.
    case sync
    
    /// Callbacks will be called twice, the 1st call will return data from the local cache in the device and the 2nd call will return the most recent data from the backend.
    @available(*, deprecated /* 3.21.0 */, message: "Please use `.auto` instead")
    case cache
    
    /// Guaranteed that all the data returned will be the most recent data from the backend.
    case network
    
    /// Tries to get the most recent data from the backend first, if it fails it returns data from the local cache.
    case auto
    
    var readPolicy: ReadPolicy {
        switch self {
        case .cache:
            return .both
        case .network:
            return .forceNetwork
        case .sync:
            return .forceLocal
        case .auto:
            return .networkOtherwiseLocal
        }
    }
    
    var writePolicy: WritePolicy {
        switch self {
        case .cache, .auto:
            return .localThenNetwork
        case .network:
            return .forceNetwork
        case .sync:
            return .forceLocal
        }
    }
    
}
