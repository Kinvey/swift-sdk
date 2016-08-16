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

internal class FindOperation<T: Persistable where T: NSObject>: ReadOperation<T> {
    
    let query: Query
    let deltaSet: Bool
    
    lazy var isEmptyQuery: Bool = {
        return self.query.predicate == nil || self.query.predicate == NSPredicate()
    }()
    
    var mustRemoveCachedRecords: Bool {
        get {
            return isEmptyQuery
        }
    }
    
    typealias ResultsHandler = ([JsonDictionary]) -> Void
    let resultsHandler: ResultsHandler?
    
    init(query: Query, deltaSet: Bool, readPolicy: ReadPolicy, cache: Cache<T>?, client: Client, resultsHandler: ResultsHandler? = nil) {
        self.query = query
        self.deltaSet = deltaSet
        self.resultsHandler = resultsHandler
        super.init(readPolicy: readPolicy, cache: cache, client: client)
    }
    
    override func executeLocal(completionHandler: CompletionHandler? = nil) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            if let cache = self.cache {
                let json = cache.findEntityByQuery(self.query)
                completionHandler?(json, nil)
            } else {
                completionHandler?([], nil)
            }
        }
        return request
    }
    
    typealias ArrayCompletionHandler = ([AnyObject]?, ErrorType?) -> Void
    
    override func executeNetwork(completionHandler: CompletionHandler? = nil) -> Request {
        let deltaSet = self.deltaSet && (cache != nil ? !cache!.isEmpty() : false)
        let fields: Set<String>? = deltaSet ? [PersistableIdKey, "\(PersistableMetadataKey).\(Metadata.LmtKey)"] : nil
        let request = client.networkRequestFactory.buildAppDataFindByQuery(collectionName: T.collectionName(), query: query, fields: fields)
        request.execute() { data, response, error in
            if let response = response where response.isOK,
                let jsonArray = self.client.responseParser.parseArray(data)
            {
                self.resultsHandler?(jsonArray)
                if let cache = self.cache where deltaSet {
                    let refObjs = self.reduceToIdsLmts(jsonArray)
                    let deltaSet = self.computeDeltaSet(self.query, refObjs: refObjs)
                    var allIds = Set<String>()
                    allIds.unionInPlace(deltaSet.created)
                    allIds.unionInPlace(deltaSet.updated)
                    allIds.unionInPlace(deltaSet.deleted)
                    if allIds.count > MaxIdsPerQuery {
                        let allIds = Array<String>(allIds)
                        var promises = [Promise<[AnyObject]>]()
                        var newRefObjs = [String : String]()
                        for offset in 0.stride(to: allIds.count, by: MaxIdsPerQuery) {
                            let limit = min(offset + MaxIdsPerQuery, allIds.count - 1)
                            let allIds = Set<String>(allIds[offset...limit])
                            let promise = Promise<[AnyObject]> { fulfill, reject in
                                let query = Query(format: "\(PersistableIdKey) IN %@", allIds)
                                let operation = FindOperation<T>(query: query, deltaSet: false, readPolicy: .ForceNetwork, cache: cache, client: self.client) { jsonArray in
                                    for (key, value) in self.reduceToIdsLmts(jsonArray) {
                                        newRefObjs[key] = value
                                    }
                                }
                                operation.execute { (results, error) -> Void in
                                    if let results = results as? [AnyObject] {
                                        fulfill(results)
                                    } else {
                                        reject(buildError(data, response, error, self.client))
                                    }
                                }
                            }
                            promises.append(promise)
                        }
                        when(promises).thenInBackground { results in
                            if self.mustRemoveCachedRecords {
                                self.removeCachedRecords(cache, keys: refObjs.keys, deleted: deltaSet.deleted)
                            }
                            self.executeLocal(completionHandler)
                        }.error { error in
                            completionHandler?(nil, error)
                        }
                    } else if allIds.count > 0 {
                        let query = Query(format: "\(PersistableIdKey) IN %@", allIds)
                        var newRefObjs: [String : String]? = nil
                        let operation = FindOperation<T>(query: query, deltaSet: false, readPolicy: .ForceNetwork, cache: cache, client: self.client) { jsonArray in
                            newRefObjs = self.reduceToIdsLmts(jsonArray)
                        }
                        operation.execute { (results, error) -> Void in
                            if let _ = results {
                                if self.mustRemoveCachedRecords, let refObjs = newRefObjs {
                                    self.removeCachedRecords(cache, keys: refObjs.keys, deleted: deltaSet.deleted)
                                }
                                self.executeLocal(completionHandler)
                            } else {
                                completionHandler?(nil, buildError(data, response, error, self.client))
                            }
                        }
                    } else {
                        self.executeLocal(completionHandler)
                    }
                } else {
                    let entities = [T](JSONArray: jsonArray)
                    if let entities = entities {
                        if let cache = self.cache {
                            if self.mustRemoveCachedRecords {
                                let refObjs = self.reduceToIdsLmts(jsonArray)
                                let deltaSet = self.computeDeltaSet(self.query, refObjs: refObjs)
                                self.removeCachedRecords(cache, keys: refObjs.keys, deleted: deltaSet.deleted)
                            }
                            cache.saveEntities(entities)
                        }
                        completionHandler?(entities, nil)
                    } else {
                        completionHandler?(nil, buildError(data, response, error, self.client))
                    }
                }
            } else {
                completionHandler?(nil, buildError(data, response, error, self.client))
            }
        }
        return request
    }
    
    private func removeCachedRecords<S : SequenceType where S.Generator.Element == String>(cache: Cache<T>, keys: S, deleted: Set<String>) {
        let refKeys = Set<String>(keys)
        let deleted = deleted.subtract(refKeys)
        if deleted.count > 0 {
            let query = Query(format: "\(T.entityIdProperty()) IN %@", deleted)
            cache.removeEntitiesByQuery(query)
        }
    }
    
}
