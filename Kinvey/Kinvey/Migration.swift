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

/// Class used to perform migrations in your local cache.
@objc(KNVMigration)
public class Migration: NSObject {
    
    public typealias MigrationHandler = (migration: Migration, schemaVersion: UInt64) -> Void
    public typealias MigrationObjectHandler = (oldEntity: JsonDictionary) -> JsonDictionary?
    
    let realmMigration: RealmSwift.Migration
    
    init(realmMigration: RealmSwift.Migration) {
        self.realmMigration = realmMigration
    }
    
    internal class func performMigration(persistenceId persistenceId: String, encryptionKey: NSData? = nil, schemaVersion: CUnsignedLongLong = 0, migrationHandler: Migration.MigrationHandler? = nil) {
        var realmBaseConfiguration = Realm.Configuration()
        if let encryptionKey = encryptionKey {
            realmBaseConfiguration.encryptionKey = encryptionKey
        }
        realmBaseConfiguration.schemaVersion = schemaVersion
        realmBaseConfiguration.migrationBlock = { migration, oldSchemaVersion in
            let migration = Migration(realmMigration: migration)
            migrationHandler?(migration: migration, schemaVersion: oldSchemaVersion)
        }
        let baseFolderURL = Client.fileURL(appKey: persistenceId).URLByDeletingLastPathComponent!
        let fileManager = NSFileManager.defaultManager()
        if let allFilesURL = try? fileManager.contentsOfDirectoryAtURL(baseFolderURL, includingPropertiesForKeys: nil, options: []) {
            for realmFileURL in allFilesURL.filter({ $0.lastPathComponent!.hasSuffix(".realm") }) {
                var realmConfiguration = realmBaseConfiguration //copy
                realmConfiguration.fileURL = realmFileURL
                do {
                    try Realm.performMigration(for: realmConfiguration)
                } catch {
                    print("Database migration failed: deleting local database.\nDetails of the failure: \(error)")
                    realmConfiguration.deleteRealmIfMigrationNeeded = true
                    try! Realm.performMigration(for: realmConfiguration)
                }
            }
        }
    }
    
    /// Method that performs a migration in a specific collection.
    public func execute<T: Entity>(type: T.Type, oldClassName: String? = nil, migrationObjectHandler: MigrationObjectHandler? = nil) {
        let className = type.className()
        let oldClassName = oldClassName ?? className
        let oldObjectSchema = realmMigration.oldSchema[oldClassName]
        if let oldObjectSchema = oldObjectSchema {
            let oldProperties = oldObjectSchema.properties.map { $0.name }
            realmMigration.enumerate(oldClassName) { (oldObject, newObject) in
                if let oldObject = oldObject {
                    let oldDictionary = oldObject.dictionaryWithValuesForKeys(oldProperties)
                    
                    let newDictionary = migrationObjectHandler?(oldEntity: oldDictionary)
                    if let newObject = newObject {
                        self.realmMigration.delete(newObject)
                    }
                    if let newDictionary = newDictionary {
                        self.realmMigration.create(className, value: newDictionary)
                    }
                }
            }
        }
    }
    
}
