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
            baseURL.deleteLastPathComponent()
            let fileManager = FileManager.default
            if let fileURLs = try? fileManager.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for fileURL in fileURLs {
                    try! fileManager.removeItem(at: fileURL)
                }
            }
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNoCache() {
        Kinvey.sharedClient.initialize(appKey: "appKey", appSecret: "appSecret")
        
        let _ = DataStore<Person>.collection(.network)
        
        let realmConfiguration = Realm.Configuration.defaultConfiguration
        if var baseURL = realmConfiguration.fileURL {
            baseURL.deleteLastPathComponent()
            let fileManager = FileManager.default
            if let fileURLs = try? fileManager.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                XCTAssertEqual(fileURLs.count, 0)
            }
        }
    }
    
}
