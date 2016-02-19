//
//  Request.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-07.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

public protocol Request {
    
    var executing: Bool { get }
    var canceled: Bool { get }
    
    func cancel()

}
