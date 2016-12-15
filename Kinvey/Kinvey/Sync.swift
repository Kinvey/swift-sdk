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
    
    func createPendingOperation(_ request: URLRequest, objectId: String?) -> PendingOperation
    func savePendingOperation(_ pendingOperation: PendingOperation
    )
    
    func pendingOperations() -> Results<PendingOperationIMP>
    func pendingOperations(_ objectId: String?) -> Results<PendingOperationIMP>
    
    func removePendingOperation(_ pendingOperation: PendingOperation)
    
    func removeAllPendingOperations()
    func removeAllPendingOperations(_ objectId: String?)
    func removeAllPendingOperations(_ objectId: String?, methods: [String]?)
    
}

internal class Sync<T: Persistable>: SyncType where T: NSObject {
    
    let collectionName: String
    let persistenceId: String
    
    required init(persistenceId: String) {
        self.collectionName = T.collectionName()
        self.persistenceId = persistenceId
    }
    
    func createPendingOperation(_ request: URLRequest, objectId: String?) -> PendingOperationIMP {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    func savePendingOperation(_ pendingOperation: PendingOperationIMP) {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    func pendingOperations() -> Results<PendingOperationIMP> {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    func pendingOperations(_ objectId: String?) -> Results<PendingOperationIMP> {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    func removePendingOperation(_ pendingOperation: PendingOperationIMP) {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    func removeAllPendingOperations() {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    func removeAllPendingOperations(_ objectId: String?) {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    func removeAllPendingOperations(_ objectId: String?, methods: [String]?) {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
}
