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
        didSet {
            guard #available(iOS 11.0, OSX 10.13, tvOS 11.0, watchOS 4.0, *) else {
                if let task = task {
                    addObservers(task)
                } else {
                    removeObservers(oldValue)
                }
                return
            }
        }
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
    
    func addObservers(_ task: URLSessionTask?) {
        lock.lock()
        if let task = task {
            if !progressObserving {
                progressObserving = true
                task.addObserver(self, forKeyPath: "countOfBytesSent", options: [.new], context: nil)
                task.addObserver(self, forKeyPath: "countOfBytesExpectedToSend", options: [.new], context: nil)
                task.addObserver(self, forKeyPath: "countOfBytesReceived", options: [.new], context: nil)
                task.addObserver(self, forKeyPath: "countOfBytesExpectedToReceive", options: [.new], context: nil)
            }
        }
        lock.unlock()
    }
    
    func removeObservers(_ task: URLSessionTask?) {
        lock.lock()
        if let task = task {
            if progressObserving {
                progressObserving = false
                task.removeObserver(self, forKeyPath: "countOfBytesSent")
                task.removeObserver(self, forKeyPath: "countOfBytesExpectedToSend")
                task.removeObserver(self, forKeyPath: "countOfBytesReceived")
                task.removeObserver(self, forKeyPath: "countOfBytesExpectedToReceive")
            }
        }
        lock.unlock()
    }
    
    deinit {
        removeObservers(task)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let _ = object as? URLSessionTask, let keyPath = keyPath {
            switch keyPath {
            case "countOfBytesReceived":
                reportProgress()
            case "countOfBytesExpectedToReceive":
                reportProgress()
            case "countOfBytesSent":
                reportProgress()
            case "countOfBytesExpectedToSend":
                reportProgress()
            default:
                break
            }
        }
    }
    
    fileprivate func reportProgress() {
        if let task = task
        {
            let httpMethod = task.originalRequest?.httpMethod ?? "GET"
            switch httpMethod {
            case "GET":
                if _progressDownload == nil,
                    task.countOfBytesExpectedToReceive != NSURLSessionTransferSizeUnknown
                {
                    _progressDownload = Progress(totalUnitCount: task.countOfBytesExpectedToReceive, parent: _progress, pendingUnitCount: 1)
                }
                if let progress = _progressDownload,
                    task.countOfBytesReceived > 0
                {
                    progress.completedUnitCount = task.countOfBytesReceived
                }
            case "POST", "PUT", "PATCH":
                if _progressUpload == nil,
                    task.countOfBytesExpectedToSend != NSURLSessionTransferSizeUnknown
                {
                    _progressUpload = Progress(totalUnitCount: task.countOfBytesExpectedToSend, parent: _progress, pendingUnitCount: 1)
                }
                if let progress = _progressUpload,
                    task.countOfBytesSent > 0
                {
                    progress.completedUnitCount = task.countOfBytesSent
                }
            default:
                break
            }
        }
    }
    
}
