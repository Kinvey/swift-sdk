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
@testable import Kinvey
import ObjectMapper
import Zip
import Nimble

class Person: Entity {
    
    @objc
    dynamic var fullName: String?
    
    override class func collectionName() -> String {
        return "CacheMigrationTestCase_Person"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        fullName <- map["fullName"]
    }
    
}

class CacheMigrationTestCaseStep2: XCTestCase {
    
    let defaultTimeout = KinveyTestCase.defaultTimeout
    var clearCache = true
    
    override func setUp() {
        let zipDataPath = Bundle(for: CacheMigrationTestCaseStep2.self).url(forResource: "CacheMigrationTestCaseData", withExtension: "zip")!
        var unzipDirectory = try! Zip.quickUnzipFile(zipDataPath)
        let appKeyFrom = unzipDirectory.appendingPathComponent("appKey")
        let documents = unzipDirectory.deletingLastPathComponent()
        let appKeyTo = documents.appendingPathComponent("appKey")
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: appKeyTo.path) {
            try! FileManager.default.removeItem(at: appKeyTo)
        }
        try! FileManager.default.moveItem(at: appKeyFrom, to: appKeyTo)
        
        clearCache = true
        
        super.setUp()
    }
    
    override func tearDown() {
        if clearCache {
            Kinvey.sharedClient.cacheManager.clearAll()
        }
        
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
                    XCTFail()
                    return
                }
            }
        }
        
        super.tearDown()
    }
    
    func testMigration() {
        var migrationCalled = false
        var migrationPersonCalled = false
        
        let schema: Kinvey.Schema = (version: 2, migrationHandler: { migration, oldSchemaVersion in
            migrationCalled = true
            migration.execute(Person.self) { (oldEntity) in
                migrationPersonCalled = true
                
                var newEntity = oldEntity
                if oldSchemaVersion < 2 {
                    let fullName = "\(oldEntity["firstName"]!) \(oldEntity["lastName"]!)".trimmingCharacters(in: .whitespacesAndNewlines)
                    if fullName.count == 0 {
                        return nil
                    }
                    newEntity["fullName"] = fullName
                    newEntity.removeValue(forKey: "firstName")
                    newEntity.removeValue(forKey: "lastName")
                }
                
                return newEntity
            }
        })
        Kinvey.sharedClient.initialize(appKey: "appKey", appSecret: "appSecret", schema: schema) {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        XCTAssertTrue(migrationCalled)
        XCTAssertTrue(migrationPersonCalled)
        
        let store = DataStore<Person>.collection(.sync)
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find {
            switch $0 {
            case .success(let persons):
                XCTAssertEqual(persons.count, 1)
                
                if let person = persons.first {
                    XCTAssertEqual(person.fullName, "Victor Barros")
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testMigrationWithoutCallExecute() {
        var migrationCalled = false
        
        let schema: Kinvey.Schema = (version: 2, migrationHandler: { migration, oldSchemaVersion in
            migrationCalled = true
        })
        Kinvey.sharedClient.initialize(appKey: "appKey", appSecret: "appSecret", schema: schema) {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        XCTAssertTrue(migrationCalled)
        
        let store = DataStore<Person>.collection(.sync)
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find {
            switch $0 {
            case .success(let persons):
                XCTAssertEqual(persons.count, 2)
                
                XCTAssertNotNil(persons.first)
                if let person = persons.first {
                    XCTAssertNil(person.fullName)
                }
                
                XCTAssertNotNil(persons.last)
                if let person = persons.last {
                    XCTAssertNil(person.fullName)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testMigrationWithoutMigrationBlock() {
        let schema: Kinvey.Schema = (version: 2, migrationHandler: nil)
        Kinvey.sharedClient.initialize(appKey: "appKey", appSecret: "appSecret", schema: schema) {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        let store = DataStore<Person>.collection(.sync)
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find {
            switch $0 {
            case .success(let persons):
                XCTAssertEqual(persons.count, 0)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testMigrationRaiseException() {
        clearCache = false
        
        var realmConfiguration = Realm.Configuration.defaultConfiguration
        let lastPathComponent = realmConfiguration.fileURL!.lastPathComponent
        realmConfiguration.fileURL!.deleteLastPathComponent()
        realmConfiguration.fileURL!.appendPathComponent("appKey")
        realmConfiguration.fileURL!.appendPathComponent(lastPathComponent)
        let realm = try! Realm(configuration: realmConfiguration)
        
        let schema: Kinvey.Schema = (version: 2, migrationHandler: { migration, oldSchemaVersion in
            migration.execute(Person.self) { (oldEntity) in
                return nil
            }
        })
        expect {
            Kinvey.sharedClient.initialize(appKey: "appKey", appSecret: "appSecret", schema: schema) {
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            }
        }.to(raiseException(named: "RLMException", reason: "Cannot migrate Realms that are already open."))
    }
    
}
