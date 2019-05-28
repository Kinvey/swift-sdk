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
    let requestStartHeaderHandler: ((Date) -> Void)?
    
    init(
        query: Query? = nil,
        readPolicy: ReadPolicy,
        validationStrategy: ValidationStrategy?,
        cache: AnyCache<T>?,
        options: Options?,
        requestStartHeaderHandler: ((Date) -> Void)? = nil
    ) {
        self.query = query
        self.requestStartHeaderHandler = requestStartHeaderHandler
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
            let result: ResultType
            if let cache = self.cache {
                let count = cache.count(query: self.query)
                result = .success(count)
            } else {
                result = .success(0)
            }
            request.result = result
            completionHandler?(result)
        }
        return AnyRequest(request)
    }
    
    func executeNetwork(_ completionHandler: CompletionHandler? = nil) -> AnyRequest<ResultType> {
        let request = client.networkRequestFactory.appData.buildAppDataCountByQuery(
            collectionName: try! T.collectionName(),
            query: query,
            options: options,
            resultType: ResultType.self
        )
        request.execute() { data, response, error in
            if let requestStartHeader = response?.requestStartHeader {
                self.requestStartHeaderHandler?(requestStartHeader)
            }
            let result: ResultType
            if let response = response, response.isOK,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data),
                let jsonObject = json as? [String : Int],
                let count = jsonObject["count"]
            {
                result = .success(count)
            } else {
                result = .failure(buildError(data, response, error, self.client))
            }
            request.result = result
            completionHandler?(result)
        }
        return AnyRequest(request)
    }
    
}
