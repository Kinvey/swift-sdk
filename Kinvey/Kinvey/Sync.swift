//
//  Sync.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal protocol SyncType {
    
    //Create
    func createPendingOperation(_ request: URLRequest, objectId: String?) -> PendingOperationType
    
    //Read
    func pendingOperations() -> AnyCollection<PendingOperationType>
    
    //Update
    func savePendingOperation(_ pendingOperation: PendingOperationType)
    
    //Delete
    func removePendingOperation(_ pendingOperation: PendingOperationType)
    func removeAllPendingOperations(_ objectId: String?, methods: [String]?)
    
}


internal final class AnySync: SyncType {
    
    private let _createPendingOperation: (URLRequest, String?) -> PendingOperationType
    private let _pendingOperations: () -> AnyCollection<PendingOperationType>
    private let _savePendingOperation: (PendingOperationType) -> Void
    private let _removePendingOperation: (PendingOperationType) -> Void
    private let _removeAllPendingOperations: (String?, [String]?) -> Void
    
    init<Sync: SyncType>(_ sync: Sync) {
        _createPendingOperation = sync.createPendingOperation
        _pendingOperations = sync.pendingOperations
        _savePendingOperation = sync.savePendingOperation
        _removePendingOperation = sync.removePendingOperation
        _removeAllPendingOperations = sync.removeAllPendingOperations
    }
    
    func createPendingOperation(_ request: URLRequest, objectId: String? = nil) -> PendingOperationType {
        return _createPendingOperation(request, objectId)
    }
    
    func pendingOperations() -> AnyCollection<PendingOperationType> {
        return _pendingOperations()
    }
    
    func savePendingOperation(_ pendingOperation: PendingOperationType) {
        _savePendingOperation(pendingOperation)
    }
    
    func removePendingOperation(_ pendingOperation: PendingOperationType) {
        _removePendingOperation(pendingOperation)
    }
    
    func removeAllPendingOperations(_ objectId: String? = nil, methods: [String]? = nil) {
        _removeAllPendingOperations(objectId, methods)
    }
    
}
