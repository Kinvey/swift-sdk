//
//  OperationQueueRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-26.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class OperationQueueRequest: NSObject, Request {
    
    let operationQueue: OperationQueue
    var progress: ((ProgressStatus) -> Void)?
    
    override init() {
        operationQueue = OperationQueue()
    }
    
    var executing: Bool {
        get {
            return operationQueue.operationCount > 0
        }
    }
    
    var cancelled = false
    
    func cancel() {
        cancelled = true
        operationQueue.cancelAllOperations()
    }
    
}
