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
    
    lazy var documentPathURL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)
    
    override func setUp() {
        super.setUp()
        
        eraseFolder(basePathURL: documentPathURL)
        
        assertEmptyFolder()
    }
    
    func eraseFolder(basePathURL: URL) {
        let fileManager = FileManager.default
        for pathURL in try! fileManager.contentsOfDirectory(at: basePathURL, includingPropertiesForKeys: [.isDirectoryKey]) {
            if let isDirectory = try! pathURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory, isDirectory {
                eraseFolder(basePathURL: pathURL)
            }
            try! fileManager.removeItem(at: pathURL)
        }
    }
    
    func testNoCache() {
        let appKey = "noCacheAppKey"
        Kinvey.sharedClient.initialize(appKey: appKey, appSecret: "noCacheAppSecret") {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        let dataStore = try! DataStore<Person>.collection(.network)
        
        mockResponse(json: [
            [
                "_id" : UUID().uuidString,
                "name" : "Victor",
                "_kmd" : [
                    "lmt" : Date().toString(),
                    "ect" : Date().toString()
                ]
            ]
        ])
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        dataStore.find {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                print(error)
                XCTFail(error.localizedDescription)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: KinveyTestCase.defaultTimeout) { (error) in
            expectationFind = nil
        }
        
        assertEmptyFolder()
    }
    
    @inline(__always)
    func assertEmptyFolder() {
        let fileManager = FileManager.default
        XCTAssertEqual(0, try! fileManager.contentsOfDirectory(at: documentPathURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).count)
    }
    
}
