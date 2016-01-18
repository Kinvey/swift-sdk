//
//  Kinvey.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

internal let PersistableIdKey = "_id"
internal let PersistableAclKey = "_acl"
internal let PersistableMetadataKey = "_kmd"
internal let PersistableMetadataLastRetrievedTime = "lrt"

public let sharedClient = Client()

public func getNetworkStore<T: Persistable>(type: T.Type, client: Client = sharedClient) -> Store<T> {
    return client.getNetworkStore(type)
}

public func getCachedStore<T: Persistable>(type: T.Type, expiration: CachedStoreExpiration, client: Client = sharedClient) -> Store<T> {
    return client.getCachedStore(type, expiration: expiration)
}

public func getCachedStore<T: Persistable>(type: T.Type, expiration: Expiration, client: Client = sharedClient) -> Store<T> {
    return client.getCachedStore(type, expiration: expiration)
}

public func getSyncedStore<T: Persistable>(type: T.Type, client: Client = sharedClient) -> Store<T> {
    return client.getSyncedStore(type)
}
