//
//  Persistable.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public protocol Persistable: JsonObject {
    
    init(json: [String : AnyObject])
    
    func merge<T: Persistable>(object: T)
    
}
