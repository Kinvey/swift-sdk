//
//  NSDate.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

extension Date {

    public func toISO8601() -> String {
        return KinveyDateTransform().transformToJSON(self)!
    }
    
}
