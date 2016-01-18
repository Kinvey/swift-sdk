//
//  HttpRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class HttpRequest: Request {
    
    var endpoint: Endpoint
    
    let request: NSMutableURLRequest
    let credential: Credential?
    let client: Client
    
    var task: NSURLSessionTask?
    
    var executing: Bool {
        get {
            return task?.state == .Running
        }
    }
    
    var canceled: Bool {
        get {
            return task?.state == .Canceling || task?.error?.code == NSURLErrorCancelled
        }
    }
    
    init(endpoint: Endpoint, credential: Credential? = nil, client: Client = sharedClient) {
        self.endpoint = endpoint
        self.client = client
        self.credential = credential != nil ? credential! : client
        
        let url = endpoint.url()
        request = NSMutableURLRequest(URL: url)
    }
    
    func execute(completionHandler: DataResponseCompletionHandler? = nil) {
        if let credential = credential, let authorizationHeader = credential.authorizationHeader {
            request.addValue(authorizationHeader, forHTTPHeaderField: "Authorization")
        }
        
        task = client.urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
            completionHandler?(data, HttpResponse(response: response as! NSHTTPURLResponse), error)
        }
        task!.resume()
    }
    
    func cancel() {
        task?.cancel()
    }

}
