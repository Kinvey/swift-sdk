//
//  RemoveOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class RemoveByQueryOperation<T: Persistable>: RemoveOperation<T> {
    
    override func buildRequest() -> HttpRequest {
        return client.networkRequestFactory.buildAppDataRemoveByQuery(collectionName: T.kinveyCollectionName, query: query)
    }
    
}
