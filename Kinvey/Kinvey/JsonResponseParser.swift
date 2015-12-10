//
//  JsonResponseParser.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-09.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

class JsonResponseParser: ResponseParser {
    
    let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    func parse<T>(data: NSData?, type: T.Type) -> T? {
        if let data = data {
            if (data.length > 0) {
                let result = try! NSJSONSerialization.JSONObjectWithData(data, options: [])
                if let result = result as? T {
                    return result
                } else if let result = result as? [String : AnyObject] {
                    if let persistableType = type as? Persistable.Type {
                        let obj = persistableType.init(json: result)
                        return obj as? T
                    } else if let _ = type as? User.Type {
                        let obj = client.userType.init(json: result)
                        return obj as? T
                    }
                }
            }
        }
        
        return nil
    }
    
    func parse<S, T>(source: S?) -> T? {
        if let source = source as? User {
            return source.toJson() as? T
        }
        return nil
    }

}
