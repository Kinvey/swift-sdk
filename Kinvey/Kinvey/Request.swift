//
//  Request.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-07.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/// Protocol that represents a request made to the backend.
public protocol BasicRequest : ProgressReporting {
    
    /// Indicates if a request still executing or not.
    var executing: Bool { get }
    
    /// Indicates if a request was cancelled or not.
    var cancelled: Bool { get }
    
    /// Cancels a request in progress.
    func cancel()
    
}

public protocol Request : BasicRequest {
    
    associatedtype ResultType
    
    /// Indicates if a request still executing or not.
    var executing: Bool { get }
    
    /// Indicates if a request was cancelled or not.
    var cancelled: Bool { get }
    
    /// Cancels a request in progress.
    func cancel()
    
    var result: ResultType? { get }
    
}

extension Request {
    
    @discardableResult
    func wait(timeout: TimeInterval = TimeInterval.infinity) -> Bool {
        var result = false
        let observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, CFRunLoopActivity.beforeWaiting.rawValue, true, 0) { (observer, activity) in
            if let _ = self.result {
                result = true
                CFRunLoopStop(CFRunLoopGetCurrent())
            }
        }
        
        CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, .defaultMode)
        CFRunLoopRunInMode(.defaultMode, timeout, false)
        CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), observer, .defaultMode)
        return result
    }
    
}

public class AnyRequest<Result>: NSObject, Request {
    
    public typealias ResultType = Result
    
    private let _getExecuting: () -> Bool
    
    public var executing: Bool {
        return _getExecuting()
    }
    
    private let _getCancelled: () -> Bool
    
    public var cancelled: Bool {
        return _getCancelled()
    }
    
    private let _cancel: () -> Void
    
    public func cancel() {
        _cancel()
    }
    
    private let _getResult: () -> Result?
    
    public var result: Result? {
        return _getResult()
    }
    
    private let _getProgress: () -> Progress
    
    public var progress: Progress {
        return _getProgress()
    }
    
    init<RequestType: Request>(_ request: RequestType) where RequestType.ResultType == Result {
        _getExecuting = { return request.executing }
        _getCancelled = { return request.cancelled }
        _cancel = request.cancel
        _getResult = { request.result }
        _getProgress = { request.progress }
    }
    
}
