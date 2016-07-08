//
//  CacheManager.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

internal class CacheManager: NSObject {
    
    private let persistenceId: String
    private let encryptionKey: NSData?
    private let schemaVersion: UInt64
    
    init(persistenceId: String, encryptionKey: NSData? = nil, schemaVersion: UInt64 = 0, migrationHandler: Migration.MigrationHandler? = nil) {
        self.persistenceId = persistenceId
        self.encryptionKey = encryptionKey
        self.schemaVersion = schemaVersion
        
        var realmConfiguration = Realm.Configuration()
        if let encryptionKey = encryptionKey {
            realmConfiguration.encryptionKey = encryptionKey
        }
        realmConfiguration.schemaVersion = schemaVersion
        realmConfiguration.migrationBlock = { migration, oldSchemaVersion in
            let migration = Migration(realmMigration: migration)
            migrationHandler?(migration: migration, schemaVersion: oldSchemaVersion)
        }
        do {
            _ = try Realm(configuration: realmConfiguration)
        } catch {
            realmConfiguration.deleteRealmIfMigrationNeeded = true
            _ = try! Realm(configuration: realmConfiguration)
        }
    }
    
    func cache<T: Persistable where T: NSObject>(filePath filePath: String? = nil, type: T.Type) -> Cache<T>? {
        return RealmCache<T>(persistenceId: persistenceId, filePath: filePath, encryptionKey: encryptionKey, schemaVersion: schemaVersion)
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
                    var realmConfiguration = Realm.Configuration.defaultConfiguration
                    realmConfiguration.fileURL = NSURL(fileURLWithPath: (basePath as NSString).stringByAppendingPathComponent(realmFile))
                    if let encryptionKey = encryptionKey {
                        realmConfiguration.encryptionKey = encryptionKey
                    }
                    if let realm = try? Realm(configuration: realmConfiguration) where !realm.isEmpty {
                        try! realm.write {
                            realm.deleteAll()
                        }
                    }
                }
            }
        }
    }
    
}
