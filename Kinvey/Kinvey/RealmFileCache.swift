//
//  RealmFileCache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-07-26.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift

class RealmFileCache<T: File>: FileCache {
    
    typealias FileType = T
    
    let persistenceId: String
    let realm: Realm
    let executor: Executor
    
    init(persistenceId: String, fileURL: URL? = nil, encryptionKey: Data? = nil, schemaVersion: UInt64) {
        self.persistenceId = persistenceId
        var configuration = Realm.Configuration()
        if let fileURL = fileURL {
            let fileManager = FileManager.default
            let baseURL = fileURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: baseURL.path) {
                try! fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
            }
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
    
    func save(_ file: FileType, beforeSave: (() -> Void)?) {
        executor.executeAndWait {
            try! self.realm.write {
                beforeSave?()
                self.realm.create(File.self, value: file, update: .all)
            }
        }
    }
    
    func remove(_ file: FileType) {
        executor.executeAndWait {
            try! self.realm.write {
                if let fileId = file.fileId, let file = self.realm.object(ofType: File.self, forPrimaryKey: fileId) {
                    self.realm.delete(file)
                }
                
                if let path = file.path {
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: path) {
                        do {
                            try FileManager.default.removeItem(atPath: (path as NSString).expandingTildeInPath)
                        } catch {
                            //ignore possible errors if for any reason is not possible to delete the file
                        }
                    }
                }
            }
        }
    }
    
    func get(_ fileId: String) -> FileType? {
        var file: FileType? = nil
        
        executor.executeAndWait {
            file = self.realm.object(ofType: FileType.self, forPrimaryKey: fileId)
        }
        
        return file
    }
    
}
