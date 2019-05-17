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
    
    typealias ResultType = Swift.Result<UInt, MultipleErrors>
    
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

internal class PushOperation<T: Persistable>: SyncOperation<T, UInt, MultipleErrors> where T: NSObject {
    
    typealias ResultType = Swift.Result<UInt, MultipleErrors>
    
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
        guard let sync = sync else {
            return AnyRequest(.success(0))
        }
        
        let requests = MultiRequest<ResultType>()
        
        let promises = sync.pendingOperations().map({ push(pendingOperation: $0, requests: requests) })
        when(resolved: promises).done {
            var count = UInt(0)
            var errors: [Swift.Error] = []
            for result in $0 {
                switch result {
                case .fulfilled(let _count):
                    count += _count
                case .rejected(let error):
                    errors.append(error)
                }
            }
            completionHandler?(errors.isEmpty ? .success(count) : .failure(MultipleErrors(errors: errors)))
        }
        
        return AnyRequest(requests)
    }
    
    private func push(pendingOperation: PendingOperation, requests: MultiRequest<ResultType>) -> Promise<UInt> {
        return Promise<UInt> { resolver in
            let request = HttpRequest<Swift.Result<UInt, Swift.Error>>(
                request: pendingOperation.buildRequest(),
                options: options
            )
            let objectId = pendingOperation.objectId
            requests += request
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
                        resolver.fulfill(1)
                    } else if let json = json, let count = json["count"] as? UInt {
                        self.sync?.removePendingOperation(pendingOperation)
                        resolver.fulfill(count)
                    } else {
                        resolver.reject(buildError(data, response, error, self.client))
                    }
                } else if let response = response, response.isUnauthorized,
                    let data = data,
                    let json = try? self.client.jsonParser.parseDictionary(from: data) as? [String : String],
                    let error = json["error"],
                    let debug = json["debug"],
                    let description = json["description"]
                {
                    resolver.reject(Error.unauthorized(
                        httpResponse: response.httpResponse,
                        data: data,
                        error: error,
                        debug: debug,
                        description: description
                    ))
                } else {
                    resolver.reject(buildError(data, response, error, self.client))
                }
            }
        }
    }
    
}
