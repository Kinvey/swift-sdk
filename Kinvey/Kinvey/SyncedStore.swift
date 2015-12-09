//
//  SyncedStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class SyncedStore<T: Persistable>: NSObject, Store {
    
    public let collectionName: String
    
    public let client: Client
    
    public required convenience init(collectionName: String) {
        self.init(collectionName: collectionName, client: Kinvey.sharedClient())
    }
    
    public required init(collectionName: String, client: Client) {
        self.collectionName = collectionName
        self.client = client
    }
    
    public func initialize(query: Query) {
    }
    
    public func push() {
    }
    
    public func sync(query: Query) {
    }
    
    public func purge() {
    }
    
    //MARK: - Store protocol
    
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
