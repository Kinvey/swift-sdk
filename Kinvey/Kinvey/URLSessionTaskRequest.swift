//
//  NSURLSessionDownloadTaskRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

class URLSessionTaskRequest: TaskProgressRequest, Request {
    
    var executing: Bool {
        get {
            return task?.state == .running
        }
    }
    
    var cancelled: Bool {
        get {
            return task?.state == .canceling || (task?.error as NSError?)?.code == NSURLErrorCancelled
        }
    }
    
    let client: Client
    let options: Options?
    var url: URL
    var file: File?
    
    var urlSession: URLSession {
        return options?.urlSession ?? client.urlSession
    }
    
    init(client: Client, options: Options?, url: URL) {
        self.client = client
        self.options = options
        self.url = url
    }
    
    convenience init(client: Client, options: Options?, task: URLSessionTask) {
        self.init(client: client, options: options, url: task.originalRequest!.url!)
        self.task = task
        addObservers(task)
    }
    
    func cancel() {
        if let file = self.file, let downloadTask = task as? URLSessionDownloadTask {
            let operation = AsyncBlockOperation { (operation: AsyncBlockOperation) in
                downloadTask.cancel { (data) -> Void in
                    file.resumeDownloadData = data
                    operation.state = .finished
                }
            }
            operation.start()
            operation.waitUntilFinished()
        } else {
            task?.cancel()
        }
    }
    
    fileprivate func downloadTask(_ url: URL?, response: URLResponse?, error: Swift.Error?, completionHandler: PathResponseCompletionHandler) {
        if let response = response as? HTTPURLResponse?, let httpResponse = HttpResponse(response: response), httpResponse.isOK || httpResponse.isNotModified, let url = url {
            completionHandler(url, httpResponse, nil)
        } else if let error = error {
            completionHandler(nil, nil, error)
        } else {
            completionHandler(nil, nil, Error.invalidResponse(httpResponse: response as? HTTPURLResponse, data: nil))
        }
    }
    
    func downloadTaskWithURL(_ file: File) -> Promise<(Data, Response)> {
        self.file = file
        return Promise<(Data, Response)> { fulfill, reject in
            if self.client.logNetworkEnabled {
                do {
                    log.debug("GET \(self.url)")
                }
            }
            
            let handler = { (url: URL?, response: URLResponse?, error: Swift.Error?) in
                if let response = response as? HTTPURLResponse, 200 <= response.statusCode && response.statusCode < 300, let url = url, let data = try? Data(contentsOf: url) {
                    if self.client.logNetworkEnabled {
                        do {
                            log.debug("\(response.description(data))")
                        }
                    }
                    
                    fulfill((data, HttpResponse(response: response)))
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.invalidResponse(httpResponse: response as? HTTPURLResponse, data: nil))
                }
            }
            
            if let resumeData = file.resumeDownloadData {
                task = urlSession.downloadTask(withResumeData: resumeData) { (url, response, error) -> Void in
                    handler(url, response, error)
                }
            } else {
                task = urlSession.downloadTask(with: url) { (url, response, error) -> Void in
                    handler(url, response, error)
                }
            }
            task!.resume()
        }
    }
    
    func downloadTaskWithURL(_ file: File, completionHandler: @escaping PathResponseCompletionHandler) {
        self.file = file
        
        if let resumeData = file.resumeDownloadData {
            task = urlSession.downloadTask(withResumeData: resumeData) { (url, response, error) -> Void in
                self.downloadTask(url, response: response, error: error, completionHandler: completionHandler)
            }
        } else {
            var request = URLRequest(url: url)
            if let etag = file.etag {
                request.setValue(etag, forHTTPHeaderField: "If-None-Match")
            }
            task = urlSession.downloadTask(with: request) { (url, response, error) -> Void in
                self.downloadTask(url, response: response, error: error, completionHandler: completionHandler)
            }
        }
        task!.resume()
    }
    
}
