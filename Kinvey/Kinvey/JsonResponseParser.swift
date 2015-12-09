//
//  JsonResponseParser.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-09.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

class JsonResponseParser: ResponseParser {
    
    override func parse<T>(data: NSData?, response: NSURLResponse?, error: NSError?, type: T.Type) -> T? {
        if let data = data, let response = response {
            if let httpResponse = response as? NSHTTPURLResponse {
                if (200 <= httpResponse.statusCode && httpResponse.statusCode < 300) {
                    let result = try! NSJSONSerialization.JSONObjectWithData(data, options: [])
                    if let result = result as? T {
                        return result
                    } else if let result = result as? [String : AnyObject] {
                        print(T.self is protocol<Persistable>)
                        print(T.self is Persistable)
                        print(T.self as? Persistable)
                        print(T.self as? protocol<Persistable>)
                        if T.self is protocol<Persistable> {
//                            persistable.loadFrom(result)
                        }
                    }
                }
            }
        }
        
        return nil
    }

}
