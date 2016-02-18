//
//  RequestDecorator.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-17.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class RequestDecorator: Request {
    
    var request: Request? {
        willSet(request) {
            if _canceled {
                request?.cancel()
            }
        }
    }
    
    init(request: Request? = nil) {
        self.request = request
    }
    
    var executing: Bool {
        get {
            if let request = request {
                return request.executing
            } else {
                return false
            }
        }
    }
    
    var _canceled = false
    var canceled: Bool {
        get {
            if let request = request {
                return request.canceled
            } else {
                return _canceled
            }
        }
    }
    
    func cancel() {
        _canceled = true
        request?.cancel()
    }
    
    func execute(completionHandler: DataResponseCompletionHandler?) {
        request?.execute(completionHandler)
    }
    
}
