//
//  Kinvey.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class Kinvey: NSObject {
    
    private override init() {
    }
    
    static let _sharedClient = Client()
    
    public class func sharedClient() -> Client {
        return _sharedClient
    }

}
