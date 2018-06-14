//
//  NSData.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-03.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

extension Data {
    
    func hexString() -> String {
        return withUnsafeBytes {
            [UInt8](UnsafeBufferPointer(start: $0, count: count))
        }.map {
            String(format: "%02hhx", $0)
        }.joined()
    }
    
}
