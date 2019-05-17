//
//  SaveOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class SaveOperation<T: Persistable>: WriteOperation<T, T>, WriteOperationType where T: NSObject {
    
    var persistable: T
    
    typealias ResultType = Result<T, Swift.Error>
    
    init(
        persistable: inout T,
        writePolicy: WritePolicy,
        sync: AnySync? = nil,
        cache: AnyCache<T>? = nil,
        options: Options?
    ) {
        self.persistable = persistable
        super.init(
            writePolicy: writePolicy,
            sync: sync,
            cache: cache,
            options: options
        )
    }
    
    init(
        persistable: T,
        writePolicy: WritePolicy,
        sync: AnySync? = nil,
        cache: AnyCache<T>? = nil,
        options: Options?
    ) {
        self.persistable = persistable
        super.init(
            writePolicy: writePolicy,
            sync: sync,
            cache: cache,
            options: options
        )
    }
    
    func executeLocal(_ completionHandler: CompletionHandler?) -> AnyRequest<ResultType> {
        let request = LocalRequest<Result<T, Swift.Error>>()
        request.execute { () -> Void in
            let networkRequest = self.client.networkRequestFactory.appData.buildAppDataSave(
                self.persistable,
                options: options,
                resultType: ResultType.self
            )
            
            let persistable = self.fillObject(&self.persistable)
            if let cache = self.cache {
                cache.save(entity: persistable)
            }
            
            if let sync = self.sync {
                sync.savePendingOperation(sync.createPendingOperation(networkRequest.request, objectId: persistable.entityId))
            }
            request.result = .success(self.persistable)
            if let completionHandler = completionHandler, let result = request.result {
                completionHandler(result)
            }
        }
        return AnyRequest(request)
    }
    
    func executeNetwork(_ completionHandler: CompletionHandler?) -> AnyRequest<ResultType> {
        let request = client.networkRequestFactory.appData.buildAppDataSave(
            persistable,
            options: options,
            resultType: ResultType.self
        )
        if checkRequirements(completionHandler) {
            request.execute() { data, response, error in
                let result: ResultType
                if let response = response,
                    response.isOK,
                    let data = data,
                    let persistable = try? self.client.jsonParser.parseObject(T.self, from: data)
                {
                    if let objectId = self.persistable.entityId,
                        let sync = self.sync
                    {
                        sync.removeAllPendingOperations(
                            objectId,
                            methods: ["POST", "PUT"]
                        )
                    }
                    if let cache = self.cache {
                        cache.remove(entity: self.persistable)
                        cache.save(entity: persistable)
                    }
                    result = .success(persistable)
                } else {
                    result = .failure(buildError(data, response, error, self.client))
                }
                request.result = result
                completionHandler?(result)
            }
        }
        return AnyRequest(request)
    }
    
    fileprivate func checkRequirements(_ completionHandler: CompletionHandler?) -> Bool {
        guard let _ = client.activeUser else {
            completionHandler?(.failure(Error.noActiveUser))
            return false
        }
        
        return true
    }
    
}
