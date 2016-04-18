//
//  SyncManager.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVSyncManager)
internal class SyncManager: NSObject {
    
    private let persistenceId: String
    
    init(persistenceId: String) {
        self.persistenceId = persistenceId
    }
    
    func sync(collectionName: String, filePath: String? = nil) -> Sync {
        return KCSRealmEntityPersistence(persistenceId: persistenceId, collectionName: collectionName, filePath: filePath) as! Sync
    }
    
}
