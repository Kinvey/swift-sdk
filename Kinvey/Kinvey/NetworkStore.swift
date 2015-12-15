//
//  NetworkStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class NetworkStore<T: Persistable>: BaseStore<T> {
    
    public required init(collectionName: String, client: Client = Kinvey.sharedClient()) {
        super.init(collectionName: collectionName, client: client)
    }
    
    public override func get(id: String, completionHandler: ObjectCompletionHandler?) {
        super.get(id, completionHandler: dispatchAsyncTo(completionHandler))
    }
    
    public override func find(query: Query, completionHandler: ArrayCompletionHandler?) {
        super.find(query, completionHandler: dispatchAsyncTo(completionHandler))
    }
    
    public override func save(persistable: T, completionHandler: ObjectCompletionHandler?) {
        super.save(persistable, completionHandler: dispatchAsyncTo(completionHandler))
    }

}
