//
//  Result.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-02-07.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation

public enum Result<T> {
    
    case success(T)
    case failure(Swift.Error)
    
}
