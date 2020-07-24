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
        var count = UInt(0)
        var errors: [Swift.Error] = []
        
        let collectionName = try! T.collectionName()
        var pushOperation: PushRequest!
        pushOperation = PushRequest(collectionName: collectionName) {
            let result: ResultType
            if errors.isEmpty {
                result = .success(count)
            } else {
                result = .failure(MultipleErrors(errors: errors))
            }
            pushOperation.result = result
            completionHandler?(result)
        }
        
        let pendingBlockOperations = operationsQueue.pendingBlockOperations(forCollection: collectionName)
        
        if let sync = sync {
            for pendingOperation in sync.pendingOperations(useMultiInsert: true) {
                let request = HttpRequest<Swift.Result<UInt, Swift.Error>>(
                    request: pendingOperation.buildRequest(),
                    options: options
                )
                var objectId = pendingOperation.objectId
                let objectIds = pendingOperation.objectIds
                let requestIds = pendingOperation.requestIds
                let operation = AsyncBlockOperation { (operation: AsyncBlockOperation) in
                    request.execute() { data, response, error in
                        if let response = response,
                            response.isOK,
                            let data = data
                        {
                            if let result = try? self.client.jsonParser.parseDictionary(from: data),
                                let results = objectIds != nil
                                    ? result["entities"] as? [JsonDictionary?]
                                    : Array<JsonDictionary?>.init(repeating: result, count: 1)
                            {
                                var index = objectIds?.startIndex
                                for json in results {
                                    if objectId == nil,
                                        index != nil,
                                        let objectIds = objectIds
                                    {
                                        objectId = objectIds[index!]
                                        index = objectIds.index(after: index!)
                                    }
                                    if let cache = self.cache,
                                        let json = json,
                                        request.request.httpMethod != "DELETE"
                                    {
                                        if let objectId = objectId,
                                            objectId.hasPrefix(EntityIdTmpPrefix),
                                            let entity = cache.find(byId: objectId)
                                        {
                                            cache.remove(entity: entity)
                                        }
                                        
                                        if let persistable = try? self.client.jsonParser.parseObject(T.self, from: json) {
                                            cache.save(entity: persistable)
                                        }
                                    }
                                }
                                
                                var requestIdsRemoved = requestIds != nil ? [Bool](repeating: true, count: requestIds?.count ?? 0) : nil
                                var entities: AnyRandomAccessCollection<T?>? = nil
                                var entitiesErrors: AnyRandomAccessCollection<Swift.Error>? = nil
                                if let errorsJson = result["errors"] as? [JsonDictionary],
                                    let objectIds = objectIds,
                                    let cache = self.cache
                                {
                                    let entitiesJson = results
                                    var objectIdsRemoved = [Bool](repeating: true, count: objectIds.count)
                                    let _entities = AnyRandomAccessCollection(entitiesJson.enumerated().lazy.map({ (offset, entity) -> T? in
                                        guard let entity = entity else {
                                            requestIdsRemoved?[offset] = false
                                            objectIdsRemoved[offset] = false
                                            return nil
                                        }
                                        return try? self.client.jsonParser.parseObject(T.self, from: entity)
                                    }))
                                    entitiesErrors = AnyRandomAccessCollection(errorsJson.lazy.compactMap({ (error) -> MultiSaveError? in
                                        guard let index = error[MultiSaveError.CodingKeys.index.rawValue] as? Int,
                                            let message = error[MultiSaveError.CodingKeys.error.rawValue] as? String
                                        else {
                                            return nil
                                        }
                                        let description = error[MultiSaveError.CodingKeys.serverDescription.rawValue] as? String
                                        let debug = error[MultiSaveError.CodingKeys.serverDebug.rawValue] as? String
                                        
                                        return MultiSaveError(index: index, error: message, serverDescription: description, serverDebug: debug)
                                    }))
                                    let objectIdsToBeRemoved = zip(objectIds, objectIdsRemoved).compactMap { objectId, removed in
                                        return removed ? objectId : nil
                                    }
                                    cache.remove(byQuery: Query(format: "\(try! T.entityIdProperty()) IN %@", objectIdsToBeRemoved))
                                    cache.save(entities: _entities.compactMap({ $0 }), syncQuery: nil)
                                    entities = _entities
                                }
                                if request.request.httpMethod != "DELETE" {
                                    if let entities = entities,
                                        let entitiesErrors = entitiesErrors,
                                        let requestIds = requestIds,
                                        let requestIdsRemoved = requestIdsRemoved
                                    {
                                        errors.append(contentsOf: entitiesErrors)
                                        let requestIdsToBeRemoved = zip(requestIds, requestIdsRemoved).compactMap { (requestId, removed) in
                                            return removed ? requestId : nil
                                        }
                                        self.sync?.remove(requestIds: requestIdsToBeRemoved)
                                        count += UInt(entities.count)
                                    } else {
                                        self.sync?.remove(pendingOperation: pendingOperation)
                                        count += 1
                                    }
                                } else if let _count = result["count"] as? UInt {
                                    self.sync?.remove(pendingOperation: pendingOperation)
                                    count += _count
                                } else {
                                    errors.append(buildError(data, response, error, self.client))
                                }
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
                            let errorCount = objectIds != nil ? objectIds!.count : 1
                            errors.append(contentsOf: repeatElement(buildError(data, response, error, self.client), count: errorCount))
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
