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
            let networkRequest = self.client.networkRequestFactory.buildAppDataSave(
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
        let request = client.networkRequestFactory.buildAppDataSave(
            persistable,
            options: options,
            resultType: ResultType.self
        )
        if checkRequirements(completionHandler) {
            request.execute() { data, response, error in
                if let response = response, response.isOK {
                    let json = self.client.responseParser.parse(data)
                    if let json = json {
                        let persistable = T(JSON: json)
                        if let objectId = self.persistable.entityId,
                            let sync = self.sync
                        {
                            sync.removeAllPendingOperations(
                                objectId,
                                methods: ["POST", "PUT"]
                            )
                        }
                        if let persistable = persistable,
                            let cache = self.cache
                        {
                            cache.remove(entity: self.persistable)
                            cache.save(entity: persistable)
                        }
                        self.merge(&self.persistable, json: json)
                    }
                    completionHandler?(.success(self.persistable))
                } else {
                    completionHandler?(.failure(buildError(data, response, error, self.client)))
                }
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
