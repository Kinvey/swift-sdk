//
//  DirectoryEntry.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-19.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
@testable import Kinvey

class DirectoryEntry: NSObject, Persistable {
    
    dynamic var uniqueId: String?
    dynamic var nameFirst: String?
    dynamic var nameLast: String?
    dynamic var email: String?
    
    dynamic var refProject: RefProject?
    
    static func kinveyCollectionName() -> String {
        return "HelixProjectDirectory"
    }
    
    static func kinveyPropertyMapping() -> [String : String] {
        return [
            "uniqueId" : Kinvey.PersistableIdKey,
            "nameFirst" : "nameFirst",
            "nameLast" : "nameLast",
            "email" : "email"
        ]
    }
    
    func toJson() -> JsonDictionary {
        var json = JsonDictionary()
        if let uniqueId = uniqueId {
            json[Kinvey.PersistableIdKey] = uniqueId
        }
        if let nameFirst = nameFirst {
            json["nameFirst"] = nameFirst
        }
        if let nameLast = nameLast {
            json["nameLast"] = nameLast
        }
        if let email = email {
            json["email"] = email
        }
        if let refProject = refProject {
            json["refProject"] = refProject
        }
        return json
    }
    
    func fromJson(json: JsonDictionary) {
        if let uniqueId = json[Kinvey.PersistableIdKey] as? String {
            self.uniqueId = uniqueId
        }
        if let nameFirst = json["nameFirst"] as? String {
            self.nameFirst = nameFirst
        }
        if let nameLast = json["nameLast"] as? String {
            self.nameLast = nameLast
        }
        if let email = json["email"] as? String {
            self.email = email
        }
        if let refProject = json["refProject"] as? JsonDictionary {
            let project = RefProject()
            project.fromJson(refProject)
            self.refProject = project
        }
    }
    
}
