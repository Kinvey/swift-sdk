//
//  CacheManager.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import Realm

@objc(__KNVCacheManager)
internal class CacheManager: NSObject {
    
    private let persistenceId: String
    private let encryptionKey: NSData?
    
    init(persistenceId: String, encryptionKey: NSData? = nil, schemaVersion: CUnsignedLongLong = 0, migrationHandler: Migration.MigrationHandler? = nil) {
        self.persistenceId = persistenceId
        self.encryptionKey = encryptionKey
        let realmConfiguration = KCSRealmEntityPersistence.configurationForPersistenceId(persistenceId, filePath: nil, encryptionKey: encryptionKey)
        realmConfiguration.schemaVersion = schemaVersion
        realmConfiguration.migrationBlock = { migration, oldSchemaVersion in
            let migration = Migration(realmMigration: migration)
            migrationHandler?(migration: migration, schemaVersion: oldSchemaVersion)
        }
        let _ = try! RLMRealm(configuration: realmConfiguration)
    }
    
    func cache(collectionName: String? = nil, filePath: String? = nil) -> Cache {
        return KCSRealmEntityPersistence(persistenceId: persistenceId, collectionName: collectionName, filePath: filePath, encryptionKey: encryptionKey) as! Cache
    }
    
}
