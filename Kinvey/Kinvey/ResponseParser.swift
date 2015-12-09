//
//  ResponseParser.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-09.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class ResponseParser: NSObject {
    
    private let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    func isResponseOk(response: NSURLResponse?) -> Bool {
        if let response = response {
            if let httpResponse = response as? NSHTTPURLResponse {
                return 200 <= httpResponse.statusCode && httpResponse.statusCode < 300
            }
        }
        return false
    }
    
    func parse<T>(data: NSData?, type: T.Type) -> T? {
        preconditionFailure("This method must be overridden")
    }

}
