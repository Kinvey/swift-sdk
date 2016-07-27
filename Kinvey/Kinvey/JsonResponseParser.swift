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
    
    func parseArray(data: NSData?) -> [JsonDictionary]? {
        if let data = data where data.length > 0 {
            let result = try? NSJSONSerialization.JSONObjectWithData(data, options: []) as! [JsonDictionary]
            return result
        }
        return nil
    }
    
    func parse(data: NSData?) -> JsonDictionary? {
        if let data = data where data.length > 0,
            let result = try? NSJSONSerialization.JSONObjectWithData(data, options: []) as? JsonDictionary,
            let json = result
        {
            return json
        }
        return nil
    }
    
    func parseUser(data: NSData?) -> User? {
        if let data = data where data.length > 0,
            let result = try? NSJSONSerialization.JSONObjectWithData(data, options: []) as? JsonDictionary,
            let json = result
        {
            let user = client.userType.init(JSON: json)
            return user
        }
        return nil
    }
    
    func parseUsers(data: NSData?) -> [User]? {
        if let data = data where data.length > 0,
            let result = try? NSJSONSerialization.JSONObjectWithData(data, options: []) as? [JsonDictionary],
            let jsonArray = result
        {
            var users = [User]()
            for json in jsonArray {
                if let user = client.userType.init(JSON: json) {
                    users.append(user)
                }
            }
            return users
        }
        return nil
    }

}
