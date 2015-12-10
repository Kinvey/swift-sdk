//
//  NetworkTransport.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public protocol NetworkTransport {
    
    func execute(request: NSMutableURLRequest, forceBasicAuthentication: Bool, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void)
    
}

extension NetworkTransport {
    
    func execute(request: NSMutableURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
        execute(request, forceBasicAuthentication: false, completionHandler: completionHandler)
    }
    
}
