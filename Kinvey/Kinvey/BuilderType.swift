//
//  BuilderType.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-08-12.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

public protocol BuilderType {
    
    init()
    init(@noescape _ block: (Self) -> Void)
    
}

extension BuilderType {
    public init(@noescape _ block: (Self) -> Void) {
        self.init()
        block(self)
    }
}
