//
//  CacheMigrationTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-22.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
import RealmSwift
@testable import Kinvey
import ObjectMapper
import ZIPFoundation
import Nimble

class Person: Entity {
    
    @objc
    dynamic var fullName: String?
    
    override class func collectionName() -> String {
        return "CacheMigrationTestCase_Person"
    }
    
    @available(*, deprecated)
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        fullName <- map["fullName"]
    }
    
}

class CacheMigrationTestCaseStep2: XCTestCase {
    
    let defaultTimeout = KinveyTestCase.defaultTimeout
    var clearCache = true
    
    private func removeItemIfExists(at url: URL, fileManager: FileManager = FileManager.default) {
        if fileManager.fileExists(atPath: url.path) {
            try! fileManager.removeItem(at: url)
        }
    }
    
    var client: Client?
    
    override func setUp() {
        let zipDataPath = Bundle(for: CacheMigrationTestCaseStep2.self).url(forResource: "CacheMigrationTestCaseData", withExtension: "zip")!
        let zip2DataPath = Bundle(for: CacheMigrationTestCaseStep2.self).url(forResource: "CacheMigrationTestCaseData2", withExtension: "zip")!
        var destination = Realm.Configuration.defaultConfiguration.fileURL!.deletingLastPathComponent()
        #if os(macOS)
        if let xcTestConfigurationFilePath = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] {
            destination = URL(fileURLWithPath: xcTestConfigurationFilePath).deletingLastPathComponent()
        }
        #endif
        removeItemIfExists(at: destination.appendingPathComponent("__MACOSX"))
        removeItemIfExists(at: destination.appendingPathComponent("appKey"))
        removeItemIfExists(at: destination.appendingPathComponent("w12GADaufTzqoq+qlmhFzjQWppZZ0s3Rd4pbLNosL6WupD0qB7ye+nUsRVo1PVV8tr1zavgjjVFFsJWJWvAOFQ=="))
        try! FileManager.default.unzipItem(at: zipDataPath, to: destination)
        try! FileManager.default.unzipItem(at: zip2DataPath, to: destination)
        
        clearCache = true
        
        client = Client()
        
        super.setUp()
    }
    
    override func tearDown() {
        if clearCache {
            if let client = client, client.isInitialized() {
                client.cacheManager.clearAll()
            }
        }
        
        let realmConfiguration = Realm.Configuration.defaultConfiguration
        if let fileURL = realmConfiguration.fileURL {
            var fileURL = fileURL
            #if os(macOS)
            if let xcTestConfigurationFilePath = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] {
                fileURL = URL(fileURLWithPath: xcTestConfigurationFilePath)
            }
            #endif
            fileURL = fileURL.deletingLastPathComponent()
            fileURL.appendPathComponent("com.kinvey.appKey_cache.realm")
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.removeItem(at: fileURL)
                } catch {
                    XCTFail(error.localizedDescription)
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
        client!.initialize(appKey: "appKey", appSecret: "appSecret", schema: schema) {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        XCTAssertTrue(migrationCalled)
        XCTAssertTrue(migrationPersonCalled)
        
        let store = try! DataStore<Person>.collection(.sync, options: Options(client: client))
        
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
        client!.initialize(appKey: "appKey", appSecret: "appSecret", schema: schema) {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        XCTAssertTrue(migrationCalled)
        
        let store = try! DataStore<Person>.collection(.sync, options: Options(client: client))
        
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
        client!.initialize(appKey: "appKey", appSecret: "appSecret", schema: schema) {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        let store = try! DataStore<Person>.collection(.sync, options: Options(client: client))
        
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
        #if os(macOS)
        if let xcTestConfigurationFilePath = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] {
            realmConfiguration.fileURL = URL(fileURLWithPath: xcTestConfigurationFilePath)
        }
        #endif
        realmConfiguration.fileURL!.deleteLastPathComponent()
        realmConfiguration.fileURL!.appendPathComponent("appKey")
        realmConfiguration.fileURL!.appendPathComponent(lastPathComponent)
        let _ = try! Realm(configuration: realmConfiguration)
        
        let schema: Kinvey.Schema = (version: 2, migrationHandler: { migration, oldSchemaVersion in
            migration.execute(Person.self) { (oldEntity) in
                return nil
            }
        })
        expect {
            self.client!.initialize(appKey: "appKey", appSecret: "appSecret", schema: schema) { _ in
                XCTFail("Exception is expected")
            }
        }.to(raiseException(named: "RLMException", reason: "Cannot migrate Realms that are already open."))
    }
    
    func testRealmFileDecryptionFailed() {
        let appKey = "w12GADaufTzqoq+qlmhFzjQWppZZ0s3Rd4pbLNosL6WupD0qB7ye+nUsRVo1PVV8tr1zavgjjVFFsJWJWvAOFQ=="
        
        let numberOfBytes = 64
        var bytes = [UInt8](repeating: 0, count: numberOfBytes)
        let result = SecRandomCopyBytes(kSecRandomDefault, numberOfBytes, &bytes)
        guard result == 0 else {
            XCTFail("Result: \(result)")
            return
        }
        let key = Data(bytes: bytes)
        
        let expectationInitialize = expectation(description: "Initialize")
        
        let client = Client()
        client.initialize(appKey: appKey, appSecret: "appSecret", encryptionKey: key) {
            switch $0 {
            case .success:
                XCTFail("Error is expected")
            case .failure(let error):
                let error = error as NSError
                XCTAssertEqual(error.code, 2)
                XCTAssertTrue(error.userInfo["Underlying"] is String)
                if let underlyingError =  error.userInfo["Underlying"] as? String {
                    XCTAssertTrue(underlyingError.hasPrefix("Realm file decryption failed"))
                }
            }
            expectationInitialize.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout)
    }
    
}
