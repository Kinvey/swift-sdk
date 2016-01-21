//
//  CacheManager.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

class CacheManager: KCSCacheManager {
    
    internal func cache(collectionName: String) -> Cache {
        return super.cache(collectionName) as! Cache
    }
    
}
