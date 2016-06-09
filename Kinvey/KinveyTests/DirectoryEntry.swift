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

class DirectoryEntry: NSObject, Persistable {
    
    dynamic var uniqueId: String?
    dynamic var nameFirst: String?
    dynamic var nameLast: String?
    dynamic var email: String?
    
    dynamic var refProject: RefProject?
    
    static func kinveyCollectionName() -> String {
        return "HelixProjectDirectory"
    }
    
    required init?(_ map: Map) {
    }
    
    override init() {
    }
    
    func mapping(map: Map) {
        uniqueId <- map[Kinvey.PersistableIdKey]
        nameFirst <- map["nameFirst"]
        nameLast <- map["nameLast"]
        email <- map["email"]
    }
    
}
