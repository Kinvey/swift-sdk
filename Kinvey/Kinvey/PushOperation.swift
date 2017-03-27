//
//  PushOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

class PendingBlockOperation: CollectionBlockOperation {
}

class PushBlockOperation: PendingBlockOperation {
}

fileprivate class PushRequest: NSObject, Request {
    
    let completionOperation: PushBlockOperation
    private let dispatchSerialQueue: DispatchQueue
    
    var progress: ((ProgressStatus) -> Void)?
    
    var executing: Bool {
        return !completionOperation.isFinished
    }
    
    var cancelled = false
    
    func cancel() {
        cancelled = true
        completionOperation.cancel()
        for operation in self.completionOperation.dependencies {
            operation.cancel()
        }
    }
    
    init(collectionName: String, completionBlock: @escaping () -> Void) {
        dispatchSerialQueue = DispatchQueue(label: "Push \(collectionName)")
        completionOperation = PushBlockOperation(collectionName: collectionName, block: completionBlock)
    }
    
    func addOperation(operation: Foundation.Operation) {
        dispatchSerialQueue.sync {
            self.completionOperation.addDependency(operation)
        }
    }
    
    func execute(pendingBlockOperations: [PendingBlockOperation]) {
        dispatchSerialQueue.sync {
            for operation in self.completionOperation.dependencies {
                operationsQueue.addOperation(operation)
            }
            for pendingBlockOperation in pendingBlockOperations {
                self.completionOperation.addDependency(pendingBlockOperation)
            }
            operationsQueue.addOperation(self.completionOperation)
        }
    }
    
}

internal class PushOperation<T: Persistable>: SyncOperation<T, UInt, [Swift.Error]?> where T: NSObject {
    
    internal override init(sync: AnySync?, cache: Cache<T>?, client: Client) {
        super.init(sync: sync, cache: cache, client: client)
    }
    
    override func execute(timeout: TimeInterval? = nil, completionHandler: CompletionHandler?) -> Request {
        var count = UInt(0)
        var errors: [Swift.Error] = []
        
        let collectionName = T.collectionName()
        let pushOperation = PushRequest(collectionName: collectionName) {
            completionHandler?(count, errors.count > 0 ? errors : nil)
        }
        
        let pendingBlockOperations = operationsQueue.pendingBlockOperations(forCollection: collectionName)
        
        if let sync = sync {
            for pendingOperation in sync.pendingOperations() {
                let request = HttpRequest(request: pendingOperation.buildRequest(), timeout: timeout, client: client)
                let objectId = pendingOperation.objectId
                let operation = AsyncBlockOperation { (operation: AsyncBlockOperation) in
                    request.execute() { data, response, error in
                        if let response = response,
                            response.isOK,
                            let data = data
                        {
                            let json = self.client.responseParser.parse(data)
                            if let cache = self.cache, let json = json, let objectId = objectId , request.request.httpMethod != "DELETE" {
                                if let entity = cache.findEntity(objectId) {
                                    cache.removeEntity(entity)
                                }
                                
                                let persistable = T(JSON: json)
                                if let persistable = persistable {
                                    cache.saveEntity(persistable)
                                }
                            }
                            if request.request.httpMethod != "DELETE" {
                                self.sync?.removePendingOperation(pendingOperation)
                                count += 1
                            } else if let json = json, let _count = json["count"] as? UInt {
                                self.sync?.removePendingOperation(pendingOperation)
                                count += _count
                            } else {
                                errors.append(buildError(data, response, error, self.client))
                            }
                        } else if let response = response , response.isUnauthorized,
                            let data = data,
                            let json = self.client.responseParser.parse(data) as? [String : String]
                        {
                            let error = Error.buildUnauthorized(httpResponse: response.httpResponse, data: data, json: json)
                            switch error {
                            case .unauthorized(_, _, let error, _):
                                if error == Error.InsufficientCredentials {
                                    self.sync?.removePendingOperation(pendingOperation)
                                }
                            default:
                                break
                            }
                            errors.append(error)
                        } else {
                            errors.append(buildError(data, response, error, self.client))
                        }
                        operation.state = .finished
                    }
                }
                
                for pendingBlockOperation in pendingBlockOperations {
                    operation.addDependency(pendingBlockOperation)
                }
                
                pushOperation.addOperation(operation: operation)
            }
        }
        
        pushOperation.execute(pendingBlockOperations: pendingBlockOperations)
        return pushOperation
    }
    
}
