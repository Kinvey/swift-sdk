//
//  RealmCache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-06-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift

internal class RealmCache<T: Persistable where T: NSObject>: Cache<T>, Sync {
    
    let realm: Realm
    let operationQueue: NSOperationQueue
    
    required init(persistenceId: String) {
        if !(T.self is Entity.Type) {
            preconditionFailure("\(T.self) needs to be a Entity")
        }
        realm = try! Realm()
        operationQueue = NSOperationQueue.currentQueue()!
        print("\(realm.configuration.fileURL!.path!)")
        super.init(persistenceId: persistenceId)
    }
    
    override func saveEntity(entity: T) {
        operationQueue.addOperationWithBlock {
            try! self.realm.write {
                self.realm.add(entity as! Entity)
            }
        }
        operationQueue.waitUntilAllOperationsAreFinished()
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
