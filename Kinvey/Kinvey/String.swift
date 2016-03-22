//
//  String.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

extension String {
    
    func toDate() -> NSDate? {
        switch self.characters.count {
            case 20:
                return NSDate2StringValueTransformer.rfc3339DateFormatter.dateFromString(self)
            case 24:
                return NSDate2StringValueTransformer.rfc3339MilliSecondsDateFormatter.dateFromString(self)
            default:
                return nil
        }
    }
    
}

extension NSString {
    
    func toDate() -> NSDate? {
        return (self as String).toDate()
    }
    
}
