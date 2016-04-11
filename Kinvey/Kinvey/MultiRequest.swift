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
    
    deinit {
        for request in requests {
            if let request = request as? NSObject {
                request.removeObserver(self, forKeyPath: "executing")
            }
        }
    }
    
    internal func addRequest(request: Request) {
        if let request = request as? NSObject {
            request.addObserver(self, forKeyPath: "executing", options: [.Old, .New], context: nil)
        }
        if _canceled {
            request.cancel()
        }
        requests.append(request)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let _ = object as? Request {
            if let keyPath = keyPath where keyPath == "executing" {
                if let change = change,
                    let oldValue = change[NSKeyValueChangeOldKey] as? Bool,
                    let newValue = change[NSKeyValueChangeNewKey] as? Bool
                    where oldValue != newValue
                {
                    let executing = evaluateExecuting()
                    if executing != self.executing {
                        willChangeValueForKey(keyPath)
                        self.executing = executing
                        didChangeValueForKey(keyPath)
                    }
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    internal private(set) var executing = false
    
    private func evaluateExecuting() -> Bool {
        for request in requests {
            if request.executing {
                return true
            }
        }
        return false
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
