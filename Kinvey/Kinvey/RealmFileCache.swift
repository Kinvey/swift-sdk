//
//  RealmFileCache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-07-26.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift

class RealmFileCache: FileCache {
    
    let realm: Realm
    let executor: Executor
    
    init(persistenceId: String, filePath: String? = nil, encryptionKey: NSData? = nil, schemaVersion: UInt64) {
        var configuration = Realm.Configuration()
        if let filePath = filePath {
            configuration.fileURL = NSURL(fileURLWithPath: filePath)
        }
        configuration.encryptionKey = encryptionKey
        configuration.schemaVersion = schemaVersion
        
        do {
            realm = try Realm(configuration: configuration)
        } catch {
            configuration.deleteRealmIfMigrationNeeded = true
            realm = try! Realm(configuration: configuration)
        }
        
        executor = Executor()
    }
    
    func save(file: File, beforeSave: (() -> Void)?) {
        executor.executeAndWait {
            try! self.realm.write {
                beforeSave?()
                self.realm.create(File.self, value: file, update: true)
            }
        }
    }
    
    func get(fileId: String) -> File? {
        var file: File? = nil
        
        executor.executeAndWait {
            file = self.realm.objectForPrimaryKey(File.self, key: fileId)
        }
        
        return file
    }
    
}
