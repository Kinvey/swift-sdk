//
//  NSURLSessionDownloadTaskRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

@objc(__KNVNSURLSessionDownloadTaskRequest)
class NSURLSessionTaskRequest: NSObject, Request {
    
    var task: NSURLSessionTask?
    
    var executing: Bool {
        get {
            return task?.state == .Running
        }
    }
    
    var cancelled: Bool {
        get {
            return task?.state == .Canceling || task?.error?.code == NSURLErrorCancelled
        }
    }
    
    let client: Client
    var url: NSURL
    var file: File?
    
    init(client: Client, url: NSURL) {
        self.client = client
        self.url = url
    }
    
    init(client: Client, task: NSURLSessionTask) {
        self.client = client
        self.task = task
        self.url = task.originalRequest!.URL!
    }
    
    func cancel() {
        if let file = self.file, let downloadTask = task as? NSURLSessionDownloadTask {
            let lock = NSCondition()
            lock.lock()
            downloadTask.cancelByProducingResumeData { (data) -> Void in
                lock.lock()
                file.resumeDownloadData = data
                lock.signal()
                lock.unlock()
            }
            lock.wait()
            lock.unlock()
        } else {
            task?.cancel()
        }
    }
    
    private func downloadTask(url: NSURL?, response: NSURLResponse?, error: NSError?, fulfill: ((NSData, Response)) -> Void, reject: (ErrorType) -> Void) {
        if let response = response as? NSHTTPURLResponse where 200 <= response.statusCode && response.statusCode < 300, let url = url, let data = NSData(contentsOfURL: url) {
            fulfill((data, HttpResponse(response: response)))
        } else if let error = error {
            reject(error)
        } else {
            reject(Error.InvalidResponse)
        }
    }
    
    private func downloadTask(url: NSURL?, response: NSURLResponse?, error: NSError?, fulfill: ((NSURL, Response)) -> Void, reject: (ErrorType) -> Void) {
        if let response = response as? NSHTTPURLResponse?, let httpResponse = HttpResponse(response: response) where httpResponse.isOK || httpResponse.isNotModified, let url = url {
            fulfill((url, httpResponse))
        } else if let error = error {
            reject(error)
        } else {
            reject(Error.InvalidResponse)
        }
    }
    
    func downloadTaskWithURL(file: File, completionHandler: DataResponseCompletionHandler) {
        self.file = file
        Promise<(NSData, Response)> { fulfill, reject in
            if let resumeData = file.resumeDownloadData {
                task = self.client.urlSession.downloadTaskWithResumeData(resumeData) { (url, response, error) -> Void in
                    self.downloadTask(url, response: response, error: error, fulfill: fulfill, reject: reject)
                }
            } else {
                task = self.client.urlSession.downloadTaskWithURL(url) { (url, response, error) -> Void in
                    self.downloadTask(url, response: response, error: error, fulfill: fulfill, reject: reject)
                }
            }
            task!.resume()
        }.then { data, response in
            completionHandler(data, response, nil)
        }.error { error in
            completionHandler(nil, nil, error)
        }
    }
    
    func downloadTaskWithURL(file: File, completionHandler: PathResponseCompletionHandler) {
        self.file = file
        Promise<(NSURL, Response)> { fulfill, reject in
            if let resumeData = file.resumeDownloadData {
                task = self.client.urlSession.downloadTaskWithResumeData(resumeData) { (url, response, error) -> Void in
                    self.downloadTask(url, response: response, error: error, fulfill: fulfill, reject: reject)
                }
            } else {
                let request = NSMutableURLRequest(URL: url)
                if let etag = file.etag {
                    request.setValue(etag, forHTTPHeaderField: "If-None-Match")
                }
                task = self.client.urlSession.downloadTaskWithRequest(request) { (url, response, error) -> Void in
                    self.downloadTask(url, response: response, error: error, fulfill: fulfill, reject: reject)
                }
            }
            task!.resume()
        }.then { data, response in
            completionHandler(data, response, nil)
        }.error { error in
            completionHandler(nil, nil, error)
        }
    }
    
}
