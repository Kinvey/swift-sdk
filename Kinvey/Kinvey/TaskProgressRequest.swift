//
//  TaskRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-08-23.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class TaskProgressRequest: NSObject {
    
    var task: URLSessionTask? {
        willSet {
            guard #available(iOS 11.0, OSX 10.13, tvOS 11.0, watchOS 4.0, *) else {
                if let task = task {
                    removeObservers(task)
                }
                return
            }
        }
        didSet {
            guard #available(iOS 11.0, OSX 10.13, tvOS 11.0, watchOS 4.0, *) else {
                if let task = task {
                    addObservers(task)
                }
                return
            }
        }
    }
    
    deinit {
        removeObservers(task)
    }
    
    private lazy var _progress = Progress(totalUnitCount: 1)
    private var _progressDownload: Progress?
    private var _progressUpload: Progress?
    
    @objc var progress: Progress {
        if #available(iOS 11.0, OSX 10.13, tvOS 11.0, watchOS 4.0, *) {
            return task!.progress
        } else {
            return _progress
        }
    }
    
    var progressObserving = false
    
    fileprivate let lock = NSLock()
    var stateObservationToken: NSKeyValueObservation?
    var countOfBytesSentObservationToken: NSKeyValueObservation?
    var countOfBytesExpectedToSendObservationToken: NSKeyValueObservation?
    var countOfBytesReceivedObservationToken: NSKeyValueObservation?
    var countOfBytesExpectedToReceiveObservationToken: NSKeyValueObservation?
    
    func addObservers(_ task: URLSessionTask?) {
        lock.lock()
        if let task = task {
            if !progressObserving {
                progressObserving = true
            }
            let options: NSKeyValueObservingOptions = [.new]
            stateObservationToken = task.observe(\.state, options: options, changeHandler: reportProgress(task:change:))
            countOfBytesSentObservationToken = task.observe(\.countOfBytesSent, options: options, changeHandler: reportProgress(task:change:))
            countOfBytesExpectedToSendObservationToken = task.observe(\.countOfBytesExpectedToSend, options: options, changeHandler: reportProgress(task:change:))
            countOfBytesReceivedObservationToken = task.observe(\.countOfBytesReceived, options: options, changeHandler: reportProgress(task:change:))
            countOfBytesExpectedToReceiveObservationToken = task.observe(\.countOfBytesExpectedToReceive, options: options, changeHandler: reportProgress(task:change:))
        }
        lock.unlock()
    }
    
    func removeObservers(_ task: URLSessionTask?) {
        lock.lock()
        if let observationToken = stateObservationToken {
            observationToken.invalidate()
        }
        if let observationToken = countOfBytesSentObservationToken {
            observationToken.invalidate()
        }
        if let observationToken = countOfBytesExpectedToSendObservationToken {
            observationToken.invalidate()
        }
        if let observationToken = countOfBytesReceivedObservationToken {
            observationToken.invalidate()
        }
        if let observationToken = countOfBytesExpectedToReceiveObservationToken {
            observationToken.invalidate()
        }
        if progressObserving {
            progressObserving = false
        }
        lock.unlock()
    }
    
    fileprivate func reportProgress<Value>(task: URLSessionTask, change: NSKeyValueObservedChange<Value>) {
        switch task.state {
        case .completed:
            _progress.completedUnitCount = _progress.totalUnitCount
        default:
            let httpMethod = task.originalRequest?.httpMethod ?? "GET"
            switch httpMethod {
            case "GET":
                if _progressDownload == nil,
                    task.countOfBytesExpectedToReceive != NSURLSessionTransferSizeUnknown,
                    task.countOfBytesExpectedToReceive > 0
                {
                    _progressDownload = Progress(totalUnitCount: task.countOfBytesExpectedToReceive, parent: _progress, pendingUnitCount: 1)
                }
                if let progress = _progressDownload,
                    task.countOfBytesReceived > 0,
                    task.countOfBytesReceived <= task.countOfBytesExpectedToReceive
                {
                    progress.completedUnitCount = task.countOfBytesReceived
                }
            case "POST", "PUT", "PATCH":
                if _progressUpload == nil,
                    task.countOfBytesExpectedToSend != NSURLSessionTransferSizeUnknown,
                    task.countOfBytesExpectedToSend > 0
                {
                    _progressUpload = Progress(totalUnitCount: task.countOfBytesExpectedToSend, parent: _progress, pendingUnitCount: 1)
                }
                if let progress = _progressUpload,
                    task.countOfBytesSent > 0,
                    task.countOfBytesSent <= task.countOfBytesExpectedToSend
                {
                    progress.completedUnitCount = task.countOfBytesSent
                }
            default:
                break
            }
        }
    }
    
}
