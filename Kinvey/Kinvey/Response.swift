//
//  Response.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal protocol Response {
    
    var isResponseOK: Bool { get }
    var isResponseUnauthorized: Bool { get }

}
