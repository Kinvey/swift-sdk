//
//  RemoveOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVRemoveOperation)
internal class RemoveByQueryOperation: RemoveOperation {
    
    override func buildRequest() -> HttpRequest {
        return client.networkRequestFactory.buildAppDataRemoveByQuery(collectionName: persistableType.kinveyCollectionName(), query: query)
    }
    
}
