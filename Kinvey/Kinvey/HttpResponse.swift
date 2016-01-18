//
//  HttpResponse.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class HttpResponse: Response {
    
    let response: NSHTTPURLResponse
    
    init(response: NSHTTPURLResponse) {
        self.response = response
    }
    
    var isResponseOK: Bool {
        get {
            return 200 <= response.statusCode && response.statusCode < 300
        }
    }

}
