//
//  MultiRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class MultiRequest: NSObject, Request {
    
    fileprivate var requests = [Request]()
    
    var progress = Progress()
    
    internal func addRequest(_ request: Request) {
        if _cancelled {
            request.cancel()
        }
        requests.append(request)
    }
    
    internal var executing: Bool {
        get {
            for request in requests {
                if request.executing {
                    return true
                }
            }
            return false
        }
    }
    
    private var _cancelled = false
    internal var cancelled: Bool {
        get {
            for request in requests {
                if request.cancelled {
                    return true
                }
            }
            return _cancelled
        }
    }
    
    internal func cancel() {
        _cancelled = true
        for request in requests {
            request.cancel()
        }
    }
    
}

func +=(lhs: MultiRequest, rhs: Request) {
    lhs.addRequest(rhs)
}
