//
//  SyncManager.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

class SyncManager: KCSSyncManager {
    
    internal func sync(collectionName: String) -> Sync {
        return super.sync(collectionName) as! Sync
    }
    
}
