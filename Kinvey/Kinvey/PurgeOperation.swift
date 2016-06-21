//
//  PurgeOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

internal class PurgeOperation<T: Persistable where T: NSObject>: SyncOperation<T, UInt?, ErrorType?> {
    
    internal override init(sync: Sync<T>?, cache: Cache<T>?, client: Client) {
        super.init(sync: sync, cache: cache, client: client)
    }
    
    override func execute(timeout timeout: NSTimeInterval? = nil, completionHandler: CompletionHandler?) -> Request {
        let requests = MultiRequest()
        var promises: [Promise<Void>] = []
        if let sync = sync {
            for pendingOperation in sync.pendingOperations() {
                let urlRequest = pendingOperation.buildRequest()
                if let timeout = timeout {
                    urlRequest.timeoutInterval = timeout
                }
                switch HttpMethod.parse(urlRequest.HTTPMethod).requestType {
                case .Update:
                    if let objectId = pendingOperation.objectId {
                        promises.append(Promise<Void> { fulfill, reject in
                            let request = client.networkRequestFactory.buildAppDataGetById(collectionName: T.kinveyCollectionName(), id: objectId)
                            requests.addRequest(request)
                            request.execute() { data, response, error in
                                if let response = response where response.isResponseOK, let json = self.client.responseParser.parse(data) {
                                    if let cache = self.cache {
                                        let persistable = T(JSON: json)
                                        //                                    let persistableJson = self.merge(persistable, json: json)
                                        //                                    cache.saveEntity(persistableJson)
                                    }
                                    self.sync?.removePendingOperation(pendingOperation)
                                    fulfill()
                                } else if let error = error {
                                    reject(error)
                                } else {
                                    reject(Error.InvalidResponse)
                                }
                            }
                            })
                    } else {
                        sync.removePendingOperation(pendingOperation)
                    }
                case .Delete:
                    promises.append(Promise<Void> { fulfill, reject in
                        sync.removePendingOperation(pendingOperation)
                        fulfill()
                        })
                case .Create:
                    promises.append(Promise<Void> { fulfill, reject in
                        if let objectId = pendingOperation.objectId {
                            let query = Query(format: "\(T.kinveyObjectIdPropertyName()) == %@", objectId)
                            cache?.removeEntitiesByQuery(query)
                        }
                        sync.removePendingOperation(pendingOperation)
                        fulfill()
                        })
                default:
                    break
                }
            }
        }
        
        when(promises).thenInBackground { results in
            completionHandler?(UInt(results.count), nil)
        }.error { error in
            completionHandler?(nil, error)
        }
        return requests
    }
    
}
