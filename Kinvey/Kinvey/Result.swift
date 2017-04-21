//
//  Result.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-04-11.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation

public enum Result<SuccessType, FailureType> {
    
    case success(SuccessType)
    case failure(FailureType)
    
}
