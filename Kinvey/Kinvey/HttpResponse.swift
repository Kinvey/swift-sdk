//
//  HttpResponse.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

struct HttpResponse: Response {
    
    let response: HTTPURLResponse
    
    init(response: HTTPURLResponse) {
        self.response = response
    }
    
    init?(response: HTTPURLResponse?) {
        guard let response = response else {
            return nil
        }
        self.init(response: response)
    }
    
    init?(response: URLResponse?) {
        guard let response = response as? HTTPURLResponse else {
            return nil
        }
        self.init(response: response)
    }
    
    var isOK: Bool {
        return 200 <= response.statusCode && response.statusCode < 300
    }
    
    var isNotModified: Bool {
        return response.statusCode == 304
    }
    
    var isUnauthorized: Bool {
        return response.statusCode == 401
    }
    
    var isForbidden: Bool {
        return response.statusCode == 403
    }
    
    var isNotFound: Bool {
        return response.statusCode == 404
    }
    
    var isMethodNotAllowed: Bool {
        return response.statusCode == 405
    }
    
    var etag: String? {
        return response.allHeaderFields["Etag"] as? String
    }
    
    var contentTypeIsJson: Bool {
        if let contentType = response.allHeaderFields["Content-Type"] as? String {
            return contentType.hasPrefix("application/json")
        }
        return false
    }

}

extension Response {
    
    var httpResponse: HTTPURLResponse? {
        return (self as? HttpResponse)?.response
    }
    
}
