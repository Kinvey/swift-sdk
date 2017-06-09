//
//  Migration.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-22.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

public typealias Schema = (version: CUnsignedLongLong, migrationHandler: Migration.MigrationHandler?)

//public struct Schema {
//    
//    let version: CUnsignedLongLong
//    let migrationHandler: Migration.MigrationHandler?
//    
//    init(version: CUnsignedLongLong = 0, migrationHandler: Migration.MigrationHandler? = nil) {
//        self.version = version
//        self.migrationHandler = migrationHandler
//    }
//    
//}

/// Class used to perform migrations in your local cache.
open class Migration: NSObject {
    
    public typealias MigrationHandler = (Migration, UInt64) -> Void
    public typealias MigrationObjectHandler = (JsonDictionary) -> JsonDictionary?
    
    let realmMigration: RealmSwift.Migration
    
    init(realmMigration: RealmSwift.Migration) {
        self.realmMigration = realmMigration
    }
    
    internal class func performMigration(persistenceId: String, encryptionKey: Data? = nil, schemaVersion: CUnsignedLongLong = 0, migrationHandler: Migration.MigrationHandler? = nil) {
        var realmBaseConfiguration = Realm.Configuration()
        if let encryptionKey = encryptionKey {
            realmBaseConfiguration.encryptionKey = encryptionKey
        }
        realmBaseConfiguration.schemaVersion = schemaVersion
        if let migrationHandler = migrationHandler {
            realmBaseConfiguration.migrationBlock = { migration, oldSchemaVersion in
                let migration = Migration(realmMigration: migration)
                migrationHandler(migration, oldSchemaVersion)
            }
        } else {
            realmBaseConfiguration.deleteRealmIfMigrationNeeded = true
        }
        let baseFolderURL = Client.fileURL(appKey: persistenceId).deletingLastPathComponent()
        let fileManager = FileManager.default
        if let allFilesURL = try? fileManager.contentsOfDirectory(at: baseFolderURL, includingPropertiesForKeys: nil) {
            for realmFileURL in allFilesURL.filter({ $0.lastPathComponent.hasSuffix(".realm") }) {
                var realmConfiguration = realmBaseConfiguration //copy
                realmConfiguration.fileURL = realmFileURL
                do {
                    try Realm.performMigration(for: realmConfiguration)
                } catch {
                    log.error("Database migration failed: deleting local database.\nDetails of the failure: \(error)")
                    realmConfiguration.deleteRealmIfMigrationNeeded = true
                    try! Realm.performMigration(for: realmConfiguration)
                }
            }
        }
    }
    
    /// Method that performs a migration in a specific collection.
    open func execute<T: Entity>(_ type: T.Type, oldClassName: String? = nil, migrationObjectHandler: MigrationObjectHandler? = nil) {
        let className = type.className()
        let oldSchemaClassName = oldClassName ?? className
        let oldObjectSchema = realmMigration.oldSchema[oldSchemaClassName]
        if let oldObjectSchema = oldObjectSchema {
            let oldProperties = oldObjectSchema.properties.map { $0.name }
            realmMigration.enumerateObjects(ofType: oldSchemaClassName) { (oldObject, newObject) in
                if let oldObject = oldObject, let newObject = newObject {
                    let oldDictionary = oldObject.dictionaryWithValues(forKeys: oldProperties)
                    
                    if let newDictionary = migrationObjectHandler?(oldDictionary) {
                        newObject.setValuesForKeys(newDictionary)
                    } else {
                        self.realmMigration.delete(newObject)
                    }
                }
            }
        }
    }
    
}
