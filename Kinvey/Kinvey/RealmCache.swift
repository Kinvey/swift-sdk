//
//  RealmCache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-06-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class RealmCache<T: Persistable where T: NSObject>: Cache<T>, Sync {
    
    required init(persistenceId: String) {
        super.init(persistenceId: persistenceId)
    }
    
    func createPendingOperation(request: NSURLRequest!, objectId: String?) -> PendingOperation {
        return RealmPendingOperation(objectId: objectId)
    }
    
    func savePendingOperation(pendingOperation: PendingOperation) {
        
    }
    
    func pendingOperations() -> [PendingOperation] {
        return []
    }
    
    func pendingOperations(objectId: String?) -> [PendingOperation] {
        return []
    }
    
    func removePendingOperation(pendingOperation: PendingOperation) {
        
    }
    
    func removeAllPendingOperations() {
        
    }
    
    func removeAllPendingOperations(objectId: String?) {
        
    }
    
}

internal class RealmPendingOperation: PendingOperation {
    
    let objectId: String?
    
    init(objectId: String?) {
        self.objectId = objectId
    }
    
    func buildRequest() -> NSMutableURLRequest {
        return NSMutableURLRequest()
    }
    
}
