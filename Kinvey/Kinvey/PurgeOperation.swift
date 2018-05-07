//
//  PurgeOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

internal class PurgeOperation<T: Persistable>: SyncOperation<T, Int, Swift.Error> where T: NSObject {
    
    typealias ResultType = Result<Int, Swift.Error>
    
    internal override init(
        sync: AnySync?,
        cache: AnyCache<T>?,
        options: Options?
    ) {
        super.init(
            sync: sync,
            cache: cache,
            options: options
        )
    }
    
    func execute(timeout: TimeInterval? = nil, completionHandler: CompletionHandler?) -> AnyRequest<ResultType> {
        let requests = MultiRequest<ResultType>()
        var promises: [Promise<Void>] = []
        if let sync = sync {
            for pendingOperation in sync.pendingOperations() {
                var urlRequest = pendingOperation.buildRequest()
                if let timeout = timeout {
                    urlRequest.timeoutInterval = timeout
                }
                switch HttpMethod.parse(urlRequest.httpMethod ?? "GET").requestType {
                case .update:
                    if let objectId = pendingOperation.objectId {
                        promises.append(Promise<Void> { resolver in
                            let request = client.networkRequestFactory.buildAppDataGetById(
                                collectionName: T.collectionName(),
                                id: objectId,
                                options: options,
                                resultType: ResultType.self
                            )
                            requests.addRequest(request)
                            request.execute() { data, response, error in
                                if let response = response, response.isOK,
                                    let json = self.client.responseParser.parse(data)
                                {
                                    if let cache = self.cache, let persistable = T(JSON: json) {
                                        cache.save(entity: persistable)
                                    }
                                    self.sync?.removePendingOperation(pendingOperation)
                                    resolver.fulfill(())
                                } else {
                                    resolver.reject(buildError(data, response, error, self.client))
                                }
                            }
                        })
                    } else {
                        sync.removePendingOperation(pendingOperation)
                    }
                case .delete:
                    promises.append(Promise<Void> { resolver in
                        sync.removePendingOperation(pendingOperation)
                        resolver.fulfill(())
                    })
                case .create:
                    promises.append(Promise<Void> { resolver in
                        if let objectId = pendingOperation.objectId {
                            let query = Query(format: "\(T.entityIdProperty()) == %@", objectId)
                            cache?.remove(byQuery: query)
                        }
                        sync.removePendingOperation(pendingOperation)
                        resolver.fulfill(())
                    })
                default:
                    break
                }
            }
        }
        
        when(fulfilled: promises).done { (results: [Void]) -> Void in
            let result: ResultType = .success(results.count)
            requests.result = result
            completionHandler?(result)
        }.catch { error in
            let result: ResultType = .failure(error)
            requests.result = result
            completionHandler?(result)
        }
        return AnyRequest(requests)
    }
    
}
