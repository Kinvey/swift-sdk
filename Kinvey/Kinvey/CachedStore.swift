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
        case Second, Minute, Hour, Day, Month, Year
    }
    
    public let value: UInt
    public let time: Time
    
    public init(_ value: UInt, _ time: Time) {
        self.value = value
        self.time = time
    }
    
}

public class CachedStore<T: Persistable>: BaseStore<T> {
    
    public let expiration: CachedStoreExpiration
    
    public typealias Expiration = (UInt, CachedStoreExpiration.Time)
    
    internal convenience init(expiration: Expiration, client: Client = Kinvey.sharedClient()) {
        self.init(expiration: CachedStoreExpiration(expiration.0, expiration.1), client: client)
    }
    
    internal init(expiration: CachedStoreExpiration, client: Client = Kinvey.sharedClient()) {
        self.expiration = expiration
        super.init(client: client)
    }
    
    public override func get(id: String, completionHandler: ObjectCompletionHandler?) {
        super.get(id) { (obj, error) -> Void in
            self.dispatchAsyncTo(completionHandler)?(obj, error)
        }
    }
    
    public override func find(query: Query, completionHandler: ArrayCompletionHandler?) {
        super.find(query) { (results, error) -> Void in
            self.dispatchAsyncTo(completionHandler)?(results, error)
        }
    }
    
    public override func save(persistable: T, completionHandler: ObjectCompletionHandler?) {
        super.save(persistable) { (obj, error) -> Void in
            self.dispatchAsyncTo(completionHandler)?(obj, error)
        }
    }
    
    public override func remove(query: Query, completionHandler: IntCompletionHandler?) {
        super.remove(query) { (count, error) -> Void in
            self.dispatchAsyncTo(completionHandler)?(count, error)
        }
    }

}
