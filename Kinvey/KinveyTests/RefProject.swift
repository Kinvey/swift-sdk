//
//  RefProject.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-19.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import ObjectMapper
@testable import Kinvey

class RefProject: Entity {
    
    dynamic var uniqueId: String?
    dynamic var name: String?
    
    override class func kinveyCollectionName() -> String {
        return "HelixProjectProjects"
    }
    
    override func mapping(map: Map) {
        super.mapping(map)
        
        uniqueId <- map[PersistableIdKey]
        name <- map["name"]
    }
    
}
