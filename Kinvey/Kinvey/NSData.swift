//
//  NSData.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-03.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

extension NSData {
    
    func hexString() -> String {
        let str = NSMutableString()
        let bytes = UnsafeBufferPointer<UInt8>(start: UnsafePointer(self.bytes), count:self.length)
        for byte in bytes {
            str.appendFormat("%02hhx", byte)
        }
        return str as String
    }
    
}
