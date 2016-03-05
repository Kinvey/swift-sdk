//
//  ReadPolicy.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-21.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc
public enum ReadPolicy: UInt {
    
    case ForceLocal = 0, ForceNetwork, Both
    
}
