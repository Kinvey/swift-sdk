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
    private let encryptionKey: NSData?
    
    init(persistenceId: String, encryptionKey: NSData? = nil) {
        self.persistenceId = persistenceId
        self.encryptionKey = encryptionKey
    }
    
    func sync(collectionName: String, filePath: String? = nil) -> Sync {
        return KCSRealmEntityPersistence(persistenceId: persistenceId, collectionName: collectionName, filePath: filePath, encryptionKey: encryptionKey) as! Sync
    }
    
}
