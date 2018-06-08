//
//  RefProject.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-19.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
@testable import Kinvey
import ObjectMapper

class RefProject: Entity {
    
    @objc
    dynamic var uniqueId: String?
    
    @objc
    dynamic var name: String?
    
    override class func collectionName() -> String {
        return "HelixProjectProjects"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        uniqueId <- map[Entity.CodingKeys.entityId]
        name <- map["name"]
    }
    
}
