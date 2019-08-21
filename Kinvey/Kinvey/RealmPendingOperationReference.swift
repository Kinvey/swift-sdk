//
//  RealmPendingOperationReference.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2019-08-21.
//  Copyright © 2019 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift

class RealmPendingOperationReference: PendingOperation {
    
    let realmConfig: Realm.Configuration
    let requestId: String
    
    init(_ realmPendingOperation: RealmPendingOperation) {
        realmConfig = realmPendingOperation.realm!.configuration
        requestId = realmPendingOperation.requestId
    }
    
    lazy var realmPendingOperation: RealmPendingOperation = {
        let realm = try! Realm(configuration: realmConfig)
        return realm.object(ofType: RealmPendingOperation.self, forPrimaryKey: requestId)!
    }()
    
    var collectionName: String {
        return realmPendingOperation.collectionName
    }
    
    var objectId: String? {
        return realmPendingOperation.objectId
    }
    
    var objectIds: AnyRandomAccessCollection<String>? {
        return realmPendingOperation.objectIds
    }
    
    var requestIds: AnyRandomAccessCollection<String>? {
        return realmPendingOperation.requestIds
    }
    
    func buildRequest() -> URLRequest {
        return realmPendingOperation.buildRequest()
    }
    
}
