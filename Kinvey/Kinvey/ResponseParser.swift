//
//  ResponseParser.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-09.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class ResponseParser: NSObject {
    
    private let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    func parse<T>(data: NSData?, response: NSURLResponse?, error: NSError?, type: T.Type) -> T? {
        preconditionFailure("This method must be overridden")
    }

}
