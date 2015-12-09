//
//  JsonResponseParser.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-09.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

class JsonResponseParser: ResponseParser {
    
    override func parse<T>(data: NSData?, type: T.Type) -> T? {
        if let data = data {
            if (data.length > 0) {
                let result = try! NSJSONSerialization.JSONObjectWithData(data, options: [])
                if let result = result as? T {
                    return result
                } else if let result = result as? [String : AnyObject] {
                    if let persistable = type as? Persistable.Type {
                        let obj = persistable.init(json: result)
                        return obj as? T
                    }
                }
            }
        }
        
        return nil
    }

}
