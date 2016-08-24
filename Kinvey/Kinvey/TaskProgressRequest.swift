//
//  TaskRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-08-23.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class TaskProgressRequest: NSObject {
    
    var task: NSURLSessionTask? {
        didSet {
            if let task = task {
                addObservers(task)
            } else {
                removeObservers(oldValue)
            }
        }
    }
    
    var uploadProgress: ((Int64, Int64) -> Void)? {
        didSet { addObservers(task) }
    }
    
    var downloadProgress: ((Int64, Int64) -> Void)? {
        didSet { addObservers(task) }
    }
    
    var uploadProgressObserving = false
    var downloadProgressObserving = false
    
    private let lock = NSLock()
    
    func addObservers(task: NSURLSessionTask?) {
        lock.lock()
        if let task = task {
            if !uploadProgressObserving && uploadProgress != nil {
                uploadProgressObserving = true
                task.addObserver(self, forKeyPath: "countOfBytesSent", options: [.New], context: nil)
                task.addObserver(self, forKeyPath: "countOfBytesExpectedToSend", options: [.New], context: nil)
            }
            if !downloadProgressObserving && downloadProgress != nil {
                downloadProgressObserving = true
                task.addObserver(self, forKeyPath: "countOfBytesReceived", options: [.New], context: nil)
                task.addObserver(self, forKeyPath: "countOfBytesExpectedToReceive", options: [.New], context: nil)
            }
        }
        lock.unlock()
    }
    
    func removeObservers(task: NSURLSessionTask?) {
        lock.lock()
        if let task = task {
            if uploadProgressObserving && uploadProgress != nil {
                uploadProgressObserving = false
                task.removeObserver(self, forKeyPath: "countOfBytesSent")
                task.removeObserver(self, forKeyPath: "countOfBytesExpectedToSend")
            }
            if downloadProgressObserving && downloadProgress != nil {
                downloadProgressObserving = false
                task.removeObserver(self, forKeyPath: "countOfBytesReceived")
                task.removeObserver(self, forKeyPath: "countOfBytesExpectedToReceive")
            }
        }
        lock.unlock()
    }
    
    deinit {
        removeObservers(task)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let _ = object as? NSURLSessionTask, let keyPath = keyPath {
            switch keyPath {
            case "countOfBytesReceived":
                fallthrough
            case "countOfBytesExpectedToReceive":
                reportDownloadProgress()
                break
            case "countOfBytesSent":
                fallthrough
            case "countOfBytesExpectedToSend":
                reportUploadProgress()
                break
            default:
                break
            }
        }
    }
    
    private var lastCountOfBytesSent = NSURLSessionTransferSizeUnknown
    private var lastCountOfBytesExpectedToSend = NSURLSessionTransferSizeUnknown
    
    private func reportUploadProgress() {
        if let _ = uploadProgress, let task = task where task.countOfBytesSent >= 0 && task.countOfBytesExpectedToSend > 0 {
            dispatch_async(dispatch_get_main_queue()) {
                if self.lastCountOfBytesSent != task.countOfBytesSent || self.lastCountOfBytesExpectedToSend != task.countOfBytesExpectedToSend {
                    self.lastCountOfBytesSent = task.countOfBytesSent
                    self.lastCountOfBytesExpectedToSend = task.countOfBytesExpectedToSend
                    self.uploadProgress?(self.lastCountOfBytesSent, self.lastCountOfBytesExpectedToSend)
                }
            }
        }
    }
    
    private var lastCountOfBytesReceived = NSURLSessionTransferSizeUnknown
    private var lastCountOfBytesExpectedToReceive = NSURLSessionTransferSizeUnknown
    
    private func reportDownloadProgress() {
        if let _ = downloadProgress, let task = task where task.countOfBytesReceived >= 0 && task.countOfBytesExpectedToReceive > 0 {
            dispatch_async(dispatch_get_main_queue()) {
                if self.lastCountOfBytesReceived != task.countOfBytesReceived || self.lastCountOfBytesExpectedToReceive != task.countOfBytesExpectedToReceive {
                    self.lastCountOfBytesReceived = task.countOfBytesReceived
                    self.lastCountOfBytesExpectedToReceive = task.countOfBytesExpectedToReceive
                    self.downloadProgress?(self.lastCountOfBytesReceived, self.lastCountOfBytesExpectedToReceive)
                }
            }
        }
    }
    
}
