//
//  Executor.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-06-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class Executor {
    
    private let operationQueue: NSOperationQueue
    private let thread: NSThread
    
    init() {
        operationQueue = NSOperationQueue.currentQueue()!
        operationQueue.maxConcurrentOperationCount = 1
        thread = NSThread.currentThread()
    }
    
    func execute(block: () -> Void) {
        operationQueue.addOperationWithBlock(block)
    }
    
    func executeAndWait(block: () -> Void) {
        if thread == NSThread.currentThread() {
            block()
        } else {
            operationQueue.addOperationWithBlock(block)
            operationQueue.waitUntilAllOperationsAreFinished()
        }
    }
    
}
