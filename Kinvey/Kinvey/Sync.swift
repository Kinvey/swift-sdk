//
//  Sync.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal protocol SyncType {
    
    var persistenceId: String { get }
    var collectionName: String { get }
    
    //Create
    func createPendingOperation(_ request: URLRequest, objectId: String?) -> PendingOperationType
    
    //Read
    func pendingOperations(_ objectId: String?) -> AnyCollection<PendingOperationType>
    
    //Update
    func savePendingOperation(_ pendingOperation: PendingOperationType)
    
    //Delete
    func removePendingOperation(_ pendingOperation: PendingOperationType)
    func removeAllPendingOperations(_ objectId: String?, methods: [String]?)
    
}


internal final class AnySync: SyncType {
    
    var persistenceId: String {
        return _getPersistenceId()
    }
    
    var collectionName: String {
        return _getCollectionName()
    }
    
    private let _getPersistenceId: () -> String
    private let _getCollectionName: () -> String
    private let _createPendingOperation: (URLRequest, String?) -> PendingOperationType
    private let _pendingOperations: (String?) -> AnyCollection<PendingOperationType>
    private let _savePendingOperation: (PendingOperationType) -> Void
    private let _removePendingOperation: (PendingOperationType) -> Void
    private let _removeAllPendingOperations: (String?, [String]?) -> Void
    
    init<Sync: SyncType>(_ sync: Sync) {
        _getPersistenceId = { return sync.persistenceId }
        _getCollectionName = { return sync.collectionName }
        _createPendingOperation = sync.createPendingOperation
        _pendingOperations = sync.pendingOperations
        _savePendingOperation = sync.savePendingOperation
        _removePendingOperation = sync.removePendingOperation
        _removeAllPendingOperations = sync.removeAllPendingOperations
    }
    
    func createPendingOperation(_ request: URLRequest, objectId: String? = nil) -> PendingOperationType {
        return _createPendingOperation(request, objectId)
    }
    
    func pendingOperations(_ objectId: String? = nil) -> AnyCollection<PendingOperationType> {
        return _pendingOperations(objectId)
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
