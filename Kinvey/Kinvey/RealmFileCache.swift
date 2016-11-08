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
    
    let persistenceId: String
    let realm: Realm
    let executor: Executor
    
    init(persistenceId: String, fileURL: NSURL? = nil, encryptionKey: NSData? = nil, schemaVersion: UInt64) {
        self.persistenceId = persistenceId
        var configuration = Realm.Configuration()
        if let fileURL = fileURL {
            configuration.fileURL = fileURL
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
    
    func remove(file: File) {
        executor.executeAndWait {
            try! self.realm.write {
                if let fileId = file.fileId, let file = self.realm.objectForPrimaryKey(File.self, key: fileId) {
                    self.realm.delete(file)
                }
                
                if let path = file.path {
                    let fileManager = NSFileManager.defaultManager()
                    if fileManager.fileExistsAtPath(path) {
                        do {
                            try NSFileManager.defaultManager().removeItemAtPath((path as NSString).stringByExpandingTildeInPath)
                        } catch {
                            //ignore possible errors if for any reason is not possible to delete the file
                        }
                    }
                }
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
