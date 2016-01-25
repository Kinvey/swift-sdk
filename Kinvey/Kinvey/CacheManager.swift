//
//  CacheManager.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

class CacheManager {
    
    private let persistenceId: String
    
    class func getInstance(persistenceId: String) -> CacheManager {
        return CacheManager(persistenceId: persistenceId)
    }
    
    init(persistenceId: String) {
        self.persistenceId = persistenceId
    }
    
    func cache(collectionName: String) -> Cache {
        return KCSRealmEntityPersistence(persistenceId: persistenceId, collectionName: collectionName) as! Cache
    }
    
}
