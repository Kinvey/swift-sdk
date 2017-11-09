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
        resultsHandler: ResultsHandler? = nil
    ) {
        self.query = query
        self.deltaSet = deltaSet
        self.deltaSetCompletionHandler = deltaSetCompletionHandler
        self.autoPagination = autoPagination
        self.resultsHandler = resultsHandler
        super.init(
            readPolicy: readPolicy,
            validationStrategy: validationStrategy,
            cache: cache,
            options: options
        )
    }
    
    @discardableResult
    func executeLocal(_ completionHandler: CompletionHandler? = nil) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            if let cache = self.cache {
                let json = cache.find(byQuery: self.query)
                completionHandler?(.success(json))
            } else {
                completionHandler?(.success(AnyRandomAccessCollection<T>([])))
            }
        }
        return request
    }
    
    typealias ArrayCompletionHandler = ([Any]?, Error?) -> Void
    
    private func count(multiRequest: MultiRequest) -> Promise<Int?> {
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
    
    private func fetchAutoPagination(multiRequest: MultiRequest, count: Int) -> Promise<AnyRandomAccessCollection<T>> {
        return Promise<AnyRandomAccessCollection<T>> { fulfill, reject in
            let nPages = Int64(ceil(Double(count) / Double(MaxSizePerResultSet)))
            let progress = Progress(totalUnitCount: nPages + 1, parent: multiRequest.progress, pendingUnitCount: 99)
            var offsetIterator = stride(from: 0, to: count, by: MaxSizePerResultSet).makeIterator()
            let promisesIterator = AnyIterator<Promise<AnyRandomAccessCollection<T>>> {
                guard let offset = offsetIterator.next() else {
                    return nil
                }
                return Promise<AnyRandomAccessCollection<T>> { fulfill, reject in
                    let query = Query(self.query)
                    query.skip = offset
                    query.limit = min(MaxSizePerResultSet, count - offset)
                    let operation = FindOperation(
                        query: query,
                        deltaSet: self.deltaSet,
                        autoPagination: false,
                        readPolicy: .forceNetwork,
                        validationStrategy: self.validationStrategy,
                        cache: self.cache,
                        options: self.options
                    )
                    let request = operation.execute { result in
                        switch result {
                        case .success(let results):
                            fulfill(results)
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
                let results = AnyRandomAccessCollection(results.lazy.flatMap { $0 })
                progress.completedUnitCount += 1
                fulfill(results)
            }.catch { error in
                reject(error)
            }
        }
    }
    
    private func fetch(multiRequest: MultiRequest) -> Promise<AnyRandomAccessCollection<T>> {
        return Promise<AnyRandomAccessCollection<T>> { fulfill, reject in
            if deltaSet, let cache = self.cache, let lastPull = cache.lastPull {
                let request = CustomEndpoint.execute(
                    "DeltaSet",
                    params: CustomEndpoint.Params([
                        "collection" : T.collectionName(),
                        "lmt" : lastPull.toString()
                    ]),
                    options: Options(
                        client: client
                    )
                ) { (result: Result<JsonDictionary, Swift.Error>) in
                    switch result {
                    case .success(let results):
                        let dateTransform = KinveyDateTransform()
                        if let dateString = results["date"] as? String,
                            let date = dateTransform.transformFromJSON(dateString),
                            let deleted = results["deleted"] as? [JsonDictionary],
                            let changed = results["changed"] as? [JsonDictionary]
                        {
                            cache.lastPull = date.addingTimeInterval(-5)
                            cache.remove(entities: AnyRandomAccessCollection(Array<T>(JSONArray: deleted)))
                            cache.save(entities: AnyRandomAccessCollection(Array<T>(JSONArray: changed)))
                            self.executeLocal {
                                switch $0 {
                                case .success(let results):
                                    fulfill(results)
                                case .failure(let error):
                                    reject(error)
                                }
                            }
                        } else {
                            reject(Error.invalidResponse(httpResponse: nil, data: nil))
                        }
                    case .failure(let error):
                        reject(error)
                    }
                }
                multiRequest.progress.addChild(request.progress, withPendingUnitCount: 99)
            } else {
                let startTime = Date()
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
                        func convert(_ jsonArray: [JsonDictionary]) -> AnyRandomAccessCollection<T> {
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
                        let entities = convert(jsonArray)
                        if let cache = self.cache {
                            if let cache = cache.dynamic {
                                cache.save(entities: AnyRandomAccessCollection(jsonArray))
                            } else {
                                cache.save(entities: entities)
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
    }
    
    @discardableResult
    func executeNetwork(_ completionHandler: CompletionHandler? = nil) -> Request {
        let request = MultiRequest()
        request.progress = Progress(totalUnitCount: 100)
        count(multiRequest: request).then { (count) -> Promise<AnyRandomAccessCollection<T>> in
            request.progress.completedUnitCount = 1
            if let count = count {
                return self.fetchAutoPagination(multiRequest: request, count: count)
            } else {
                return self.fetch(multiRequest: request)
            }
        }.then {
            completionHandler?(.success($0))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return request
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
