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

internal class FindOperation<T: Persistable>: ReadOperation<T, [T], Swift.Error>, ReadOperationType where T: NSObject {
    
    let query: Query
    let deltaSet: Bool
    let deltaSetCompletionHandler: (([T]) -> Void)?
    
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
        deltaSetCompletionHandler: (([T]) -> Void)? = nil,
        readPolicy: ReadPolicy,
        cache: AnyCache<T>?,
        options: Options?,
        resultsHandler: ResultsHandler? = nil
    ) {
        self.query = query
        self.deltaSet = deltaSet
        self.deltaSetCompletionHandler = deltaSetCompletionHandler
        self.resultsHandler = resultsHandler
        super.init(
            readPolicy: readPolicy,
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
                completionHandler?(.success([]))
            }
        }
        return request
    }
    
    typealias ArrayCompletionHandler = ([Any]?, Error?) -> Void
    
    @discardableResult
    func executeNetwork(_ completionHandler: CompletionHandler? = nil) -> Request {
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
                self.resultsHandler?(jsonArray)
                if let cache = self.cache, deltaSet {
                    let refObjs = self.reduceToIdsLmts(jsonArray)
                    let deltaSet = self.computeDeltaSet(self.query, refObjs: refObjs)
                    var allIds = Set<String>(minimumCapacity: deltaSet.created.count + deltaSet.updated.count + deltaSet.deleted.count)
                    allIds.formUnion(deltaSet.created)
                    allIds.formUnion(deltaSet.updated)
                    allIds.formUnion(deltaSet.deleted)
                    if allIds.count > MaxIdsPerQuery {
                        let allIds = Array<String>(allIds)
                        var promises = [Promise<[T]>]()
                        var newRefObjs = [String : String]()
                        for offset in stride(from: 0, to: allIds.count, by: MaxIdsPerQuery) {
                            let limit = min(offset + MaxIdsPerQuery, allIds.count - 1)
                            let allIds = Set<String>(allIds[offset...limit])
                            let promise = Promise<[T]> { fulfill, reject in
                                let query = Query(format: "\(Entity.Key.entityId) IN %@", allIds)
                                let operation = FindOperation<T>(
                                    query: query,
                                    deltaSet: false,
                                    readPolicy: .forceNetwork,
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
                                        fulfill(results)
                                    case .failure(let error):
                                        reject(error)
                                    }
                                }
                            }
                            promises.append(promise)
                        }
                        when(fulfilled: promises).then { results -> Void in
                            if self.mustRemoveCachedRecords {
                                self.removeCachedRecords(
                                    cache,
                                    keys: refObjs.keys,
                                    deleted: deltaSet.deleted
                                )
                            }
                            if let deltaSetCompletionHandler = self.deltaSetCompletionHandler {
                                deltaSetCompletionHandler(results.flatMap { $0 })
                            }
                            self.executeLocal(completionHandler)
                        }.catch { error in
                            completionHandler?(.failure(error))
                        }
                    } else if allIds.count > 0 {
                        let query = Query(format: "\(Entity.Key.entityId) IN %@", allIds)
                        var newRefObjs: [String : String]? = nil
                        let operation = FindOperation<T>(
                            query: query,
                            deltaSet: false,
                            readPolicy: .forceNetwork,
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
                                self.executeLocal(completionHandler)
                            case .failure(let error):
                                completionHandler?(.failure(buildError(data, response, error, self.client)))
                            }
                        }
                    } else {
                        self.executeLocal(completionHandler)
                    }
                } else {
                    func convert(_ jsonArray: [JsonDictionary]) -> [T] {
                        let startTime = CFAbsoluteTimeGetCurrent()
                        let entities = [T](JSONArray: jsonArray)
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
                        cache.save(entities: entities)
                    }
                    completionHandler?(.success(entities))
                }
            } else {
                completionHandler?(.failure(buildError(data, response, error, self.client)))
            }
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
