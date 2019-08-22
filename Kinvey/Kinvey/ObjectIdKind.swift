//
//  ObjectIdKind.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2019-08-21.
//  Copyright © 2019 Kinvey. All rights reserved.
//

import Foundation

enum ObjectIdKind {
    
    case objectId(String)
    case objectIds(AnyRandomAccessCollection<String>)
    
}

extension ObjectIdKind {
    
    init?(_ objectId: String?) {
        guard let objectId = objectId else {
            return nil
        }
        self = .objectId(objectId)
    }
    
    init?<RAC>(_ objectIds: RAC?) where RAC: RandomAccessCollection, RAC.Element == String {
        guard let objectIds = objectIds else {
            return nil
        }
        self = .objectIds(AnyRandomAccessCollection(objectIds))
    }
    
}
