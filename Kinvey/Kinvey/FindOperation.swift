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
    
    var isSkipAndLimitNil: Bool {
        return query.skip == nil && query.limit == nil
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
        return Promise<Int?> { fulfill, reject in
            if autoPagination {
                if let limit = query.limit {
                    fulfill(limit)
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
                            fulfill(count)
                        case .failure(let error):
                            reject(error)
                        }
                    }
                    multiRequest.progress.addChild(request.progress, withPendingUnitCount: 1)
                    multiRequest += request
                }
            } else {
                fulfill(nil)
            }
        }
    }
    
    private func fetchAutoPagination(multiRequest: MultiRequest<ResultType>, count: Int) -> Promise<AnyRandomAccessCollection<T>> {
        return Promise<AnyRandomAccessCollection<T>> { fulfill, reject in
            let maxSizePerResultSet = options?.maxSizePerResultSet ?? MaxSizePerResultSet
            let nPages = Int64(ceil(Double(count) / Double(maxSizePerResultSet)))
            let progress = Progress(totalUnitCount: nPages + 1, parent: multiRequest.progress, pendingUnitCount: 99)
            var offsetIterator = stride(from: 0, to: count, by: maxSizePerResultSet).makeIterator()
            let isCacheNotNil = cache != nil
            let promisesIterator = AnyIterator<Promise<AnyRandomAccessCollection<T>>> {
                guard let offset = offsetIterator.next() else {
                    return nil
                }
                return Promise<AnyRandomAccessCollection<T>> { fulfill, reject in
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
                            fulfill(isCacheNotNil ? AnyRandomAccessCollection<T>([]) : results)
                        case .failure(let error):
                            reject(error)
                        }
                    }
                    progress.addChild(request.progress, withPendingUnitCount: 1)
                    multiRequest += request
                }
            }
            let urlSessionConfiguration = options?.urlSession?.configuration ?? client.urlSession.configuration
            when(fulfilled: promisesIterator, concurrently: urlSessionConfiguration.httpMaximumConnectionsPerHost).then(on: DispatchQueue.global(qos: .default)) { results -> Void in
                let result: AnyRandomAccessCollection<T>
                if let cache = self.cache {
                    result = cache.find(byQuery: self.query)
                } else {
                    result = AnyRandomAccessCollection(results.lazy.flatMap { $0 })
                }
                progress.completedUnitCount += 1
                fulfill(result)
            }.catch { error in
                reject(error)
            }
        }
    }
    
    func convertToEntities(fromJsonArray jsonArray: [JsonDictionary]) -> AnyRandomAccessCollection<T> {
        let startTime = CFAbsoluteTimeGetCurrent()
        let entities = AnyRandomAccessCollection(jsonArray.lazy.map { (json) -> T in
            guard let entity = T(JSON: json) else {
                fatalError("_id is required")
            }
            return entity
        })
        log.debug("Time elapsed: \(CFAbsoluteTimeGetCurrent() - startTime) s")
        return entities
    }
    
    private func fetchDelta(multiRequest: MultiRequest<ResultType>, sinceDate: Date) -> Promise<AnyRandomAccessCollection<T>> {
        return Promise<AnyRandomAccessCollection<T>> { fulfill, reject in
            let request = client.networkRequestFactory.buildAppDataFindByQueryDeltaSet(
                collectionName: T.collectionName(),
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
                    cache.remove(entities: self.convertToEntities(fromJsonArray: deleted))
                    cache.save(entities: self.convertToEntities(fromJsonArray: changed), syncQuery: (query: self.query, lastSync: requestStart))
                    self.executeLocal {
                        switch $0 {
                        case .success(let results):
                            fulfill(results)
                        case .failure(let error):
                            reject(error)
                        }
                    }
                } else {
                    let error = buildError(data, response, error, self.client)
                    if let error = error as? Kinvey.Error {
                        switch error {
                        case .parameterValueOutOfRange:
                            self.cache?.invalidateLastSync(query: self.query)
                            self.executeNetwork { (result: Result<AnyRandomAccessCollection<T>, Swift.Error>) in
                                switch result {
                                case .success(let entities):
                                    fulfill(entities)
                                case .failure(let error):
                                    reject(error)
                                }
                            }
                        default:
                            reject(error)
                        }
                    } else {
                        reject(error)
                    }
                }
            }
            multiRequest.progress.addChild(request.progress, withPendingUnitCount: 99)
        }
    }
    
    private func fetchAll(multiRequest: MultiRequest<ResultType>) -> Promise<AnyRandomAccessCollection<T>> {
        return Promise<AnyRandomAccessCollection<T>> { fulfill, reject in
            let request = client.networkRequestFactory.buildAppDataFindByQuery(
                collectionName: T.collectionName(),
                query: query,
                options: options
            )
            request.execute() { data, response, error in
                if let response = response, response.isOK,
                    let jsonArray = self.client.responseParser.parseArray(data)
                {
                    if let validationStrategy = self.validationStrategy,
                        let error = validationStrategy.validate(jsonArray: jsonArray)
                    {
                        reject(error)
                        return
                    }
                    self.resultsHandler?(jsonArray)
                    let entities = self.convertToEntities(fromJsonArray: jsonArray)
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
                        var syncQuery: (query: Query, lastSync: Date)? = nil
                        if self.deltaSet, self.isSkipAndLimitNil, let requestStart = response.requestStartHeader {
                            syncQuery = (query: self.query, lastSync: requestStart)
                        }
                        if let cache = cache.dynamic {
                            cache.save(entities: AnyRandomAccessCollection(jsonArray), syncQuery: syncQuery)
                        } else {
                            cache.save(entities: entities, syncQuery: syncQuery)
                        }
                    }
                    fulfill(entities)
                } else {
                    reject(buildError(data, response, error, self.client))
                }
            }
            multiRequest.progress.addChild(request.progress, withPendingUnitCount: 99)
        }
    }
    
    private func fetch(multiRequest: MultiRequest<ResultType>) -> Promise<AnyRandomAccessCollection<T>> {
        let deltaSet = self.deltaSet &&
            isSkipAndLimitNil &&
            !(cache?.isEmpty() ?? true)
        if deltaSet, let sinceDate = cache?.lastSync(query: query) {
            return fetchDelta(multiRequest: multiRequest, sinceDate: sinceDate)
        } else {
            return fetchAll(multiRequest: multiRequest)
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
        }.then { (results) -> Void in
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
