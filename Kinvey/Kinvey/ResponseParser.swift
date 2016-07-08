//
//  ResponseParser.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-09.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

internal protocol ResponseParser {
    
    var client: Client { get }
    
    func parse(data: NSData?) -> JsonDictionary?
    func parseArray(data: NSData?) -> [JsonDictionary]?
    func parseUser(data: NSData?) -> User?

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
