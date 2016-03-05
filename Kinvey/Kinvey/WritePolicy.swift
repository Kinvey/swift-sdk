//
//  WritePolicy.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-27.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc
public enum WritePolicy: UInt {
    
    case LocalThenNetwork = 0, ForceLocal, ForceNetwork
    
}
