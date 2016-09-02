//
//  ReadOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class ReadOperation<T: Persistable>: Operation<T> where T: NSObject {
    
    typealias CompletionHandler = (Any?, Swift.Error?) -> Void
    
    let readPolicy: ReadPolicy
    
    init(readPolicy: ReadPolicy, cache: Cache<T>?, client: Client) {
        self.readPolicy = readPolicy
        super.init(cache: cache, client: client)
    }
    
    func execute(_ completionHandler: CompletionHandler? = nil) -> Request {
        switch readPolicy {
        case .forceLocal:
            return executeLocal(completionHandler)
        case .forceNetwork:
            return executeNetwork(completionHandler)
        case .both:
            let request = MultiRequest()
            executeLocal() { obj, error in
                completionHandler?(obj, nil)
                request.addRequest(self.executeNetwork(completionHandler))
            }
            return request
        }
    }
    
    func executeLocal(_ completionHandler: CompletionHandler?) -> Request {
        preconditionFailure("Method needs to be implemented")
    }
    
    func executeNetwork(_ completionHandler: CompletionHandler?) -> Request {
        preconditionFailure("Method needs to be implemented")
    }
    
}
