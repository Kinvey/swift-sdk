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
            for pendingOperation in sync.pendingOperations() {
                let request = HttpRequest<Swift.Result<UInt, Swift.Error>>(
                    request: pendingOperation.buildRequest(),
                    options: options
                )
                let objectId = pendingOperation.objectId
                let objectIds = pendingOperation.objectIds
                let requestIds = pendingOperation.requestIds
                var requestIdsRemoved = requestIds != nil ? [Bool](repeating: true, count: requestIds?.count ?? 0) : nil
                var entities: AnyRandomAccessCollection<T?>? = nil
                var entitiesErrors: AnyRandomAccessCollection<Swift.Error>? = nil
                let operation = AsyncBlockOperation { (operation: AsyncBlockOperation) in
                    request.execute() { data, response, error in
                        if let response = response,
                            response.isOK,
                            let data = data
                        {
                            let json = try? self.client.jsonParser.parseDictionary(from: data)
                            self.refreshEntities(
                                request: request,
                                json: json,
                                objectId: objectId,
                                objectIds: objectIds,
                                requestIdsRemoved: &requestIdsRemoved,
                                entities: &entities,
                                entitiesErrors: &entitiesErrors
                            )
                            
                            self.remove(
                                pendingOperation: pendingOperation,
                                json: json,
                                request: request,
                                requestIds: requestIds,
                                requestIdsRemoved: requestIdsRemoved,
                                response: response,
                                data: data,
                                error: error,
                                entities: entities,
                                entitiesErrors: entitiesErrors,
                                count: &count,
                                errors: &errors
                            )
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
    
    private func refreshEntities(
        request: HttpRequest<Swift.Result<UInt, Swift.Error>>,
        json: JsonDictionary?,
        objectId: String?,
        objectIds: AnyRandomAccessCollection<String>?,
        requestIdsRemoved: inout [Bool]?,
        entities: inout AnyRandomAccessCollection<T?>?,
        entitiesErrors: inout AnyRandomAccessCollection<Swift.Error>?
    ) {
        guard let cache = self.cache,
            let json = json,
            request.request.httpMethod != "DELETE"
        else {
            return
        }
        self.removeOldEntities(
            cache: cache,
            objectId: objectId,
            objectIds: objectIds
        )
        
        self.saveNewEntities(
            cache: cache,
            json: json,
            requestIdsRemoved: &requestIdsRemoved,
            entities: &entities,
            entitiesErrors: &entitiesErrors
        )
    }
    
    private func removeOldEntities(
        cache: AnyCache<T>,
        objectId: String?,
        objectIds: AnyRandomAccessCollection<String>?
    ) {
        if let objectId = objectId,
            objectId.hasPrefix(EntityIdTmpPrefix),
            let entity = cache.find(byId: objectId)
        {
            cache.remove(entity: entity)
        } else if let objectIds = objectIds {
            cache.remove(byQuery: Query(format: "\(try! T.entityIdProperty()) IN %@", Array(objectIds)))
        }
    }
    
    private func saveNewEntities(
        cache: AnyCache<T>,
        json: JsonDictionary,
        requestIdsRemoved: inout [Bool]?,
        entities: inout AnyRandomAccessCollection<T?>?,
        entitiesErrors: inout AnyRandomAccessCollection<Swift.Error>?
    ) {
        if let entitiesJson = json["entities"] as? [JsonDictionary?],
            let errorsJson = json["errors"] as? [JsonDictionary]
        {
            let _entities = AnyRandomAccessCollection(entitiesJson.enumerated().lazy.map({ (offset, entity) -> T? in
                guard let entity = entity else {
                    requestIdsRemoved?[offset] = false
                    return nil
                }
                return try? self.client.jsonParser.parseObject(T.self, from: entity)
            }))
            entitiesErrors = AnyRandomAccessCollection(errorsJson.lazy.compactMap({ (error) -> MultiSaveError? in
                guard let index = error[MultiSaveError.CodingKeys.index.rawValue] as? Int,
                    let code = error[MultiSaveError.CodingKeys.code.rawValue] as? Int,
                    let message = error[MultiSaveError.CodingKeys.message.rawValue] as? String
                    else {
                        return nil
                }
                return MultiSaveError(index: index, code: code, message: message)
            }))
            cache.save(entities: _entities.compactMap({ $0 }), syncQuery: nil)
            entities = _entities
        } else if let persistable = try? self.client.jsonParser.parseObject(T.self, from: json) {
            cache.save(entity: persistable)
        }
    }
    
    private func remove(
        pendingOperation: PendingOperation,
        json: JsonDictionary?,
        request: HttpRequest<Swift.Result<UInt, Swift.Error>>,
        requestIds: AnyRandomAccessCollection<String>?,
        requestIdsRemoved: [Bool]?,
        response: Response?,
        data: Data?,
        error: Swift.Error?,
        entities: AnyRandomAccessCollection<T?>?,
        entitiesErrors: AnyRandomAccessCollection<Swift.Error>?,
        count: inout UInt,
        errors: inout [Swift.Error]
    ) {
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
                count += UInt(entities.compactMap({ $0 }).count)
            } else {
                self.sync?.remove(pendingOperation: pendingOperation)
                count += 1
            }
        } else if let json = json, let _count = json["count"] as? UInt {
            self.sync?.remove(pendingOperation: pendingOperation)
            count += _count
        } else {
            errors.append(buildError(data, response, error, self.client))
        }
    }
    
}
