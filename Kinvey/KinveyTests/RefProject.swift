//
//  RefProject.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-19.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
@testable import Kinvey

class RefProject: NSObject, Persistable {
    
    dynamic var uniqueId: String?
    dynamic var name: String?
    
    static func kinveyCollectionName() -> String {
        return "HelixProjectProjects"
    }
    
    static func kinveyPropertyMapping() -> [String : String] {
        return [
            "uniqueId" : Kinvey.PersistableIdKey,
            "name" : "name"
        ]
    }
    
    func toJson() -> JsonDictionary {
        var json = JsonDictionary()
        if let uniqueId = uniqueId {
            json[Kinvey.PersistableIdKey] = uniqueId
        }
        if let name = name {
            json["name"] = name
        }
        return json
    }
    
    func fromJson(json: JsonDictionary) {
        if let uniqueId = json[Kinvey.PersistableIdKey] as? String {
            self.uniqueId = uniqueId
        }
        if let name = json["name"] as? String {
            self.name = name
        }
    }
    
}
