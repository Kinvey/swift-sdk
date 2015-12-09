//
//  CachedStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class CachedStoreExpiration {
    
    public enum Time {
        case Seconds, Minutes, Hours, Days, Months, Years
    }
    
    public let value: UInt
    
    public let time: Time
    
    public init(value: UInt, time: Time) {
        self.value = value
        self.time = time
    }
    
}

public class CachedStore<T: Persistable>: NSObject, Store {
    
    public let collectionName: String
    
    public let client: Client
    
    public let expiration: CachedStoreExpiration
    
    public required convenience init(collectionName: String) {
        self.init(collectionName: collectionName, expiration: CachedStoreExpiration(value: 0, time: .Seconds), client: Kinvey.sharedClient())
    }
    
    public required convenience init(collectionName: String, client: Client) {
        self.init(collectionName: collectionName, expiration: CachedStoreExpiration(value: 0, time: .Seconds), client: client)
    }
    
    public convenience init(collectionName: String, expiration: CachedStoreExpiration) {
        self.init(collectionName: collectionName, expiration: expiration, client: Kinvey.sharedClient())
    }
    
    public required init(collectionName: String, expiration: CachedStoreExpiration, client: Client) {
        self.collectionName = collectionName
        self.expiration = expiration
        self.client = client
    }
    
    public func get(id: String, completionHandler: ((String?, NSError?) -> Void)) {
    }
    
    public func find(query: Query, completionHandler: (([T]?, NSError?) -> Void)) {
    }
    
    public func save(persistable: T, completionHandler: ((T?, NSError?) -> Void)) {
    }
    
    public func save(persistable: [T], completionHandler: (([T]?, NSError?) -> Void)) {
    }
    
    public func remove(persistable: T, completionHandler: ((Int?, NSError?) -> Void)) {
    }
    
    public func remove(array: [T], completionHandler: ((Int?, NSError?) -> Void)) {
    }

}
