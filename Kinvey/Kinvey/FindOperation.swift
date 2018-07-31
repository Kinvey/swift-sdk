//
//  FindOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

private let MaxIdsPerQuery = 200
private let MaxSizePerResultSet = 10_000

internal class FindOperation<T: Persistable>: ReadOperation<T, AnyRandomAccessCollection<T>, Swift.Error>, ReadOperationType where T: NSObject {
    
    let query: Query
    var deltaSet: Bool {
        return options?.deltaSet ?? false
    }
    let deltaSetCompletionHandler: ((AnyRandomAccessCollection<T>, AnyRandomAccessCollection<T>) -> Void)?
    let autoPagination: Bool
    let mustSetRequestResult: Bool
    let mustSaveQueryLastSync: Bool?
    
    typealias ResultType = Result<AnyRandomAccessCollection<T>, Swift.Error>
    
    lazy var isEmptyQuery: Bool = {
        return (self.query.predicate == nil || self.query.predicate == NSPredicate()) && self.query.skip == nil && self.query.limit == nil
    }()
    
    var mustRemoveCachedRecords: Bool {
        return isEmptyQuery
    }
    
    var isSkipAndLimitNil: Bool {
        return query.skip == nil && query.limit == nil
    }
    
    typealias ResultsHandler = ([JsonDictionary]) -> Void
    let resultsHandler: ResultsHandler?
    
    init(
        query: Query,
        deltaSetCompletionHandler: ((AnyRandomAccessCollection<T>, AnyRandomAccessCollection<T>) -> Void)? = nil,
        autoPagination: Bool,
        readPolicy: ReadPolicy,
        validationStrategy: ValidationStrategy?,
        cache: AnyCache<T>?,
        options: Options?,
        mustSetRequestResult: Bool = true,
        mustSaveQueryLastSync: Bool? = nil,
        resultsHandler: ResultsHandler? = nil
    ) {
        if autoPagination, query.skip != nil {
            query.skip = nil
        }
        if autoPagination, query.limit != nil {
            query.limit = nil
        }
        self.query = query
        self.deltaSetCompletionHandler = deltaSetCompletionHandler
        self.autoPagination = autoPagination
        self.resultsHandler = resultsHandler
        self.mustSetRequestResult = mustSetRequestResult
        self.mustSaveQueryLastSync = mustSaveQueryLastSync ?? (query.skip == nil && query.limit == nil)
        
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
    
    private func count(multiRequest: MultiRequest<ResultType>) -> Promise<Int?> {
        return Promise<Int?> { resolver in
            if !deltaSet, autoPagination {
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
            var mustSaveQueryLastSync = self.mustSaveQueryLastSync ?? true
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
                        autoPagination: false,
                        readPolicy: .forceNetwork,
                        validationStrategy: self.validationStrategy,
                        cache: self.cache,
                        options: try Options(self.options, deltaSet: false),
                        mustSetRequestResult: false,
                        mustSaveQueryLastSync: mustSaveQueryLastSync
                    )
                    if mustSaveQueryLastSync {
                        mustSaveQueryLastSync = false
                    }
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
            cache?.beginWrite()
            when(fulfilled: promisesIterator, concurrently: urlSessionConfiguration.httpMaximumConnectionsPerHost).done(on: DispatchQueue.global(qos: .default)) { results -> Void in
                let result: AnyRandomAccessCollection<T>
                if let cache = self.cache {
                    try cache.commitWrite()
                    result = cache.find(byQuery: self.query)
                } else {
                    result = AnyRandomAccessCollection(results.lazy.flatMap { $0 })
                }
                progress.completedUnitCount += 1
                resolver.fulfill(result)
            }.catch { error in
                self.cache?.cancelWrite()
                resolver.reject(error)
            }
        }
    }
    
    func convertToEntities(fromJsonArray jsonArray: [JsonDictionary]) throws -> AnyRandomAccessCollection<T> {
        let startTime = CFAbsoluteTimeGetCurrent()
        let client = options?.client ?? self.client
        let entities = AnyRandomAccessCollection(try jsonArray.lazy.map { (json) throws -> T in
            if let validationStrategy = self.validationStrategy {
                try validationStrategy.validate(jsonArray: [json])
            } else {
                guard let entityId = json[Entity.EntityCodingKeys.entityId.rawValue] as? String, !entityId.isEmpty else {
                    throw Error.invalidOperation(description: "_id is required: \(T.self)\n\(json)")
                }
            }
            guard let entity = try? client.jsonParser.parseObject(T.self, from: json) else {
                throw Error.invalidOperation(description: "Invalid entity creation: \(T.self)\n\(json)")
            }
            return entity
        })
        log.debug("Time elapsed: \(CFAbsoluteTimeGetCurrent() - startTime) s")
        return entities
    }
    
    private func fetchDelta(multiRequest: MultiRequest<ResultType>, sinceDate: Date) -> Promise<AnyRandomAccessCollection<T>> {
        return Promise<AnyRandomAccessCollection<T>> { resolver in
            let request = client.networkRequestFactory.buildAppDataFindByQueryDeltaSet(
                collectionName: try! T.collectionName(),
                query: query,
                sinceDate: sinceDate,
                options: options
            )
            request.execute() { data, response, error in
                if let response = response,
                    response.isOK,
                    let cache = self.cache,
                    let data = data,
                    let anyObject = try? JSONSerialization.jsonObject(with: data),
                    let results = anyObject as? [String : [JsonDictionary]],
                    let changed = results["changed"],
                    let deleted = results["deleted"],
                    let requestStart = response.requestStartHeader
                {
                    do {
                        let deletedEntities = try self.convertToEntities(fromJsonArray: deleted)
                        let changedEntities = try self.convertToEntities(fromJsonArray: changed)
                        cache.remove(entities: deletedEntities)
                        cache.save(entities: changedEntities, syncQuery: (query: self.query, lastSync: requestStart))
                        if let deltaSetCompletionHandler = self.deltaSetCompletionHandler {
                            DispatchQueue.main.async {
                                deltaSetCompletionHandler(changedEntities, deletedEntities)
                            }
                        }
                        self.executeLocal {
                            switch $0 {
                            case .success(let results):
                                resolver.fulfill(results)
                            case .failure(let error):
                                resolver.reject(error)
                            }
                        }
                    } catch {
                        resolver.reject(error)
                    }
                } else {
                    let error = buildError(data, response, error, self.client)
                    if let error = error as? Kinvey.Error {
                        switch error {
                        case .resultSetSizeExceeded:
                            if self.autoPagination {
                                fallthrough
                            } else {
                                resolver.reject(error)
                            }
                        case .parameterValueOutOfRange:
                            self.cache?.invalidateLastSync(query: self.query)
                            self.executeNetwork { (result: Result<AnyRandomAccessCollection<T>, Swift.Error>) in
                                switch result {
                                case .success(let entities):
                                    resolver.fulfill(entities)
                                case .failure(let error):
                                    resolver.reject(error)
                                }
                            }
                        default:
                            resolver.reject(error)
                        }
                    } else {
                        resolver.reject(error)
                    }
                }
            }
            multiRequest.progress.addChild(request.progress, withPendingUnitCount: 99)
            multiRequest += request
        }.recover { (error) -> Promise<AnyRandomAccessCollection<T>> in
            if let cache = self.cache,
                let error = error as? Kinvey.Error
            {
                switch error {
                case .missingConfiguration:
                    cache.clear(syncQueries: nil)
                    self.options = try Options(self.options, deltaSet: false)
                    return self.fetchAllAutoPagination(multiRequest: multiRequest)
                default:
                    break
                }
            }
            return Promise<AnyRandomAccessCollection<T>>(error: error)
        }
    }
    
    private func fetchAll(multiRequest: MultiRequest<ResultType>) -> Promise<AnyRandomAccessCollection<T>> {
        return Promise<AnyRandomAccessCollection<T>> { resolver in
            let request = client.networkRequestFactory.buildAppDataFindByQuery(
                collectionName: try! T.collectionName(),
                query: query,
                options: options
            )
            request.execute() { data, response, error in
                if let response = response,
                    response.isOK,
                    let data = data,
                    let jsonArray = try? self.client.jsonParser.parseDictionaries(from: data)
                {
                    if let validationStrategy = self.validationStrategy {
                        do {
                            try validationStrategy.validate(jsonArray: jsonArray)
                        } catch {
                            resolver.reject(error)
                            return
                        }
                    }
                    self.resultsHandler?(jsonArray)
                    do {
                        let entities = try self.convertToEntities(fromJsonArray: jsonArray)
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
                            var syncQuery: CacheType.SyncQuery? = nil
                            if self.mustSaveQueryLastSync ?? true, let requestStart = response.requestStartHeader {
                                syncQuery = (query: self.query, lastSync: requestStart)
                            }
                            if !(T.self is Codable.Type), let cache = cache.dynamic {
                                cache.save(entities: AnyRandomAccessCollection(jsonArray), syncQuery: syncQuery)
                            } else {
                                cache.save(entities: entities, syncQuery: syncQuery)
                            }
                        }
                        resolver.fulfill(entities)
                    } catch {
                        resolver.reject(error)
                    }
                } else {
                    resolver.reject(buildError(data, response, error, self.client))
                }
            }
            multiRequest.progress.addChild(request.progress, withPendingUnitCount: 99)
            multiRequest += request
        }
    }
    
    private func fetch(multiRequest: MultiRequest<ResultType>) -> Promise<AnyRandomAccessCollection<T>> {
        let deltaSet = self.deltaSet && isSkipAndLimitNil
        if deltaSet, let sinceDate = cache?.lastSync(query: query) {
            return fetchDelta(multiRequest: multiRequest, sinceDate: sinceDate)
        } else if deltaSet, autoPagination {
            return Promise<Int> { resolver in
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
            }.then {
                return self.fetchAutoPagination(multiRequest: multiRequest, count: $0)
            }
        } else {
            return fetchAll(multiRequest: multiRequest)
        }
    }
    
    func fetchAllAutoPagination(multiRequest: MultiRequest<ResultType>) -> Promise<AnyRandomAccessCollection<T>> {
        return self.count(multiRequest: multiRequest).then { (count) -> Promise<AnyRandomAccessCollection<T>> in
            if let count = count {
                return self.fetchAutoPagination(multiRequest: multiRequest, count: count)
            } else {
                return self.fetchAll(multiRequest: multiRequest)
            }
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
            let query = Query(format: "\(try! T.entityIdProperty()) IN %@", deleted as AnyObject)
            cache.remove(byQuery: query)
        }
    }
    
}
