//
//  FindOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVFindOperation)
internal class FindOperation: ReadOperation {
    
    let query: Query
    let deltaSet: Bool
    
    typealias ResultsHandler = ([JsonDictionary]) -> Void
    let resultsHandler: ResultsHandler?
    
    init(query: Query, deltaSet: Bool, readPolicy: ReadPolicy, persistableType: Persistable.Type, cache: Cache, client: Client, resultsHandler: ResultsHandler? = nil) {
        self.query = query
        self.deltaSet = deltaSet
        self.resultsHandler = resultsHandler
        super.init(readPolicy: readPolicy, persistableType: persistableType, cache: cache, client: client)
    }
    
    override func executeLocal(completionHandler: CompletionHandler? = nil) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            let json = self.cache.findEntityByQuery(self.query)
            let array = self.fromJson(jsonArray: json)
            completionHandler?(array, nil)
        }
        return request
    }
    
    override func executeNetwork(completionHandler: CompletionHandler? = nil) -> Request {
        let fields: Set<String>? = deltaSet ? [PersistableIdKey, "\(PersistableMetadataKey).\(Metadata.LmtKey)"] : nil
        let request = client.networkRequestFactory.buildAppDataFindByQuery(collectionName: persistableType.kinveyCollectionName(), query: query, fields: fields)
        request.execute() { data, response, error in
            if let response = response where response.isResponseOK,
                let jsonArray = self.client.responseParser.parseArray(data)
            {
                self.resultsHandler?(jsonArray)
                if !self.cache.isEmpty() && self.deltaSet {
                    let refObjs = self.reduceToIdsLmts(jsonArray)
                    let deltaSet = self.computeDeltaSet(self.query, refObjs: refObjs)
                    var allIds = Set<String>()
                    allIds.unionInPlace(deltaSet.created)
                    allIds.unionInPlace(deltaSet.updated)
                    allIds.unionInPlace(deltaSet.deleted)
                    let query = Query(format: "\(PersistableIdKey) IN %@", allIds)
                    var newRefObjs: [String : String]? = nil
                    let operation = FindOperation(query: query, deltaSet: false, readPolicy: .ForceNetwork, persistableType: self.persistableType, cache: self.cache, client: self.client) { jsonArray in
                        newRefObjs = self.reduceToIdsLmts(jsonArray)
                    }
                    operation.execute { (results, error) -> Void in
                        if let _ = results {
                            if let refObjs = newRefObjs {
                                let refKeys = Set<String>(refObjs.keys)
                                let deleted = deltaSet.deleted.subtract(refKeys)
                                if deleted.count > 0 {
                                    let query = Query(format: "\(self.persistableType.idKey) IN %@", deleted)
                                    self.cache.removeEntitiesByQuery(query)
                                }
                            }
                            self.executeLocal(completionHandler)
                        } else if let error = error {
                            completionHandler?(nil, error)
                        } else {
                            completionHandler?(nil, Error.InvalidResponse)
                        }
                    }
                } else {
                    let persistableArray = self.persistableType.fromJson(jsonArray)
                    let persistableJson = self.merge(persistableArray, jsonArray: jsonArray)
                    self.cache.saveEntities(persistableJson)
                    completionHandler?(persistableArray, nil)
                }
            } else if let error = error {
                completionHandler?(nil, error)
            } else {
                completionHandler?(nil, Error.InvalidResponse)
            }
        }
        return request
    }
    
}
