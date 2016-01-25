//
//  SyncManager.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

public class SyncManager {
    
    private let persistenceId: String
    
    init(persistenceId: String) {
        self.persistenceId = persistenceId
    }
    
    func sync(collectionName: String) -> Sync {
        return KCSRealmEntityPersistence(persistenceId: persistenceId, collectionName: collectionName) as! Sync
    }
    
}
