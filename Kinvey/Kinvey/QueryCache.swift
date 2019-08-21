//
//  QueryCache.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2019-08-21.
//  Copyright © 2019 Kinvey. All rights reserved.
//

import Foundation

internal class _QueryCache: Object {
    
    @objc
    dynamic var key: String?
    
    internal func generateKey() {
        key = "\(collectionName ?? "nil")|\(query ?? "nil")"
    }
    
    @objc
    dynamic var collectionName: String?
    
    @objc
    dynamic var query: String?
    
    @objc
    dynamic var fields: String?
    
    @objc
    dynamic var lastSync: Date?
    
    @objc
    override class func primaryKey() -> String? {
        return "key"
    }
    
}
