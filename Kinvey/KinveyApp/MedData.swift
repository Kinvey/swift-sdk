//
//  MedData.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Kinvey
import Realm
import RealmSwift
import ObjectMapper

class MedData: Entity {
    
    dynamic var id: String?
    dynamic var acl: Acl?
    dynamic var kmd: Metadata?
    dynamic var seq: Int = 0
    dynamic var first: String?
    dynamic var last: String?
    dynamic var age: Int = 0
    dynamic var street: String?
    dynamic var city: String?
    dynamic var state: String?
    dynamic var zip: Int = 0
    dynamic var dollar: String?
    dynamic var pick: String?
    
    override class func kinveyCollectionName() -> String {
        return "meddata"
    }
    
    required init?(_ map: Map) {
        super.init(map)
    }
    
    required init() {
        super.init()
    }
    
    override func mapping(map: Map) {
        super.mapping(map)
        
        id <- map[PersistableIdKey]
        acl <- map[PersistableAclKey]
        kmd <- map[PersistableMetadataKey]
        seq <- map["seq"]
        first <- map["first"]
        last <- map["last"]
        age <- map["age"]
        street <- map["street"]
        city <- map["city"]
        state <- map["state"]
        zip <- map["zip"]
        dollar <- map["dollar"]
        pick <- map["pick"]
    }
    
}
