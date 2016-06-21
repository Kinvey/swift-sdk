//
//  Sync.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal protocol SyncType {
    
    associatedtype PendingOperation: PendingOperationType
    
    var persistenceId: String { get }
    var collectionName: String { get }
    
    init(persistenceId: String)
    
    func createPendingOperation(request: NSURLRequest, objectId: String?) -> PendingOperation
    func savePendingOperation(pendingOperation: PendingOperation
    )
    
    func pendingOperations() -> Results<PendingOperationIMP>
    func pendingOperations(objectId: String?) -> Results<PendingOperationIMP>
    
    func removePendingOperation(pendingOperation: PendingOperation)
    
    func removeAllPendingOperations()
    func removeAllPendingOperations(objectId: String?)
    
}

internal class Sync<T: Persistable where T: NSObject>: SyncType {
    
    let collectionName: String
    let persistenceId: String
    
    required init(persistenceId: String) {
        self.collectionName = T.kinveyCollectionName()
        self.persistenceId = persistenceId
    }
    
    func createPendingOperation(request: NSURLRequest, objectId: String?) -> PendingOperationIMP {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func savePendingOperation(pendingOperation: PendingOperationIMP) {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func pendingOperations() -> Results<PendingOperationIMP> {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func pendingOperations(objectId: String?) -> Results<PendingOperationIMP> {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func removePendingOperation(pendingOperation: PendingOperationIMP) {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func removeAllPendingOperations() {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func removeAllPendingOperations(objectId: String?) {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
}
