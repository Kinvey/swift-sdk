//
//  Store.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public protocol Store {
    
    typealias PersistableType
    
    typealias ArrayCompletionHandler = ([CollectionType]?, NSError?) -> Void
    typealias ObjectCompletionHandler = (CollectionType?, NSError?) -> Void
    typealias IntCompletionHandler = (Int?, NSError?) -> Void
    
    var client: Client { get }
    
    //MARK: - Read
    
    func get(id: String, completionHandler: ObjectCompletionHandler?)
    
    func find(query: Query, completionHandler: ArrayCompletionHandler?)
    
    //MARK: - Create / Update
    
    func save(persistable: PersistableType, completionHandler: ObjectCompletionHandler?)
    
    func save(array: [PersistableType], completionHandler: ArrayCompletionHandler?)
    
    //MARK: - Delete
    
    func remove(id: String, completionHandler: IntCompletionHandler?)
    
    func remove(ids: [String], completionHandler: IntCompletionHandler?)
    
    func remove(persistable: PersistableType, completionHandler: IntCompletionHandler?)
    
    func remove(array: [PersistableType], completionHandler: IntCompletionHandler?)
    
    func remove(query: Query, completionHandler: IntCompletionHandler?)
    
    //TODO: - aggregation / grouping

}
