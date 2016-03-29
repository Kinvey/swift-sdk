//
//  NSURLSessionDownloadTaskRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

@objc
class NSURLSessionDownloadTaskRequest: NSObject, Request {
    
    var downloadTask: NSURLSessionDownloadTask?
    
    var executing: Bool {
        get {
            return downloadTask?.state == .Running
        }
    }
    
    var cancelled: Bool {
        get {
            return downloadTask?.state == .Canceling || downloadTask?.error?.code == NSURLErrorCancelled
        }
    }
    
    let client: Client
    var url: NSURL
    var resumeData: NSData?
    
    init(client: Client, url: NSURL) {
        self.client = client
        self.url = url
    }
    
    func cancel() {
        downloadTask?.cancelByProducingResumeData { (data) -> Void in
            self.resumeData = data
        }
    }
    
    func execute(completionHandler: DataResponseCompletionHandler?) {
        Promise<(NSData, Response)> { fulfill, reject in
            downloadTask = self.client.urlSession.downloadTaskWithURL(url) { (url, response, error) -> Void in
                if let response = response as? NSHTTPURLResponse where 200 <= response.statusCode && response.statusCode < 300, let url = url {
                    let data = NSData(contentsOfURL: url)
                    fulfill((data!, HttpResponse(response: response)))
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            }
            downloadTask!.resume()
        }.then { data, response in
            completionHandler?(data, response, nil)
        }.error { error in
            completionHandler?(nil, nil, error)
        }
    }
    
}
