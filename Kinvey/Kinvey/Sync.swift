//
//  Sync.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVSync)
internal protocol Sync {
    
    var persistenceId: String { get set }
    var collectionName: String { get set }
    
    init!(persistenceId: String, collectionName: String)
    
    func createPendingOperation(request: NSURLRequest!, objectId: String?) -> PendingOperation
    func savePendingOperation(pendingOperation: PendingOperation)
    
    func pendingOperations() -> [PendingOperation]
    func pendingOperations(objectId: String?) -> [PendingOperation]
    
    func removePendingOperation(pendingOperation: PendingOperation)
    
    func removeAllPendingOperations()
    func removeAllPendingOperations(objectId: String?)
    
}
