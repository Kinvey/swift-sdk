//
//  MultiRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class MultiRequest<Result>: NSObject, Request {
    
    typealias ResultType = Result
    
    var result: Result?
    
    fileprivate var requests = [AnyRequest<Any>]()
    
    var progress = Progress()
    
    internal func addRequest<RequestType: Request>(_ request: RequestType) {
        if _cancelled {
            request.cancel()
        }
        requests.append(AnyRequest(request))
    }
    
    internal var executing: Bool {
        return requests.first(where: { $0.executing })?.executing ?? false
    }
    
    private var _cancelled = false
    internal var cancelled: Bool {
        return requests.first(where: { $0.cancelled })?.cancelled ?? _cancelled
    }
    
    internal func cancel() {
        _cancelled = true
        for request in requests {
            request.cancel()
        }
    }
    
}

func +=<MultiRequestResult, RequestType: Request>(lhs: MultiRequest<MultiRequestResult>, rhs: RequestType) {
    lhs.addRequest(rhs)
}
