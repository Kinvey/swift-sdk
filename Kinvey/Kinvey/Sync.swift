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
    func createPendingOperation(_ request: URLRequest, objectId: String?) -> PendingOperation
    
    //Read
    func pendingOperations() -> AnyRandomAccessCollection<PendingOperation>
    
    //Update
    func savePendingOperation(_ pendingOperation: PendingOperation)
    
    //Delete
    func removePendingOperation(_ pendingOperation: PendingOperation)
    func removeAllPendingOperations(_ objectId: String?, methods: [String]?) -> Int
    
}

internal final class AnySync: SyncType {
    
    private let _createPendingOperation: (URLRequest, String?) -> PendingOperation
    private let _pendingOperations: () -> AnyRandomAccessCollection<PendingOperation>
    private let _savePendingOperation: (PendingOperation) -> Void
    private let _removePendingOperation: (PendingOperation) -> Void
    private let _removeAllPendingOperations: (String?, [String]?) -> Int
    
    init<Sync: SyncType>(_ sync: Sync) {
        _createPendingOperation = sync.createPendingOperation
        _pendingOperations = sync.pendingOperations
        _savePendingOperation = sync.savePendingOperation
        _removePendingOperation = sync.removePendingOperation
        _removeAllPendingOperations = sync.removeAllPendingOperations
    }
    
    func createPendingOperation(_ request: URLRequest, objectId: String? = nil) -> PendingOperation {
        return _createPendingOperation(request, objectId)
    }
    
    func pendingOperations() -> AnyRandomAccessCollection<PendingOperation> {
        return _pendingOperations()
    }
    
    func savePendingOperation(_ pendingOperation: PendingOperation) {
        _savePendingOperation(pendingOperation)
    }
    
    func removePendingOperation(_ pendingOperation: PendingOperation) {
        _removePendingOperation(pendingOperation)
    }
    
    @discardableResult
    func removeAllPendingOperations(_ objectId: String? = nil, methods: [String]? = nil) -> Int {
        return _removeAllPendingOperations(objectId, methods)
    }
    
}
