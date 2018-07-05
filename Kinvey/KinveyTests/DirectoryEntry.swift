//
//  DirectoryEntry.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-19.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
@testable import Kinvey
import ObjectMapper

class DirectoryEntry: Entity {
    
    @objc
    dynamic var uniqueId: String?
    
    @objc
    dynamic var nameFirst: String?
    
    @objc
    dynamic var nameLast: String?
    
    @objc
    dynamic var email: String?
    
    @objc
    dynamic var refProject: RefProject?
    
    override class func collectionName() -> String {
        return "HelixProjectDirectory"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        uniqueId <- map[Entity.EntityCodingKeys.entityId]
        nameFirst <- map["nameFirst"]
        nameLast <- map["nameLast"]
        email <- map["email"]
    }
    
    override class func ignoredProperties() -> [String] {
        return ["refProject"]
    }
    
}
