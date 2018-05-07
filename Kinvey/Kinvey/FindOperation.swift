//
//  FindOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

private let MaxIdsPerQuery = 200
private let MaxSizePerResultSet = 10_000

internal class FindOperation<T: Persistable>: ReadOperation<T, AnyRandomAccessCollection<T>, Swift.Error>, ReadOperationType where T: NSObject {
    
    let query: Query
    let deltaSet: Bool
    let deltaSetCompletionHandler: ((AnyRandomAccessCollection<T>) -> Void)?
    let autoPagination: Bool
    let mustSetRequestResult: Bool
    
    typealias ResultType = Result<AnyRandomAccessCollection<T>, Swift.Error>
    
    lazy var isEmptyQuery: Bool = {
        return (self.query.predicate == nil || self.query.predicate == NSPredicate()) && self.query.skip == nil && self.query.limit == nil
    }()
    
    var mustRemoveCachedRecords: Bool {
        return isEmptyQuery
    }
    
    typealias ResultsHandler = ([JsonDictionary]) -> Void
    let resultsHandler: ResultsHandler?
    
    init(
        query: Query,
        deltaSet: Bool,
        deltaSetCompletionHandler: ((AnyRandomAccessCollection<T>) -> Void)? = nil,
        autoPagination: Bool,
        readPolicy: ReadPolicy,
        validationStrategy: ValidationStrategy?,
        cache: AnyCache<T>?,
        options: Options?,
        mustSetRequestResult: Bool = true,
        resultsHandler: ResultsHandler? = nil
    ) {
        self.query = query
        self.deltaSet = deltaSet
        self.deltaSetCompletionHandler = deltaSetCompletionHandler
        self.autoPagination = autoPagination
        self.resultsHandler = resultsHandler
        self.mustSetRequestResult = mustSetRequestResult
        super.init(
            readPolicy: readPolicy,
            validationStrategy: validationStrategy,
            cache: cache,
            options: options
        )
    }
    
    @discardableResult
    func executeLocal(_ completionHandler: CompletionHandler? = nil) -> AnyRequest<ResultType> {
        let request = LocalRequest<ResultType>()
        request.execute { () -> Void in
            let result: ResultType
            if let cache = self.cache {
                let json = cache.find(byQuery: self.query)
                result = .success(json)
            } else {
                result = .success(AnyRandomAccessCollection<T>([]))
            }
            if mustSetRequestResult {
                request.result = result
            }
            completionHandler?(result)
        }
        return AnyRequest(request)
    }
    
    typealias ArrayCompletionHandler = ([Any]?, Error?) -> Void
    
    private func count(multiRequest: MultiRequest<ResultType>) -> Promise<Int?> {
        return Promise<Int?> { resolver in
            if autoPagination {
                if let limit = query.limit {
                    resolver.fulfill(limit)
                } else {
                    let countOperation = CountOperation<T>(
                        query: query,
                        readPolicy: .forceNetwork,
                        validationStrategy: validationStrategy,
                        cache: nil,
                        options: nil
                    )
                    let request = countOperation.execute { result in
                        switch result {
                        case .success(let count):
                            resolver.fulfill(count)
                        case .failure(let error):
                            resolver.reject(error)
                        }
                    }
                    multiRequest.progress.addChild(request.progress, withPendingUnitCount: 1)
                    multiRequest += request
                }
            } else {
                resolver.fulfill(nil)
            }
        }
    }
    
    private func fetchAutoPagination(multiRequest: MultiRequest<ResultType>, count: Int) -> Promise<AnyRandomAccessCollection<T>> {
        return Promise<AnyRandomAccessCollection<T>> { resolver in
            let maxSizePerResultSet = options?.maxSizePerResultSet ?? MaxSizePerResultSet
            let nPages = Int64(ceil(Double(count) / Double(maxSizePerResultSet)))
            let progress = Progress(totalUnitCount: nPages + 1, parent: multiRequest.progress, pendingUnitCount: 99)
            var offsetIterator = stride(from: 0, to: count, by: maxSizePerResultSet).makeIterator()
            let isCacheNotNil = cache != nil
            let promisesIterator = AnyIterator<Promise<AnyRandomAccessCollection<T>>> {
                guard let offset = offsetIterator.next() else {
                    return nil
                }
                return Promise<AnyRandomAccessCollection<T>> { resolver in
                    let query = Query(self.query)
                    query.skip = offset
                    query.limit = min(maxSizePerResultSet, count - offset)
                    let operation = FindOperation(
                        query: query,
                        deltaSet: self.deltaSet,
                        autoPagination: false,
                        readPolicy: .forceNetwork,
                        validationStrategy: self.validationStrategy,
                        cache: self.cache,
                        options: self.options,
                        mustSetRequestResult: false
                    )
                    let request = operation.execute { result in
                        switch result {
                        case .success(let results):
                            resolver.fulfill(isCacheNotNil ? AnyRandomAccessCollection<T>([]) : results)
                        case .failure(let error):
                            resolver.reject(error)
                        }
                    }
                    progress.addChild(request.progress, withPendingUnitCount: 1)
                    multiRequest += request
                }
            }
            let urlSessionConfiguration = options?.urlSession?.configuration ?? client.urlSession.configuration
            when(fulfilled: promisesIterator, concurrently: urlSessionConfiguration.httpMaximumConnectionsPerHost).done(on: DispatchQueue.global(qos: .default)) { results -> Void in
                let result: AnyRandomAccessCollection<T>
                if let cache = self.cache {
                    result = cache.find(byQuery: self.query)
                } else {
                    result = AnyRandomAccessCollection(results.lazy.flatMap { $0 })
                }
                progress.completedUnitCount += 1
                resolver.fulfill(result)
            }.catch { error in
                resolver.reject(error)
            }
        }
    }
    
    private func fetch(multiRequest: MultiRequest<ResultType>) -> Promise<AnyRandomAccessCollection<T>> {
        return Promise<AnyRandomAccessCollection<T>> { resolver in
            let deltaSet = self.deltaSet && (cache != nil ? !cache!.isEmpty() : false)
            let fields: Set<String>? = deltaSet ? [Entity.Key.entityId, "\(Entity.Key.metadata).\(Metadata.Key.lastModifiedTime)"] : nil
            let request = client.networkRequestFactory.buildAppDataFindByQuery(
                collectionName: T.collectionName(),
                query: fields != nil ? Query(query) { $0.fields = fields } : query,
                options: options
            )
            request.execute() { data, response, error in
                if let response = response, response.isOK,
                    let jsonArray = self.client.responseParser.parseArray(data)
                {
                    if let validationStrategy = self.validationStrategy,
                        let error = validationStrategy.validate(jsonArray: jsonArray)
                    {
                        resolver.reject(error)
                        return
                    }
                    self.resultsHandler?(jsonArray)
                    if let cache = self.cache, deltaSet {
                        let refObjs = self.reduceToIdsLmts(jsonArray)
                        guard jsonArray.count == refObjs.count else {
                            let operation = FindOperation(
                                query: self.query,
                                deltaSet: false,
                                autoPagination: self.autoPagination,
                                readPolicy: self.readPolicy,
                                validationStrategy: self.validationStrategy,
                                cache: cache,
                                options: self.options
                            )
                            let request = operation.executeNetwork {
                                switch $0 {
                                case .success(let results):
                                    resolver.fulfill(results)
                                case .failure(let error):
                                    resolver.reject(error)
                                }
                            }
                            return
                        }
                        let deltaSet = self.computeDeltaSet(self.query, refObjs: refObjs)
                        var allIds = Set<String>(minimumCapacity: deltaSet.created.count + deltaSet.updated.count + deltaSet.deleted.count)
                        allIds.formUnion(deltaSet.created)
                        allIds.formUnion(deltaSet.updated)
                        allIds.formUnion(deltaSet.deleted)
                        if allIds.count > MaxIdsPerQuery {
                            let allIds = Array<String>(allIds)
                            var promises = [Promise<AnyRandomAccessCollection<T>>]()
                            var newRefObjs = [String : String]()
                            for offset in stride(from: 0, to: allIds.count, by: MaxIdsPerQuery) {
                                let limit = min(offset + MaxIdsPerQuery, allIds.count - 1)
                                let allIds = Set<String>(allIds[offset...limit])
                                let promise = Promise<AnyRandomAccessCollection<T>> { resolver in
                                    let query = Query(format: "\(Entity.Key.entityId) IN %@", allIds)
                                    let operation = FindOperation<T>(
                                        query: query,
                                        deltaSet: false,
                                        autoPagination: self.autoPagination,
                                        readPolicy: .forceNetwork,
                                        validationStrategy: self.validationStrategy,
                                        cache: cache,
                                        options: self.options
                                    ) { jsonArray in
                                        for (key, value) in self.reduceToIdsLmts(jsonArray) {
                                            newRefObjs[key] = value
                                        }
                                    }
                                    operation.execute { (result) -> Void in
                                        switch result {
                                        case .success(let results):
                                            resolver.fulfill(results)
                                        case .failure(let error):
                                            resolver.reject(error)
                                        }
                                    }
                                }
                                promises.append(promise)
                            }
                            when(fulfilled: promises).done { results in
                                if self.mustRemoveCachedRecords {
                                    self.removeCachedRecords(
                                        cache,
                                        keys: refObjs.keys,
                                        deleted: deltaSet.deleted
                                    )
                                }
                                if let deltaSetCompletionHandler = self.deltaSetCompletionHandler {
                                    deltaSetCompletionHandler(AnyRandomAccessCollection(results.flatMap { $0 }))
                                }
                                self.executeLocal {
                                    switch $0 {
                                    case .success(let results):
                                        resolver.fulfill(results)
                                    case .failure(let error):
                                        resolver.reject(error)
                                    }
                                }
                            }.catch { error in
                                resolver.reject(error)
                            }
                        } else if allIds.count > 0 {
                            let query = Query(format: "\(Entity.Key.entityId) IN %@", allIds)
                            var newRefObjs: [String : String]? = nil
                            let operation = FindOperation<T>(
                                query: query,
                                deltaSet: false,
                                autoPagination : self.autoPagination,
                                readPolicy: .forceNetwork,
                                validationStrategy: self.validationStrategy,
                                cache: cache,
                                options: self.options
                            ) { jsonArray in
                                newRefObjs = self.reduceToIdsLmts(jsonArray)
                            }
                            operation.execute { (result) -> Void in
                                switch result {
                                case .success:
                                    if self.mustRemoveCachedRecords,
                                        let refObjs = newRefObjs
                                    {
                                        self.removeCachedRecords(
                                            cache,
                                            keys: refObjs.keys,
                                            deleted: deltaSet.deleted
                                        )
                                    }
                                    self.executeLocal {
                                        switch $0 {
                                        case .success(let results):
                                            resolver.fulfill(results)
                                        case .failure(let error):
                                            resolver.reject(error)
                                        }
                                    }
                                case .failure(let error):
                                    resolver.reject(error)
                                }
                            }
                        } else {
                            self.executeLocal {
                                switch $0 {
                                case .success(let results):
                                    resolver.fulfill(results)
                                case .failure(let error):
                                    resolver.reject(error)
                                }
                            }
                        }
                    } else {
                        func convert(_ jsonArray: [JsonDictionary]) -> AnyRandomAccessCollection<T> {
                            let startTime = CFAbsoluteTimeGetCurrent()
                            let entities = AnyRandomAccessCollection(jsonArray.lazy.map { (json) -> T in
                                guard let entity = T(JSON: json, context: self.validationStrategy) else {
                                    fatalError("Invalid entity creation: \(T.self)\n\(json)")
                                }
                                return entity
                            })
                            log.debug("Time elapsed: \(CFAbsoluteTimeGetCurrent() - startTime) s")
                            return entities
                        }
                        let entities = convert(jsonArray)
                        if let cache = self.cache {
                            if self.mustRemoveCachedRecords {
                                let refObjs = self.reduceToIdsLmts(jsonArray)
                                let deltaSet = self.computeDeltaSet(
                                    self.query,
                                    refObjs: refObjs
                                )
                                self.removeCachedRecords(
                                    cache,
                                    keys: refObjs.keys,
                                    deleted: deltaSet.deleted
                                )
                            }
                            if let cache = cache.dynamic {
                                cache.save(entities: AnyRandomAccessCollection(jsonArray))
                            } else {
                                cache.save(entities: entities)
                            }
                        }
                        resolver.fulfill(entities)
                    }
                } else {
                    resolver.reject(buildError(data, response, error, self.client))
                }
            }
            multiRequest.progress.addChild(request.progress, withPendingUnitCount: 99)
        }
    }
    
    @discardableResult
    func executeNetwork(_ completionHandler: CompletionHandler? = nil) -> AnyRequest<ResultType> {
        let request = MultiRequest<ResultType>()
        request.progress = Progress(totalUnitCount: 100)
        count(multiRequest: request).then { (count) -> Promise<AnyRandomAccessCollection<T>> in
            request.progress.completedUnitCount = 1
            if let count = count {
                return self.fetchAutoPagination(multiRequest: request, count: count)
            } else {
                return self.fetch(multiRequest: request)
            }
        }.done { results in
            let result: ResultType = .success(results)
            if self.mustSetRequestResult {
                request.result = result
            }
            completionHandler?(result)
        }.catch {
            let result: ResultType = .failure($0)
            if self.mustSetRequestResult {
                request.result = result
            }
            completionHandler?(result)
        }
        return AnyRequest(request)
    }
    
    fileprivate func removeCachedRecords<S : Sequence>(_ cache: AnyCache<T>, keys: S, deleted: Set<String>) where S.Iterator.Element == String {
        let refKeys = Set<String>(keys)
        let deleted = deleted.subtracting(refKeys)
        if deleted.count > 0 {
            let query = Query(format: "\(T.entityIdProperty()) IN %@", deleted as AnyObject)
            cache.remove(byQuery: query)
        }
    }
    
}
