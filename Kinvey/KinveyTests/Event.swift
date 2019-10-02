//
//  Event.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-07-08.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import Kinvey

/// Event.swift - an entity in the 'Events' collection
class Event : Entity {

    @objc
    dynamic var name: String?
    
    @objc
    dynamic var publishDate: Date?
    
    @objc
    dynamic var location: String?
    
    override class func collectionName() -> String {
        return "Event"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        name <- ("name", map["name"])
        publishDate <- ("publishDate", map["date"])
        location <- ("location", map["location"])
    }
    
}
