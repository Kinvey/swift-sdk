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

/// Class used to perform migrations in your local cache.
open class Migration: NSObject {
    
    public typealias MigrationHandler = (Migration, UInt64) -> Void
    public typealias MigrationObjectHandler = (JsonDictionary) -> JsonDictionary?
    
    let realmMigration: RealmSwift.Migration
    
    init(realmMigration: RealmSwift.Migration) {
        self.realmMigration = realmMigration
    }
    
    internal class func performMigration(
        persistenceId: String,
        encryptionKey: Data? = nil,
        schemaVersion: CUnsignedLongLong = 0,
        migrationHandler: Migration.MigrationHandler? = nil,
        compactCacheOnLaunch: Bool = true
    ) throws {
        var realmBaseConfiguration = Realm.Configuration.defaultConfiguration
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
        realmBaseConfiguration.shouldCompactOnLaunch = { totalBytes, usedBytes in
            log.debug("Cache: \(usedBytes) bytes used in a total of \(totalBytes) bytes. Compact Cache on Launch: \(compactCacheOnLaunch)")
            return compactCacheOnLaunch
        }
        let baseFolderURL = Client.fileURL(appKey: persistenceId).deletingLastPathComponent()
        let fileManager = FileManager.default
        if let allFilesURL = try? fileManager.contentsOfDirectory(at: baseFolderURL, includingPropertiesForKeys: nil) {
            for realmFileURL in allFilesURL.filter({ $0.lastPathComponent.hasSuffix(".realm") }) {
                var realmConfiguration = realmBaseConfiguration //copy
                realmConfiguration.fileURL = realmFileURL
                try performMigration(realmConfiguration: realmConfiguration)
            }
        }
    }
    
    private class func performMigration(realmConfiguration: Realm.Configuration) throws {
        var realmConfiguration = realmConfiguration //copy
        do {
            try Realm.performMigration(for: realmConfiguration)
        } catch {
            log.error("Database migration failed: deleting local database.\nDetails of the failure: \(error)")
            realmConfiguration.deleteRealmIfMigrationNeeded = true
            try Realm.performMigration(for: realmConfiguration)
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
                    
                    if var newDictionary = migrationObjectHandler?(oldDictionary) {
                        if let primaryKeyProperty = oldObjectSchema.primaryKeyProperty {
                            newDictionary.removeValue(forKey: primaryKeyProperty.name)
                        }
                        newObject.setValuesForKeys(newDictionary)
                    } else {
                        self.realmMigration.delete(newObject)
                    }
                }
            }
        }
    }
    
}
