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
@testable import Kinvey

class NoCacheTestCase: XCTestCase {
    
    func testNoCache() {
        let appKey = "noCacheAppKey"
        Kinvey.sharedClient.initialize(appKey: appKey, appSecret: "noCacheAppSecret")
        
        let _ = DataStore<Person>.collection(.network)
        
        let realmConfiguration = Realm.Configuration.defaultConfiguration
        if var baseURL = realmConfiguration.fileURL {
            baseURL.deleteLastPathComponent()
            baseURL.appendPathComponent(appKey)
            let fileManager = FileManager.default
            XCTAssertFalse(fileManager.fileExists(atPath: baseURL.path))
        }
    }
    
}
