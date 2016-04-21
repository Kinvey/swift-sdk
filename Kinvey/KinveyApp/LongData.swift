//
//  LongData.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Kinvey

class LongData: NSObject, Persistable {
    
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
    dynamic var paragraph: String?
    
    static func kinveyCollectionName() -> String {
        return "longdata"
    }
    
    static func kinveyPropertyMapping() -> [String : String] {
        return [
            "id" : Kinvey.PersistableIdKey,
            "acl" : Kinvey.PersistableAclKey,
            "kmd" : Kinvey.PersistableMetadataKey,
            "seq" : "seq",
            "first" : "first",
            "last" : "last",
            "age" : "age",
            "street" : "street",
            "city" : "city",
            "state" : "state",
            "zip" : "zip",
            "dollar" : "dollar",
            "pick" : "pick",
            "paragraph" : "paragraph"
        ]
    }
    
}
