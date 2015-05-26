//
//  City.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-05-08.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import Foundation

class City: NSObject, KCSPersistable {
    
    var objectId: String!
    var name: String!
    
    override func hostToKinveyPropertyMapping() -> [NSObject : AnyObject]! {
        return [
            "objectId" : KCSEntityKeyId,
            "name" : "name"
        ]
    }
    
    override init() {
    }
    
    init(name: String) {
        self.name = name
    }
    
}
