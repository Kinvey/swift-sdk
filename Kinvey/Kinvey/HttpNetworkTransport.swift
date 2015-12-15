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
    
    func execute(request: NSMutableURLRequest, forceBasicAuthentication: Bool, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
        var authorization: String?
        if !forceBasicAuthentication, let credential = client.activeUser as? Credential, let _authorization = credential.authorizationHeader {
            authorization = _authorization
        } else if let _authorization = client.authorizationHeader {
            authorization = _authorization
        }
        if let authorization = authorization {
            request.addValue(authorization, forHTTPHeaderField: "Authorization")
        }
        
        let task = client.urlSession.dataTaskWithRequest(request, completionHandler: completionHandler)
        task.resume()
    }

}
