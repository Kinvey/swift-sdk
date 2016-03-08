//
//  MultiRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVMultiRequest)
public class MultiRequest: NSObject, Request {
    
    private var requests = [Request]()
    
    public func addRequest(request: Request) {
        if _canceled {
            request.cancel()
        }
        requests.append(request)
    }
    
    public var executing: Bool {
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
    public var canceled: Bool {
        get {
            for request in requests {
                if request.canceled {
                    return true
                }
            }
            return _canceled
        }
    }
    
    public func cancel() {
        _canceled = true
        for request in requests {
            request.cancel()
        }
    }
    
}
