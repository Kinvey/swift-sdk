//
//  HttpRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

enum HttpMethod {
    case Get, Post, Put, Delete
}

class HttpRequest: Request {
    
    let httpMethod: HttpMethod
    let endpoint: Endpoint
    
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
    
    init(request: NSURLRequest, client: Client = sharedClient) {
        switch request.HTTPMethod! {
        case "POST":
            self.httpMethod = .Post
        case "PUT":
            self.httpMethod = .Put
        case "DELETE":
            self.httpMethod = .Delete
        case "GET":
            fallthrough
        default:
            self.httpMethod = .Get
        }
        self.endpoint = Endpoint.URL(url: request.URL!)
        self.client = client
        
        if let authorization = request.valueForHTTPHeaderField("Authorization") {
            self.credential = HttpHeaderCredential(authorization)
        } else {
            self.credential = client.activeUser ?? client
        }
        self.request = request.mutableCopy() as! NSMutableURLRequest
    }
    
    init(httpMethod: HttpMethod = .Get, endpoint: Endpoint, credential: Credential? = nil, client: Client = sharedClient) {
        self.httpMethod = httpMethod
        self.endpoint = endpoint
        self.client = client
        self.credential = credential ?? client
        
        let url = endpoint.url()
        request = NSMutableURLRequest(URL: url)
        switch (httpMethod) {
        case .Get:
            request.HTTPMethod = "GET"
        case .Post:
            request.HTTPMethod = "POST"
        case .Put:
            request.HTTPMethod = "PUT"
        case .Delete:
            request.HTTPMethod = "DELETE"
        }
    }
    
    func execute(completionHandler: DataResponseCompletionHandler? = nil) {
        if request.valueForHTTPHeaderField("Authorization") == nil, let credential = credential, let authorizationHeader = credential.authorizationHeader {
            request.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")
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
