//
//  StoreType.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-27.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

public enum StoreType {
    
    case Sync, Cache, Network
    
    var readPolicy: ReadPolicy {
        get {
            switch self {
            case .Cache:
                return .Both
            case .Network:
                return .ForceNetwork
            case .Sync:
                return .ForceLocal
            }
        }
    }
    
    var writePolicy: WritePolicy {
        get {
            switch self {
            case .Cache:
                return .LocalThenNetwork
            case .Network:
                return .ForceNetwork
            case .Sync:
                return .ForceLocal
            }
        }
    }
    
}
