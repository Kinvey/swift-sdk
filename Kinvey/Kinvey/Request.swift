//
//  Request.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-07.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/// Protocol that represents a request made to the backend.
public protocol Request : ProgressReporting {
    
    /// Indicates if a request still executing or not.
    var executing: Bool { get }
    
    /// Indicates if a request was cancelled or not.
    var cancelled: Bool { get }
    
    /// Cancels a request in progress.
    func cancel()
    
}
