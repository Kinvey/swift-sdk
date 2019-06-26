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
    
    //Count
    func pendingOperationsCount() -> Int
    
    //Update
    func save(pendingOperation: PendingOperation)
    
    //Update
    func save<C>(pendingOperations: C) where C: Collection, C.Element == PendingOperation
    
    //Delete
    func remove(pendingOperation: PendingOperation)
    func remove<C>(requestIds: C) where C: Collection, C.Element == String
    func removeAllPendingOperations(_ objectId: String?, methods: [String]?) -> Int
    
}

internal final class AnySync: SyncType {
    
    private let _createPendingOperation: (URLRequest, String?) -> PendingOperation
    private let _pendingOperations: () -> AnyRandomAccessCollection<PendingOperation>
    private let _pendingOperationsCount: () -> Int
    private let _savePendingOperation: (PendingOperation) -> Void
    private let _savePendingOperations: (AnyCollection<PendingOperation>) -> Void
    private let _removePendingOperation: (PendingOperation) -> Void
    private let _removePendingOperations: (AnyCollection<String>) -> Void
    private let _removeAllPendingOperations: (String?, [String]?) -> Int
    
    let sync: SyncType
    
    init<Sync: SyncType>(_ sync: Sync) {
        self.sync = sync
        _createPendingOperation = sync.createPendingOperation
        _pendingOperations = sync.pendingOperations
        _pendingOperationsCount = sync.pendingOperationsCount
        _savePendingOperation = sync.save(pendingOperation:)
        _savePendingOperations = sync.save(pendingOperations:)
        _removePendingOperation = sync.remove(pendingOperation:)
        _removePendingOperations = sync.remove(requestIds:)
        _removeAllPendingOperations = sync.removeAllPendingOperations
    }
    
    func createPendingOperation(_ request: URLRequest, objectId: String? = nil) -> PendingOperation {
        return _createPendingOperation(request, objectId)
    }
    
    func pendingOperations() -> AnyRandomAccessCollection<PendingOperation> {
        return _pendingOperations()
    }
    
    func pendingOperationsCount() -> Int {
        return _pendingOperationsCount()
    }
    
    func save(pendingOperation: PendingOperation) {
        _savePendingOperation(pendingOperation)
    }
    
    func save<C>(pendingOperations: C) where C : Collection, C.Element == PendingOperation {
        _savePendingOperations(AnyCollection(pendingOperations))
    }
    
    func remove(pendingOperation: PendingOperation) {
        _removePendingOperation(pendingOperation)
    }
    
    func remove<C>(requestIds: C) where C : Collection, C.Element == String {
        _removePendingOperations(AnyCollection(requestIds))
    }
    
    @discardableResult
    func removeAllPendingOperations(_ objectId: String? = nil, methods: [String]? = nil) -> Int {
        return _removeAllPendingOperations(objectId, methods)
    }
    
}
