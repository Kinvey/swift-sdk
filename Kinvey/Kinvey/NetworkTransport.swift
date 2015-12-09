//
//  NetworkTransport.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class NetworkTransport: NSObject {
    
    let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    typealias CompletionHandler = (NSData?, NSURLResponse?, NSError?) -> Void
    
    func execute(request: NSMutableURLRequest, completionHandler: CompletionHandler) {
        preconditionFailure("This method must be overridden")
    }
    
}
