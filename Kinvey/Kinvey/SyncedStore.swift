//
//  SyncedStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

class SyncedStore<T: Persistable>: CachedBaseStore<T> {
    
    internal init(client: Client) {
        super.init(client: client)
    }
    
    internal override var expirationDate: NSDate {
        get {
            return NSDate.distantFuture()
        }
    }
    
    func initialize(query: Query) {
    }
    
    func push() {
    }
    
    func sync(query: Query) {
    }
    
    func purge() {
    }

}
