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
    
    typealias ResultType = Result<T, Swift.Error>
    
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
    
    func executeLocal(_ completionHandler: CompletionHandler?) -> AnyRequest<ResultType> {
        let request = LocalRequest<ResultType>()
        request.execute { () -> Void in
            let result: ResultType
            if let persistable = self.cache?.find(byId: self.id) {
                result = .success(persistable)
            } else {
                result = .failure(buildError(client: self.client))
            }
            request.result = result
            completionHandler?(result)
        }
        return AnyRequest(request)
    }
    
    func executeNetwork(_ completionHandler: CompletionHandler?) -> AnyRequest<ResultType> {
        let request = client.networkRequestFactory.buildAppDataGetById(
            collectionName: T.collectionName(),
            id: id,
            options: options,
            resultType: ResultType.self
        )
        request.execute() { data, response, error in
            let result: ResultType
            if let response = response,
                response.isOK,
                let json = self.client.responseParser.parse(data),
                json[Entity.Key.entityId] != nil,
                let obj = T(JSON: json)
            {
                self.cache?.save(entity: obj)
                result = .success(obj)
            } else {
                result = .failure(buildError(data, response, error, self.client))
            }
            request.result = result
            completionHandler?(result)
        }
        return AnyRequest(request)
    }
    
}
