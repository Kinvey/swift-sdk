//
//  CacheMigrationTestCase.swift
//  Kinvey
//
//  Created by Victor Hugo on 2016-11-07.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
import Realm
import RealmSwift
import Kinvey

class NoCacheTestCase: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        let realmConfiguration = Realm.Configuration.defaultConfiguration
        if var baseURL = realmConfiguration.fileURL {
            baseURL = baseURL.URLByDeletingLastPathComponent!
            let fileManager = NSFileManager.defaultManager()
            if let fileURLs = try? fileManager.contentsOfDirectoryAtURL(baseURL, includingPropertiesForKeys: nil, options: [.SkipsHiddenFiles]) {
                for fileURL in fileURLs {
                    try! fileManager.removeItemAtURL(fileURL)
                }
            }
            
            if let fileURLs = try? fileManager.contentsOfDirectoryAtURL(baseURL, includingPropertiesForKeys: nil, options: [.SkipsHiddenFiles]) {
                XCTAssertEqual(fileURLs.count, 0)
            }
        }
    }
    
    func testNoCache() {
        Kinvey.sharedClient.initialize(appKey: "appKey", appSecret: "appSecret")
        
        let _ = DataStore<Person>.collection(.Network)
        
        let realmConfiguration = Realm.Configuration.defaultConfiguration
        if var baseURL = realmConfiguration.fileURL {
            baseURL = baseURL.URLByDeletingLastPathComponent!
            let fileManager = NSFileManager.defaultManager()
            if let fileURLs = try? fileManager.contentsOfDirectoryAtURL(baseURL, includingPropertiesForKeys: nil, options: [.SkipsHiddenFiles]) {
                XCTAssertEqual(fileURLs.count, 0)
            }
        }
    }
    
}
