//
//  CacheMigrationTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-22.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#if !SWIFT_PACKAGE

import XCTest
import RealmSwift
@testable import Kinvey
import ObjectMapper

class Person: Entity {
    
    @objc
    dynamic var firstName: String?
    
    @objc
    dynamic var lastName: String?
    
    override class func collectionName() -> String {
        return "CacheMigrationTestCase_Person"
    }
    
    override func propertyMapping(_ map: ObjectMapper.Map) {
        super.propertyMapping(map)
        
        firstName <- map["firstName"]
        lastName <- map["lastName"]
    }
}

class CacheMigrationTestCaseStep1: XCTestCase {
    
    let defaultTimeout = KinveyTestCase.defaultTimeout
    
    override func setUp() {
        let realmConfiguration = Realm.Configuration.defaultConfiguration
        if let fileURL = realmConfiguration.fileURL {
            var path = fileURL.path
            var pathComponents = (path as NSString).pathComponents
            pathComponents[pathComponents.count - 1] = "com.kinvey.appKey_cache.realm"
            path = NSString.path(withComponents: pathComponents)
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: path) {
                do {
                    try fileManager.removeItem(atPath: path)
                } catch {
                    XCTFail(error.localizedDescription)
                    return
                }
            }
        }
        
        super.setUp()
    }
    
    func testMigration() {
        Kinvey.sharedClient.initialize(appKey: "appKey", appSecret: "appSecret") {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        let store = try! DataStore<Person>.collection(.sync)
        
        let person = Person()
        person.firstName = "Victor"
        person.lastName = "Barros"
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person) {
            switch $0 {
            case .success(let person):
                XCTAssertEqual(person.firstName, "Victor")
                XCTAssertEqual(person.lastName, "Barros")
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSave = nil
        }
    }
    
}

#endif
