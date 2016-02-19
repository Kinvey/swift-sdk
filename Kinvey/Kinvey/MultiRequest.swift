//
//  MultiRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class MultiRequest: Request {
    
    private var requests = [Request]()
    
    func addRequest(request: Request) {
        if _canceled {
            request.cancel()
        }
        requests.append(request)
    }
    
    var executing: Bool {
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
    var canceled: Bool {
        get {
            for request in requests {
                if request.canceled {
                    return true
                }
            }
            return _canceled
        }
    }
    
    func cancel() {
        _canceled = true
        for request in requests {
            request.cancel()
        }
    }
    
}
