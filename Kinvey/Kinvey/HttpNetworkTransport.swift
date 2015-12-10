//
//  HttpNetworkTransport.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

class HttpNetworkTransport: NetworkTransport {
    
    let client: Client
    
    required init(client: Client) {
        self.client = client
    }
    
    typealias CompletionHandler = (NSData?, NSURLResponse?, NSError?) -> Void
    
    func execute(request: NSMutableURLRequest, forceBasicAuthentication: Bool, completionHandler: CompletionHandler) {
        var authorization: String?
        if !forceBasicAuthentication, let authtoken = client.activeUser?.metadata?.authtoken {
            authorization = "Kinvey \(authtoken)"
        } else if let appKey = client.appKey, let appSecret = client.appSecret {
            let appKeySecret = "\(appKey):\(appSecret)".dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions([])
            if let appKeySecret = appKeySecret {
                authorization = "Basic \(appKeySecret)"
            }
        }
        if let authorization = authorization {
            request.addValue(authorization, forHTTPHeaderField: "Authorization")
        }
        
        let task = client.urlSession.dataTaskWithRequest(request, completionHandler: completionHandler)
        task.resume()
    }

}
