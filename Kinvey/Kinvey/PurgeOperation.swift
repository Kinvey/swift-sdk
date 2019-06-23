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
    
    typealias ResultType = Swift.Result<Int, Swift.Error>
    
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
                    if let promise = updatePromise(pendingOperation: pendingOperation, requests: requests) {
                        promises.append(promise)
                    } else {
                        sync.remove(pendingOperation: pendingOperation)
                    }
                case .delete:
                    promises.append(deletePromise(pendingOperation: pendingOperation, sync: sync))
                case .create:
                    promises.append(createPromise(pendingOperation: pendingOperation, sync: sync))
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
    
    private func createPromise(pendingOperation: PendingOperation, sync: AnySync) -> Promise<Void> {
        return Promise<Void> { resolver in
            if let objectId = pendingOperation.objectId {
                let query = Query(format: "\(try T.entityIdProperty()) == %@", objectId)
                cache?.remove(byQuery: query)
            }
            sync.remove(pendingOperation: pendingOperation)
            resolver.fulfill(())
        }
    }
    
    private func deletePromise(pendingOperation: PendingOperation, sync: AnySync) -> Promise<Void> {
        return Promise<Void> { resolver in
            sync.remove(pendingOperation: pendingOperation)
            resolver.fulfill(())
        }
    }
    
    private func updatePromise(pendingOperation: PendingOperation, requests: MultiRequest<ResultType>) -> Promise<Void>? {
        guard let objectId = pendingOperation.objectId else {
            return nil
        }
        return Promise<Void> { resolver in
            let client = options?.client ?? self.client
            let request = client.networkRequestFactory.appData.buildAppDataGetById(
                collectionName: try T.collectionName(),
                id: objectId,
                options: options,
                resultType: ResultType.self
            )
            requests.addRequest(request)
            request.execute() { data, response, error in
                if let response = response,
                    response.isOK,
                    let data = data,
                    let persistable = try? client.jsonParser.parseObject(T.self, from: data)
                {
                    self.cache?.save(entity: persistable)
                    self.sync?.remove(pendingOperation: pendingOperation)
                    resolver.fulfill(())
                } else {
                    resolver.reject(buildError(data, response, error, self.client))
                }
            }
        }
    }
    
}
