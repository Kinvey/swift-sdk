//
//  ResponseParser.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-09.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public protocol ResponseParser {
    
    var client: Client { get }
    
    func parse<S, T>(source: S?, type: T.Type) -> T?
    func parseArray<S, T>(source: S?, type: T.Type) -> [T]?

}

extension ResponseParser {
    
    func isResponseOk(response: NSURLResponse?) -> Bool {
        if let response = response {
            if let httpResponse = response as? NSHTTPURLResponse {
                return 200 <= httpResponse.statusCode && httpResponse.statusCode < 300
            }
        }
        return false
    }
    
}
