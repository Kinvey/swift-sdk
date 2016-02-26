//
//  CacheManager.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

public class CacheManager {
    
    private let persistenceId: String
    
    init(persistenceId: String) {
        self.persistenceId = persistenceId
    }
    
    func cache(collectionName: String? = nil) -> Cache {
        let cache = KCSRealmEntityPersistence(persistenceId: persistenceId, collectionName: collectionName)
        return CacheAdapter(cache: cache)
    }
    
}
