//
//  PurgeOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

@objc(__KNVPurgeOperation)
public class PurgeOperation: SyncOperation {
    
    public init(sync: Sync, persistableType: Persistable.Type, cache: Cache, client: Client) {
        super.init(writePolicy: .ForceNetwork, sync: sync, persistableType: persistableType, cache: cache, client: client)
    }
    
    override func execute(completionHandler: CompletionHandler?) -> Request {
        let requests = MultiRequest()
        var promises: [Promise<Void>] = []
        for pendingOperation in sync.pendingOperations() {
            let urlRequest = pendingOperation.buildRequest()
            if let httpMethod = urlRequest.HTTPMethod {
                switch HttpMethod.parse(httpMethod).requestType {
                case .Update:
                    if let objectId = pendingOperation.objectId {
                        promises.append(Promise<Void> { fulfill, reject in
                            let request = client.networkRequestFactory.buildAppDataGetById(collectionName: self.persistableType.kinveyCollectionName(), id: objectId)
                            requests.addRequest(request)
                            request.execute() { data, response, error in
                                if let response = response where response.isResponseOK, let json = self.client.responseParser.parse(data) {
                                    let persistable = self.persistableType.fromJson(json)
                                    let persistableJson = self.merge(persistable, json: json)
                                    self.cache.saveEntity(persistableJson)
                                    self.sync.removePendingOperation(pendingOperation)
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
                            let query = Query(format: "\(self.persistableType.idKey) == %@", objectId)
                            cache.removeEntitiesByQuery(query)
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
