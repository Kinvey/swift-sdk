//
//  CountOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-08-24.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class CountOperation<T: Persistable>: ReadOperation<T, Int, Swift.Error>, ReadOperationType where T: NSObject {
    
    let query: Query?
    
    typealias ResultType = Result<Int, Swift.Error>
    
    init(
        query: Query? = nil,
        readPolicy: ReadPolicy,
        validationStrategy: ValidationStrategy?,
        cache: AnyCache<T>?,
        options: Options?
    ) {
        self.query = query
        super.init(
            readPolicy: readPolicy,
            validationStrategy: validationStrategy,
            cache: cache,
            options: options
        )
    }
    
    func executeLocal(_ completionHandler: CompletionHandler? = nil) -> AnyRequest<ResultType> {
        let request = LocalRequest<ResultType>()
        request.execute { () -> Void in
            if let cache = self.cache {
                let count = cache.count(query: self.query)
                completionHandler?(.success(count))
            } else {
                completionHandler?(.success(0))
            }
        }
        return AnyRequest(request)
    }
    
    func executeNetwork(_ completionHandler: CompletionHandler? = nil) -> AnyRequest<ResultType> {
        let request = client.networkRequestFactory.buildAppDataCountByQuery(
            collectionName: T.collectionName(),
            query: query,
            options: options,
            resultType: ResultType.self
        )
        request.execute() { data, response, error in
            if let response = response, response.isOK,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data),
                let result = json as? [String : Int],
                let count = result["count"]
            {
                completionHandler?(.success(count))
            } else {
                completionHandler?(.failure(buildError(data, response, error, self.client)))
            }
        }
        return AnyRequest(request)
    }
    
}
