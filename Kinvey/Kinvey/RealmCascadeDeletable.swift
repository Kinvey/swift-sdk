//
//  RealmCascadeDeletable.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2019-08-21.
//  Copyright © 2019 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift

protocol RealmCascadeDeletable {
}

extension RealmCascadeDeletable {
    
    func deleteAclAndMetadata<T>(realm: Realm, object: T) where T: Object {
        guard let entity = object as? Entity else {
            return
        }
        if let acl = entity.acl {
            realm.delete(acl)
        }
        if let metadata = entity.metadata {
            realm.delete(metadata)
        }
    }
    
}
