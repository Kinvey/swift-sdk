//
//  PushOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

internal class PushOperation<T: Persistable where T: NSObject>: SyncOperation<T, UInt, [ErrorType]?> {
    
    internal override init(sync: Sync<T>?, cache: Cache<T>?, client: Client) {
        super.init(sync: sync, cache: cache, client: client)
    }
    
    override func execute(timeout timeout: NSTimeInterval? = nil, completionHandler: CompletionHandler?) -> Request {
        let requests = OperationQueueRequest()
        requests.operationQueue.maxConcurrentOperationCount = 1
        var count = UInt(0)
        var errors = [ErrorType]()
        if let sync = sync {
            let executor = Executor()
            for pendingOperation in sync.pendingOperations() {
                let request = HttpRequest(request: pendingOperation.buildRequest(), timeout: timeout, client: client)
                let operation = NSBlockOperation {
                    let condition = NSCondition()
                    condition.lock()
                    request.execute() { data, response, error in
                        condition.lock()
                        if let response = response where response.isResponseOK,
                            let data = data
                        {
                            let json = self.client.responseParser.parse(data)
                            var objectId: String?
                            executor.executeAndWait {
                                objectId = pendingOperation.objectId
                            }
                            if let cache = self.cache, let json = json, let objectId = objectId where request.request.HTTPMethod != "DELETE" {
                                if let entity = cache.findEntity(objectId) {
                                    cache.removeEntity(entity)
                                }
                                
                                let persistable = T(JSON: json)
                                if let persistable = persistable {
                                    cache.saveEntity(persistable)
                                }
                            }
                            if request.request.HTTPMethod != "DELETE" {
                                self.sync?.removePendingOperation(pendingOperation)
                                count += 1
                            } else if let json = json, let _count = json["count"] as? UInt {
                                self.sync?.removePendingOperation(pendingOperation)
                                count += _count
                            } else {
                                errors.append(Error.InvalidResponse)
                            }
                        } else if let response = response where response.isResponseUnauthorized,
                            let data = data,
                            let json = self.client.responseParser.parse(data) as? [String : String]
                        {
                            let error = Error.buildUnauthorized(json)
                            switch error {
                            case .Unauthorized(let error, _):
                                if error == Error.InsufficientCredentials {
                                    self.sync?.removePendingOperation(pendingOperation)
                                }
                            default:
                                break
                            }
                            errors.append(error)
                        } else if let error = error {
                            errors.append(error)
                        } else {
                            errors.append(Error.InvalidResponse)
                        }
                        condition.signal()
                        condition.unlock()
                    }
                    condition.wait()
                    condition.unlock()
                }
                requests.operationQueue.addOperation(operation)
            }
        }
        requests.operationQueue.addOperationWithBlock {
            completionHandler?(count, errors.count > 0 ? errors : nil)
        }
        return requests
    }
    
}
