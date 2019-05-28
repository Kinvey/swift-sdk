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
    
    var isBadRequest: Bool {
        return response.statusCode == 400
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
    
    var isInternalServerError: Bool {
        return response.statusCode == 500
    }
    
    var etag: String? {
        return allHeaderFields?["etag"] as? String
    }
    
    var contentTypeIsJson: Bool {
        guard let contentType = allHeaderFields?["content-type"] as? String else {
            return false
        }
        return contentType == "application/json" || contentType.hasPrefix("application/json;")
    }

}

extension Response {
    
    var httpResponse: HTTPURLResponse? {
        return (self as? HttpResponse)?.response
    }
    
    var allHeaderFields: [AnyHashable : Any]? {
        guard let httpResponse = httpResponse else {
            return nil
        }
        return [AnyHashable : Any](uniqueKeysWithValues: httpResponse.allHeaderFields.map {
            guard let key = $0.key as? String else {
                return $0
            }
            return (key.lowercased(), $0.value)
        })
    }
    
    var requestStartHeader: Date? {
        return (allHeaderFields?["x-kinvey-request-start"] as? String)?.toDate()
    }
    
}
