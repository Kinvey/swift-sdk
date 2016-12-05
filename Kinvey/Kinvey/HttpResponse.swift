//
//  HttpResponse.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

struct HttpResponse: Response {
    
    let response: NSHTTPURLResponse
    
    init(response: NSHTTPURLResponse) {
        self.response = response
    }
    
    init?(response: NSHTTPURLResponse?) {
        guard let response = response else {
            return nil
        }
        self.init(response: response)
    }
    
    init?(response: NSURLResponse?) {
        guard let response = response as? NSHTTPURLResponse else {
            return nil
        }
        self.init(response: response)
    }
    
    var isOK: Bool {
        get {
            return 200 <= response.statusCode && response.statusCode < 300
        }
    }
    
    var isNotModified: Bool {
        get {
            return response.statusCode == 304
        }
    }
    
    var isUnauthorized: Bool {
        get {
            return response.statusCode == 401
        }
    }
    
    var isNotFound: Bool {
        get {
            return response.statusCode == 404
        }
    }
    
    var isMethodNotAllowed: Bool {
        get {
            return response.statusCode == 405
        }
    }
    
    var etag: String? {
        get {
            return response.allHeaderFields["Etag"] as? String
        }
    }

}

extension Response {
    
    var httpResponse: NSHTTPURLResponse? {
        return (self as? HttpResponse)?.response
    }
    
}
