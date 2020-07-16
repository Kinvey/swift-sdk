//
//  SaveMultiOperation.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2019-05-13.
//  Copyright © 2019 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

private let maxSizePerRequest = 100

public typealias MultiSaveResultTuple<T> = (entities: AnyRandomAccessCollection<T?>, errors: AnyRandomAccessCollection<Swift.Error>)

internal class SaveMultiOperation<T: Persistable>: WriteOperation<T, MultiSaveResultTuple<T>> where T: NSObject {
    
    let persistable: AnyRandomAccessCollection<T>
    let isNewItems: AnyRandomAccessCollection<Bool>
    let newItems: AnyRandomAccessCollection<T>
    let existingItems: AnyRandomAccessCollection<T>
    
    typealias ResultType = Swift.Result<MultiSaveResultTuple<T>, Swift.Error>
    
    init<C: RandomAccessCollection>(
        persistable: C,
        writePolicy: WritePolicy,
        sync: AnySync? = nil,
        cache: AnyCache<T>? = nil,
        options: Options?
    ) where C.Element == T {
        self.persistable = AnyRandomAccessCollection(persistable)
        var isNewItems = [Bool]()
        var newItems = [T]()
        var existingItems = [T]()
        var isNew: Bool
        isNewItems.reserveCapacity(persistable.count)
        newItems.reserveCapacity(persistable.count)
        existingItems.reserveCapacity(persistable.count)
        for item in persistable {
            isNew = item.isNew
            isNewItems.append(isNew)
            if isNew {
                newItems.append(item)
            } else {
                existingItems.append(item)
            }
        }
        self.isNewItems = AnyRandomAccessCollection(isNewItems)
        self.newItems = AnyRandomAccessCollection(newItems)
        self.existingItems = AnyRandomAccessCollection(existingItems)
        super.init(
            writePolicy: writePolicy,
            sync: sync,
            cache: cache,
            options: options
        )
    }
    
    private func requestBodyCannotBeAnEmptyArrayError(_ completionHandler: CompletionHandler?) -> AnyRequest<ResultType> {
        let error = Error.badRequest(httpResponse: nil, data: nil, description: "Request body cannot be an empty array")
        let result: Swift.Result<MultiSaveResultTuple<T>, Swift.Error> = .failure(error)
        completionHandler?(result)
        return AnyRequest(result)
    }
    
    func executeLocal(_ completionHandler: CompletionHandler?) -> AnyRequest<ResultType> {
        guard self.persistable.count > 0 else {
            return requestBodyCannotBeAnEmptyArrayError(completionHandler)
        }
        let request = LocalRequest<Swift.Result<MultiSaveResultTuple<T>, Swift.Error>>()
        request.execute { () -> Void in
            var isNewArray = [Bool]()
            if let cache = self.cache {
                let persistable = self.persistable.map { (entity: T) -> T in
                    isNewArray.append(entity.isNew)
                    var persistable = entity
                    return self.fillObject(&persistable)
                }
                cache.save(entities: persistable, syncQuery: nil)
            }
            
            if let sync = self.sync {
                let pendingOperations = persistable.enumerated().map { (args) -> PendingOperation in
                    let (offset, item) = args
                    let networkRequest = self.client.networkRequestFactory.appData.buildAppDataSave(
                        item,
                        options: options,
                        isNew: isNewArray[offset],
                        resultType: T.self
                    )
                    return sync.createPendingOperation(networkRequest.request, objectId: item.entityId)
                }
                sync.save(pendingOperations: pendingOperations)
            }
            request.result = .success((entities: AnyRandomAccessCollection(persistable.map({ Optional($0) })), errors: AnyRandomAccessCollection(EmptyCollection())))
            if let completionHandler = completionHandler, let result = request.result {
                completionHandler(result)
            }
        }
        return AnyRequest(request)
    }
    
    func executeNetwork(_ completionHandler: CompletionHandler?) -> AnyRequest<ResultType> {
        guard client.activeUser != nil else {
            let result: Swift.Result<MultiSaveResultTuple<T>, Swift.Error> = .failure(Error.noActiveUser)
            completionHandler?(result)
            return AnyRequest(result)
        }
        guard self.persistable.count > 0 else {
            return requestBodyCannotBeAnEmptyArrayError(completionHandler)
        }
        let requests = MultiRequest<ResultType>()
        
        saveNewItems(requests: requests).then { (newItemsResponse) -> Promise<(MultiSaveResultTuple<T>, [Swift.Result<T, Swift.Error>])> in
            let newItemsResult = try newItemsResponse.get()
            return self.updateExistingItems(requests: requests).map { (newItemsResult, $0) }
        }.done { newItemsResult, existingItemsResult in
            guard existingItemsResult.count > 0 else {
                requests.result = .success(newItemsResult)
                return
            }
            var entities = [T?]()
            var errors = [Swift.Error]()
            let newItemsIterator = newItemsResult.entities.makeIterator()
            var existingItemsIterator = existingItemsResult.makeIterator()
            let newItemsErrorsIterator = newItemsResult.errors.makeIterator()
            for isNew in self.isNewItems {
                if isNew {
                    guard let newItem = newItemsIterator.next() else {
                        continue
                    }
                    entities.append(newItem)
                    if newItem == nil, let error = newItemsErrorsIterator.next() {
                        errors.append(error)
                    }
                } else {
                    guard let existingItem = existingItemsIterator.next() else {
                        continue
                    }
                    switch existingItem {
                    case .success(let existingItem):
                        entities.append(existingItem)
                    case .failure(let error):
                        let error = IndexedError(index: entities.count, error: error)
                        entities.append(nil)
                        errors.append(error)
                    }
                }
            }
            requests.result = .success(
                MultiSaveResultTuple(
                    entities: AnyRandomAccessCollection(entities),
                    errors: AnyRandomAccessCollection(errors)
                )
            )
        }.catch { error in
            requests.result = .failure(error)
        }.finally {
            if let completionHandler = completionHandler, let result = requests.result {
                completionHandler(result)
            }
        }
        
        return AnyRequest(requests)
    }
    
    private func updateExistingItems(requests: MultiRequest<ResultType>) -> Promise<[Swift.Result<T, Swift.Error>]> {
        let iterator = existingItems.makeIterator()
        let promisesIterator = AnyIterator<Promise<Swift.Result<T, Swift.Error>>> {
            guard let persistable = iterator.next() else {
                return nil
            }
            return Promise<Swift.Result<T, Swift.Error>> { resolver in
                let operation = SaveOperation<T>(
                    persistable: persistable,
                    writePolicy: .forceNetwork,
                    sync: self.sync,
                    cache: self.cache,
                    options: self.options
                )
                requests += operation.execute {
                    resolver.fulfill($0)
                }
            }
        }
        let urlSessionConfiguration = options?.urlSession?.configuration ?? client.urlSession.configuration
        return when(fulfilled: promisesIterator, concurrently: urlSessionConfiguration.httpMaximumConnectionsPerHost)
    }
    
    private func saveNewItems(requests: MultiRequest<ResultType>) -> Promise<ResultType> {
        switch newItems.count {
        case 0:
            let result: Swift.Result<MultiSaveResultTuple<T>, Swift.Error> = .success((entities: AnyRandomAccessCollection(EmptyCollection()), errors: AnyRandomAccessCollection(EmptyCollection())))
            return Promise.value(result)
        case 1 ... maxSizePerRequest:
            return saveSingleRequest(newItems: newItems, requests: requests)
        default:
            return saveMultiRequests(newItems: newItems, requests: requests)
        }
    }
    
    private func saveSingleRequest(newItems: AnyRandomAccessCollection<T>, requests: MultiRequest<ResultType>) -> Promise<ResultType> {
        let objectIds = newItems.map({ $0.entityId })
        let request = client.networkRequestFactory.appData.buildAppDataSave(
            newItems,
            options: options,
            resultType: ResultType.self
        )
        requests += request
        return Promise<ResultType> { resolver in
            request.execute() { _data, _response, error in
                guard let response = _response,
                    response.isOK,
                    let data = _data,
                    let json = try? self.client.jsonParser.parseDictionary(from: data),
                    let entitiesJson = json["entities"] as? [JsonDictionary?],
                    let entities = try? entitiesJson.map({ (item) -> T? in
                        guard let item = item else {
                            return nil
                        }
                        return try self.client.jsonParser.parseObject(T.self, from: item)
                    }),
                    let errors = json["errors"] as? [JsonDictionary]
                else {
                    resolver.reject(buildError(_data, _response, error, self.client))
                    return
                }
                for (offset, entity) in entities.enumerated() {
                    guard let entity = entity else {
                        continue
                    }
                    if let objectId = objectIds[offset],
                        let sync = self.sync
                    {
                        sync.removeAllPendingOperations(
                            objectId,
                            methods: ["POST"]
                        )
                    }
                    if let cache = self.cache {
                        if let objectId = objectIds[offset] {
                            cache.remove(byQuery: Query(format: "entityId == %@", objectId))
                        }
                        cache.save(entity: entity)
                    }
                }
                resolver.fulfill(.success((
                    entities: AnyRandomAccessCollection(entities),
                    errors: AnyRandomAccessCollection(errors.map({
                        let json = $0
                        guard let error = json["error"] as? String,
                            let index = json["index"] as? Int
                        else {
                            return Error.unknownJsonError(httpResponse: response.httpResponse, data: data, json: json)
                        }
                        let description = json["description"] as? String
                        let debug = json["debug"] as? String
                        
                        return MultiSaveError(
                            index: index,
                            message: error,
                            serverDescription: description,
                            serverDebug: debug
                        )
                    }))
                )))
            }
        }
    }
    
    private func saveMultiRequests(newItems: AnyRandomAccessCollection<T>, requests: MultiRequest<ResultType>) -> Promise<ResultType> {
        var offsetIterator = stride(from: 0, to: persistable.count, by: maxSizePerRequest).makeIterator()
        let promisesIterator = AnyIterator<Guarantee<ResultType>> {
            guard let offset = offsetIterator.next() else {
                return nil
            }
            let startIndex = newItems.index(newItems.startIndex, offsetBy: offset)
            let endIndex = newItems.index(newItems.startIndex, offsetBy: offset + maxSizePerRequest, limitedBy: newItems.endIndex) ?? newItems.endIndex
            let range = startIndex ..< endIndex
            let slice = newItems[range]
            return self.saveSingleRequest(newItems: slice, requests: requests).recover({ (error) -> Guarantee<ResultType> in
                return Guarantee<ResultType>.value(.success((
                    entities: AnyRandomAccessCollection(Array(repeating: nil, count: slice.count)),
                    errors: AnyRandomAccessCollection((0 ..< slice.count).map({ IndexedError(index: $0, error: error) }))
                )))
            })
        }
        let urlSessionConfiguration = options?.urlSession?.configuration ?? client.urlSession.configuration
        return when(fulfilled: promisesIterator, concurrently: urlSessionConfiguration.httpMaximumConnectionsPerHost).map(on: DispatchQueue.global(qos: .background)) { results -> ResultType in
            var entities = [T?]()
            var errors = [Swift.Error]()
            for result in results {
                switch result {
                case .success(let item):
                    let entitiesCount = entities.count
                    errors.append(contentsOf: item.errors.map {
                        switch $0 {
                        case let multiSaveError as MultiSaveError:
                            return MultiSaveError(
                                index: entitiesCount + multiSaveError.index,
                                message: multiSaveError.message,
                                serverDescription: multiSaveError.serverDescription,
                                serverDebug: multiSaveError.serverDebug
                            )
                        case let indexedError as IndexedError:
                            return IndexedError(
                                index: entitiesCount + indexedError.index,
                                error: indexedError.error
                            )
                        default:
                            return $0
                        }
                    })
                    entities.append(contentsOf: item.entities)
                case .failure(let error):
                    errors.append(contentsOf: [error])
                }
            }
            return .success((entities: AnyRandomAccessCollection(entities), errors: AnyRandomAccessCollection(errors)))
        }
    }
    
}

extension SaveMultiOperation : SaveOperationType {
    
    var localSuccess: MultiSaveResultTuple<T> {
        let entities: [T?] = persistable.map { (entity) -> T? in
            return entity
        }
        return MultiSaveResultTuple(
            entities: AnyRandomAccessCollection(entities),
            errors: AnyRandomAccessCollection([])
        )
    }
    
}
