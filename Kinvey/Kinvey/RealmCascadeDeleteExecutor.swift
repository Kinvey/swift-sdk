//
//  RealmCascadeDeleteExecutor.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2019-08-21.
//  Copyright © 2019 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift

class RealmCascadeDeleteExecutor: CascadeDeleteExecutor, RealmCascadeDeletable {
    
    let realm: Realm
    
    init(realm: Realm) {
        self.realm = realm
    }
    
    func cascadeDelete<Value>(_ object: Value?) throws where Value : Object {
        if let object = object {
            if let cascadeDelete = object as? CascadeDeletable {
                try cascadeDelete.cascadeDelete(executor: self)
            }
            deleteAclAndMetadata(realm: realm, object: object)
            realm.delete(object)
        }
    }
    
    func cascadeDelete<Value>(_ list: List<Value>) throws where Value : Object {
        for object in list {
            if let cascadeDelete = object as? CascadeDeletable {
                try cascadeDelete.cascadeDelete(executor: self)
            }
            deleteAclAndMetadata(realm: realm, object: object)
        }
        realm.delete(list)
    }
    
}
