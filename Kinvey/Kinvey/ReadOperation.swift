//
//  ReadOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVReadOperation)
public class ReadOperation: Operation {
    
    typealias CompletionHandler = (AnyObject?, ErrorType?) -> Void
    public typealias CompletionHandlerObjC = (AnyObject?, NSError?) -> Void
    
    let readPolicy: ReadPolicy
    
    init(readPolicy: ReadPolicy, persistableType: Persistable.Type, cache: Cache, client: Client) {
        self.readPolicy = readPolicy
        super.init(persistableType: persistableType, cache: cache, client: client)
    }
    
    func execute(completionHandler: CompletionHandler? = nil) -> Request {
        switch readPolicy {
        case .ForceLocal:
            return executeLocal(completionHandler)
        case .ForceNetwork:
            return executeNetwork(completionHandler)
        case .Both:
            let request = MultiRequest()
            executeLocal() { obj, error in
                completionHandler?(obj, nil)
                request.addRequest(self.executeNetwork(completionHandler))
            }
            return request
        }
    }
    
    @objc public func execute(completionHandler: CompletionHandlerObjC? = nil) -> Request {
        switch readPolicy {
        case .ForceLocal:
            return executeLocal({ (obj, error) -> Void in
                completionHandler?(obj, error as? NSError)
            })
        case .ForceNetwork:
            return executeNetwork({ (obj, error) -> Void in
                completionHandler?(obj, error as? NSError)
            })
        case .Both:
            let request = MultiRequest()
            executeLocal({ (obj, error) -> Void in
                completionHandler?(obj, error as? NSError)
                request.addRequest(self.executeNetwork({ (obj, error) -> Void in
                    completionHandler?(obj, error as? NSError)
                }))
            })
            return request
        }
    }
    
    func executeLocal(completionHandler: CompletionHandler?) -> Request {
        preconditionFailure("Method needs to be implemented")
    }
    
    func executeNetwork(completionHandler: CompletionHandler?) -> Request {
        preconditionFailure("Method needs to be implemented")
    }
    
}
