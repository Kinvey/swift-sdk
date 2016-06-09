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

class RefProject: NSObject, Persistable {
    
    dynamic var uniqueId: String?
    dynamic var name: String?
    
    static func kinveyCollectionName() -> String {
        return "HelixProjectProjects"
    }
    
    required init?(_ map: Map) {
    }
    
    override init() {
    }
    
    func mapping(map: Map) {
        uniqueId <- map[Kinvey.PersistableIdKey]
        name <- map["name"]
    }
    
}
