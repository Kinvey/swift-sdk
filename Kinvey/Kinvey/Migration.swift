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
