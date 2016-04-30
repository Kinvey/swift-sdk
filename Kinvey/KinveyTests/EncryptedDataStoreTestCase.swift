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
        
        deleteAllDocumentFiles()
        
        super.setUp()
    }
    
    func testEncryptedDataStore() {
        signUp()
        
        store = DataStore<Person>.getInstance(.Network, client: client)
        
        save(newPerson)
    }
    
    override func tearDown() {
        super.tearDown()
        
        store = nil
        
        deleteAllDocumentFiles()
    }
    
    private func deleteAllDocumentFiles() {
        let fileManager = NSFileManager.defaultManager()
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        if let path = paths.first {
            let url = NSURL(fileURLWithPath: path)
            for url in try! fileManager.contentsOfDirectoryAtURL(url, includingPropertiesForKeys: [], options: [.SkipsSubdirectoryDescendants, .SkipsHiddenFiles]) {
                if fileManager.fileExistsAtPath(url.path!) {
                    try! fileManager.removeItemAtURL(url)
                }
            }
        }
    }
    
}
