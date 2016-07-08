//
//  CacheMigrationTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-22.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
import ObjectiveC
import RealmSwift
import KIF
@testable import Kinvey

class Person: Entity {
    
    dynamic var personId: String?
    dynamic var firstName: String?
    dynamic var lastName: String?
    
    override class func collectionName() -> String {
        return "CacheMigrationTestCase_Person"
    }
    
    override func propertyMapping(map: Map) {
        super.propertyMapping(map)
        
        personId <- map[PersistableIdKey]
        firstName <- map["firstName"]
        lastName <- map["lastName"]
    }
    
}

class CacheMigrationTestCaseStep1: XCTestCase {
    
    let defaultTimeout = KinveyTestCase.defaultTimeout
    
    override func setUp() {
        let realmConfiguration = Realm.Configuration.defaultConfiguration
        if let fileURL = realmConfiguration.fileURL, var path = fileURL.path {
            var pathComponents = (path as NSString).pathComponents
            pathComponents[pathComponents.count - 1] = "com.kinvey.appKey_cache.realm"
            path = NSString.pathWithComponents(pathComponents)
            let fileManager = NSFileManager.defaultManager()
            if fileManager.fileExistsAtPath(path) {
                do {
                    try fileManager.removeItemAtPath(path)
                } catch {
                    XCTFail()
                    return
                }
            }
        }
    }
    
    func testMigration() {
        Kinvey.sharedClient.initialize(appKey: "appKey", appSecret: "appSecret")
        
        let store = DataStore<Person>.getInstance(.Sync)
        
        var person = Person()
        person.firstName = "Victor"
        person.lastName = "Barros"
        
        weak var expectationSave = expectationWithDescription("Save")
        
        store.save(&person) { (person, error) in
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            if let person = person {
                XCTAssertEqual(person.firstName, "Victor")
                XCTAssertEqual(person.lastName, "Barros")
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationSave = nil
        }
    }
    
}