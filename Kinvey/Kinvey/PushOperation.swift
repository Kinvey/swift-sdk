//
//  PushOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

@objc(__KNVPushOperation)
internal class PushOperation: SyncOperation {
    
    override func execute(completionHandler: CompletionHandler?) -> Request {
        let requests = MultiRequest()
        var promises: [Promise<NSData>] = []
        for pendingOperation in sync.pendingOperations() {
            let request = HttpRequest(request: pendingOperation.buildRequest(), client: client)
            requests.addRequest(request)
            promises.append(Promise<NSData> { fulfill, reject in
                request.execute() { data, response, error in
                    if let response = response where response.isResponseOK, let data = data {
                        let json = self.client.responseParser.parse(data)
                        if let json = json, let objectId = pendingOperation.objectId where request.request.HTTPMethod != "DELETE" {
                            if let entity = self.cache.findEntity(objectId) {
                                self.cache.removeEntity(entity)
                            }
                            
                            let persistable = self.persistableType.fromJson(json)
                            let persistableJson = self.merge(persistable, json: json)
                            self.cache.saveEntity(persistableJson)
                        }
                        if request.request.HTTPMethod != "DELETE" {
                            self.sync.removePendingOperation(pendingOperation)
                            fulfill(data)
                        } else if let json = json, let count = json["count"] as? UInt where count > 0 {
                            self.sync.removePendingOperation(pendingOperation)
                            fulfill(data)
                        } else {
                            reject(Error.InvalidResponse)
                        }
                    } else if let error = error {
                        reject(error)
                    } else {
                        reject(Error.InvalidResponse)
                    }
                }
            })
        }
        when(promises).thenInBackground { results in
            completionHandler?(UInt(results.count), nil)
        }.error { error in
            completionHandler?(nil, error)
        }
        return requests
    }
    
}
