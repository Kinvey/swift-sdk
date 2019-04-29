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
    
    typealias ResultType = Result<UInt, [Swift.Error]>
    
    var result: ResultType?
    
    let completionOperation: PushBlockOperation
    private let dispatchSerialQueue: DispatchQueue
    
    var progress = Progress()
    
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

internal class PushOperation<T: Persistable>: SyncOperation<T, UInt, [Swift.Error]> where T: NSObject {
    
    typealias ResultType = Result<UInt, [Swift.Error]>
    
    internal override init(
        sync: AnySync?,
        cache: AnyCache<T>?,
        options: Options?
    ) {
        super.init(
            sync: sync,
            cache: cache,
            options: options
        )
    }
    
    func execute(completionHandler: CompletionHandler?) -> AnyRequest<ResultType> {
        var count = UInt(0)
        var errors: [Swift.Error] = []
        
        let collectionName = try! T.collectionName()
        var pushOperation: PushRequest!
        pushOperation = PushRequest(collectionName: collectionName) {
            let result: ResultType
            if errors.isEmpty {
                result = .success(count)
            } else {
                result = .failure(errors)
            }
            pushOperation.result = result
            completionHandler?(result)
        }
        
        let pendingBlockOperations = operationsQueue.pendingBlockOperations(forCollection: collectionName)
        
        if let sync = sync {
            for pendingOperation in sync.pendingOperations() {
                let request = HttpRequest<Result<UInt, Swift.Error>>(
                    request: pendingOperation.buildRequest(),
                    options: options
                )
                let objectId = pendingOperation.objectId
                let operation = AsyncBlockOperation { (operation: AsyncBlockOperation) in
                    request.execute() { data, response, error in
                        if let response = response,
                            response.isOK,
                            let data = data
                        {
                            let json = try? self.client.jsonParser.parseDictionary(from: data)
                            if let cache = self.cache,
                                let json = json,
                                request.request.httpMethod != "DELETE"
                            {
                                if let objectId = objectId,
                                    objectId.starts(with: ObjectIdTmpPrefix),
                                    let entity = cache.find(byId: objectId)
                                {
                                    cache.remove(entity: entity)
                                }
                                
                                if let persistable = try? self.client.jsonParser.parseObject(T.self, from: json) {
                                    cache.save(entity: persistable)
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
                        } else if let response = response, response.isUnauthorized,
                            let data = data,
                            let json = try? self.client.jsonParser.parseDictionary(from: data) as? [String : String],
                            let error = json["error"],
                            let debug = json["debug"],
                            let description = json["description"]
                        {
                            let error = Error.unauthorized(
                                httpResponse: response.httpResponse,
                                data: data,
                                error: error,
                                debug: debug,
                                description: description
                            )
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
        return AnyRequest(pushOperation)
    }
    
}
