//
//  Sync.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal protocol Sync {
    
    var persistenceId: String { get }
    var collectionName: String { get }
    
    init(persistenceId: String)
    
    func createPendingOperation(request: NSURLRequest!, objectId: String?) -> PendingOperation
    func savePendingOperation(pendingOperation: PendingOperation)
    
    func pendingOperations() -> [PendingOperation]
    func pendingOperations(objectId: String?) -> [PendingOperation]
    
    func removePendingOperation(pendingOperation: PendingOperation)
    
    func removeAllPendingOperations()
    func removeAllPendingOperations(objectId: String?)
    
}
