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
    
    func parseArray<S, T>(source: S?, type: T.Type) -> [T]? {
        if let data = source as? NSData {
            if (data.length > 0) {
                let result = try! NSJSONSerialization.JSONObjectWithData(data, options: [])
                return parseArray(result, type: type)
            }
        } else if let result = source as? [[String : AnyObject]] {
            var array: [T] = []
            for item in result {
                if let item = parse(item, type: T.self) {
                    array.append(item)
                }
            }
            return array
        }
        return nil
    }
    
    func parse<S, T>(source: S?, type: T.Type) -> T? {
        if let data = source as? NSData {
            if (data.length > 0) {
                let result = try! NSJSONSerialization.JSONObjectWithData(data, options: [])
                return parse(result, type: type)
            }
        } else if let source = source as? T {
            return source
        } else if let result = source as? [String : AnyObject] {
            if let persistableType = type as? Persistable.Type {
                let obj = persistableType.init(json: result)
                return obj as? T
            } else if let _ = type as? User.Type {
                let obj = client.userType.init(json: result, client: client)
                return obj as? T
            }
        } else if let source = source as? User, let _ = type as? [String : AnyObject].Type {
            return source.toJson() as? T
        }
        return nil
    }

}
