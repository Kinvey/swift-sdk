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
    
    func clearAll(tag: String? = nil) {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        if let path = paths.first as NSString? {
            let basePath = path.stringByAppendingPathComponent(persistenceId)
            
            let fileManager = NSFileManager.defaultManager()
            
            var isDirectory = ObjCBool(false)
            let exists = fileManager.fileExistsAtPath(basePath, isDirectory: &isDirectory)
            if exists && isDirectory {
                var array = try! fileManager.subpathsOfDirectoryAtPath(basePath)
                array = array.filter({ (path) -> Bool in
                    return path.hasSuffix(".realm") && (tag == nil || path.caseInsensitiveCompare(tag! + ".realm") == .OrderedSame)
                })
                for realmFile in array {
                    let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
                    realmConfiguration.fileURL = NSURL(fileURLWithPath: (basePath as NSString).stringByAppendingPathComponent(realmFile))
                    if let encryptionKey = encryptionKey {
                        realmConfiguration.encryptionKey = encryptionKey
                    }
                    if let realm = try? RLMRealm(configuration: realmConfiguration) where !realm.isEmpty {
                        try! realm.transactionWithBlock {
                            realm.deleteAllObjects()
                        }
                    }
                }
            }
        }
    }
    
}
