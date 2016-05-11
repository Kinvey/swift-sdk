//
//  EncryptedDataStoreTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-22.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class EncryptedDataStoreTestCase: StoreTestCase {
    
    lazy var filePath: NSString = {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        var filePath = paths.first! as NSString
        filePath = filePath.stringByAppendingPathComponent("com.kinvey.\(appInitialize.appKey)_cache.realm")
        return filePath
    }()
    
    override func setUp() {
        encrypted = true
        
        deleteRealmDatabase(filePath)
        
        super.setUp()
    }
    
    func testEncryptedDataStore() {
        signUp()
        
        store = DataStore<Person>.getInstance(.Network)
        
        save(newPerson)
    }
    
    override func tearDown() {
        super.tearDown()
        
        deleteRealmDatabase(filePath)
    }
    
    private func deleteRealmDatabase(path: NSString) {
        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(path as String) {
            try! fileManager.removeItemAtPath(path as String)
        }
        
        let lockPath = path.stringByAppendingPathExtension("lock")!
        if fileManager.fileExistsAtPath(lockPath) {
            try! fileManager.removeItemAtPath(lockPath)
        }
        
        let logPath = path.stringByAppendingPathExtension("log")!
        if fileManager.fileExistsAtPath(logPath) {
            try! fileManager.removeItemAtPath(logPath)
        }
        
        let logAPath = path.stringByAppendingPathExtension("log_a")!
        if fileManager.fileExistsAtPath(logAPath) {
            try! fileManager.removeItemAtPath(logAPath)
        }
        
        let logBPath = path.stringByAppendingPathExtension("log_b")!
        if fileManager.fileExistsAtPath(logBPath) {
            try! fileManager.removeItemAtPath(logBPath)
        }
    }
    
}
