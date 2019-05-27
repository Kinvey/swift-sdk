//
//  RemoveByIdOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-25.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class RemoveByIdOperation<T: Persistable>: RemoveOperation<T> where T: NSObject {
    
    let objectId: String
    
    internal init(
        objectId: String,
        writePolicy: WritePolicy,
        sync: AnySync? = nil,
        cache: AnyCache<T>? = nil,
        options: Options?
    ) {
        self.objectId = objectId
        let query = Query(format: "\(try! T.entityIdProperty()) == %@", objectId as Any)
        let client = options?.client ?? sharedClient
        let httpRequest = client.networkRequestFactory.appData.buildAppDataRemoveById(
            collectionName: try! T.collectionName(),
            objectId: objectId,
            options: options,
            resultType: Result<Int, Swift.Error>.self
        )
        super.init(
            query: query,
            httpRequest: httpRequest,
            writePolicy: writePolicy,
            sync: sync,
            cache: cache,
            options: options
        )
    }
    
}
