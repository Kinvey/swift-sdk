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
    
    var isResponseOK: Bool {
        get {
            return 200 <= response.statusCode && response.statusCode < 300
        }
    }
    
    var isResponseUnauthorized: Bool {
        get {
            return response.statusCode == 401
        }
    }

}
