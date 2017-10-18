//
//  GetOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class GetOperation<T: Persistable>: ReadOperation<T, T, Swift.Error>, ReadOperationType where T: NSObject {
    
    let id: String
    
    init(
        id: String,
        readPolicy: ReadPolicy,
        validationStrategy: ValidationStrategy?,
        cache: AnyCache<T>?,
        options: Options?
    ) {
        self.id = id
        super.init(
            readPolicy: readPolicy,
            validationStrategy: validationStrategy,
            cache: cache,
            options: options
        )
    }
    
    func executeLocal(_ completionHandler: CompletionHandler?) -> Progress {
        let progress = Progress(totalUnitCount: 0)
        if let persistable = self.cache?.find(byId: self.id) {
            completionHandler?(.success(persistable))
        } else {
            completionHandler?(.failure(buildError(client: self.client)))
        }
        return progress
    }
    
    func executeNetwork(_ completionHandler: CompletionHandler?) -> Progress {
        let request = client.networkRequestFactory.buildAppDataGetById(
            collectionName: T.collectionName(),
            id: id,
            options: options
        )
        request.execute() { data, response, error in
            if let response = response,
                response.isOK,
                let json = self.client.responseParser.parse(data),
                json[Entity.Key.entityId] != nil,
                let obj = T(JSON: json)
            {
                self.cache?.save(entity: obj)
                completionHandler?(.success(obj))
            } else {
                completionHandler?(.failure(buildError(data, response, error, self.client)))
            }
        }
        return request.progress!
    }
    
}
