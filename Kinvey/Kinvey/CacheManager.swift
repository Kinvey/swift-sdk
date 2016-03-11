//
//  CacheManager.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVCacheManager)
public class CacheManager: NSObject {
    
    private let persistenceId: String
    
    init(persistenceId: String) {
        self.persistenceId = persistenceId
    }
    
    public func cache(collectionName: String? = nil) -> Cache {
        return KCSRealmEntityPersistence(persistenceId: persistenceId, collectionName: collectionName) as! Cache
    }
    
}
