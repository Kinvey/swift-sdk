//
//  MultiRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVMultiRequest)
internal class MultiRequest: NSObject, Request {
    
    private var requests = [Request]()
    
    internal func addRequest(request: Request) {
        if _canceled {
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
    
    var _canceled = false
    internal var cancelled: Bool {
        get {
            for request in requests {
                if request.cancelled {
                    return true
                }
            }
            return _canceled
        }
    }
    
    internal func cancel() {
        _canceled = true
        for request in requests {
            request.cancel()
        }
    }
    
}
