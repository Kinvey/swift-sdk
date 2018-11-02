//
//  SyncedStoreTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-17.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey
import Nimble
import RealmSwift

class SyncStoreTests: StoreTestCase {
    
    class CheckForNetworkURLProtocol: URLProtocol {
        
        override class func canInit(with request: URLRequest) -> Bool {
            XCTFail("A request was initialized: \(request)")
            return false
        }
        
    }
    
    override func setUp() {
        super.setUp()
        
        signUp()
        
        store = try! DataStore<Person>.collection(.sync)
    }
    
    var mockCount = 0
    
    override func tearDown() {
        if let activeUser = client.activeUser {
            let store = try! DataStore<Person>.collection(.network)
            let query = Query(format: "\(try! Person.aclProperty() ?? Person.EntityCodingKeys.acl.rawValue).creator == %@", activeUser.userId)
            
            if useMockData {
                mockResponse(json: ["count" : mockCount])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
                mockCount = 0
            }
            
            weak var expectationRemoveAll = expectation(description: "Remove All")
            
            store.remove(query) {
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationRemoveAll?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationRemoveAll = nil
            }
        }
        
        super.tearDown()
    }
    
    func testCreate() {
        let person = self.person
        
        weak var expectationCreate = expectation(description: "Create")
        
        store.save(person) {
            self.assertThread()
            switch $0 {
            case .success(let person):
                XCTAssertNotNil(person.personId)
                XCTAssertNotEqual(person.personId, "")
                
                XCTAssertNotNil(person.age)
                XCTAssertEqual(person.age, 29)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        
            expectationCreate?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCreate = nil
        }
    }
    
    func testCreateSync() {
        let person = self.person
        
        let request = store.save(person, options: nil)
        XCTAssertTrue(request.wait(timeout: defaultTimeout))
        guard let result = request.result else {
            return
        }
        switch result {
        case .success(let person):
            XCTAssertNotNil(person.personId)
            XCTAssertNotEqual(person.personId, "")
            
            XCTAssertNotNil(person.age)
            XCTAssertEqual(person.age, 29)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testCreateTryCatchSync() {
        let person = self.person
        
        let request = store.save(person, options: nil)
        do {
            let person = try request.waitForResult(timeout: defaultTimeout).value()
            XCTAssertNotNil(person.personId)
            XCTAssertNotEqual(person.personId, "")
            
            XCTAssertNotNil(person.age)
            XCTAssertEqual(person.age, 29)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testCount() {
        var _count = 0
        
        do {
            weak var expectationCount = expectation(description: "Count")
            
            store.count {
                self.assertThread()
                switch $0 {
                case .success(let count):
                    _count = count
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationCount?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCount = nil
            }
        }
        
        do {
            let person = self.person
            
            weak var expectationCreate = expectation(description: "Create")
            
            store.save(person) {
                self.assertThread()
                switch $0 {
                case .success(let person):
                    XCTAssertNotNil(person.personId)
                    XCTAssertNotEqual(person.personId, "")
                    
                    XCTAssertNotNil(person.age)
                    XCTAssertEqual(person.age, 29)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationCreate?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCreate = nil
            }
        }
        
        do {
            weak var expectationCount = expectation(description: "Count")
            
            store.count {
                self.assertThread()
                switch $0 {
                case .success(let count):
                    XCTAssertEqual(_count + 1, count)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationCount?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCount = nil
            }
        }
    }
    
    func testCountSync() {
        var _count = 0
        
        do {
            let request = store.count(options: nil)
            XCTAssertTrue(request.wait(timeout: defaultTimeout))
            guard let result = request.result else {
                return
            }
            switch result {
            case .success(let count):
                _count = count
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        guard _count != 0 else {
            return
        }
        
        do {
            let person = self.person
            
            let request = store.save(person, options: nil)
            XCTAssertTrue(request.wait(timeout: defaultTimeout))
            guard let result = request.result else {
                return
            }
            switch result {
            case .success(let person):
                XCTAssertNotNil(person.personId)
                XCTAssertNotEqual(person.personId, "")
                
                XCTAssertNotNil(person.age)
                XCTAssertEqual(person.age, 29)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        do {
            let request = store.count(options: nil)
            XCTAssertTrue(request.wait(timeout: defaultTimeout))
            guard let result = request.result else {
                return
            }
            switch result {
            case .success(let count):
                XCTAssertEqual(_count + 1, count)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func testCountTryCatchSync() {
        var _count = 0
        
        do {
            let request = store.count(options: nil)
            let count = try request.waitForResult(timeout: defaultTimeout).value()
            _count = count
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        guard _count != 0 else {
            return
        }
        
        let person = self.person
        
        do {
            let request = store.save(person, options: nil)
            let person = try request.waitForResult(timeout: defaultTimeout).value()
            XCTAssertNotNil(person.personId)
            XCTAssertNotEqual(person.personId, "")
            
            XCTAssertNotNil(person.age)
            XCTAssertEqual(person.age, 29)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        do {
            let request = store.count(options: nil)
            let count = try request.waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(_count + 1, count)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testUpdate() {
        save()
        
        weak var expectationFind = expectation(description: "Create")
        
        var savedPerson:Person?
        
        store.find {
            self.assertThread()
            switch $0 {
            case .success(let persons):
                XCTAssertGreaterThan(persons.count, 0)
                if let person = persons.first {
                    savedPerson = person
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }

        weak var expectationUpdate = expectation(description: "Update")
        
        savedPerson?.age = 30
        
        store.save(savedPerson!) {
            self.assertThread()
            switch $0 {
            case .success(let person):
                XCTAssertNotNil(person.personId)
                XCTAssertNotEqual(person.personId, "")
                
                XCTAssertNotNil(person.age)
                XCTAssertEqual(person.age, 30)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationUpdate?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationUpdate = nil
        }
        
    }
    
    func testCustomTag() {
        let fileManager = FileManager.default
        
        let path = cacheBasePath
        let tag = "Custom Identifier"
        let customPath = "\(path)/\(client.appKey!)/\(tag).realm"
        
        let removeFiles: () -> Void = {
            if fileManager.fileExists(atPath: customPath) {
                try! fileManager.removeItem(atPath: customPath)
            }
            
            let lockPath = (customPath as NSString).appendingPathExtension("lock")!
            if fileManager.fileExists(atPath: lockPath) {
                try! fileManager.removeItem(atPath: lockPath)
            }
            
            let logPath = (customPath as NSString).appendingPathExtension("log")!
            if fileManager.fileExists(atPath: logPath) {
                try! fileManager.removeItem(atPath: logPath)
            }
            
            let logAPath = (customPath as NSString).appendingPathExtension("log_a")!
            if fileManager.fileExists(atPath: logAPath) {
                try! fileManager.removeItem(atPath: logAPath)
            }
            
            let logBPath = (customPath as NSString).appendingPathExtension("log_b")!
            if fileManager.fileExists(atPath: logBPath) {
                try! fileManager.removeItem(atPath: logBPath)
            }
        }
        
        removeFiles()
        XCTAssertFalse(fileManager.fileExists(atPath: customPath))
        
        store = try! DataStore<Person>.collection(.sync, tag: tag)
        defer {
            removeFiles()
            XCTAssertFalse(fileManager.fileExists(atPath: customPath))
        }
        XCTAssertTrue(fileManager.fileExists(atPath: customPath))
    }
    
    func testPurge() {
        store.clearCache()
        XCTAssertEqual(store.syncCount(), 0)
        
        var persons = [Person]()
        do {
            if useMockData {
                mockResponse(json: [
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Test 1",
                        "age" : 29,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : [
                            "lmt" : Date().toISO8601(),
                            "ect" : Date().toISO8601()
                        ]
                    ],
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Test 2",
                        "age" : 30,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : [
                            "lmt" : Date().toISO8601(),
                            "ect" : Date().toISO8601()
                        ]
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPush = expectation(description: "Push")
            
            store.pull() { (_persons, error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(_persons)
                XCTAssertNil(error)
                
                if let _persons = _persons {
                    XCTAssertGreaterThanOrEqual(_persons.count, 2)
                    persons = _persons
                }
                
                expectationPush?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPush = nil
            }
        }
        
        if let person = persons.first {
            person.name = "Test 1 (Renamed)"
            
            weak var expectationRemove = expectation(description: "Remove")
            
            store.save(person) {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRemove = nil
            }
        }
        if let person = persons.last {
            weak var expectationRemove = expectation(description: "Remove")
            
            store.remove(byId: person.entityId!) {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success(let count):
                    XCTAssertEqual(count, 1)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRemove = nil
            }
        }
        save()
        
        XCTAssertEqual(store.syncCount(), 3)
        
        if useMockData {
            var count = 0
            mockResponse(completionHandler: { (request) -> HttpResponse in
                defer {
                    count += 1
                }
                switch count {
                case 0:
                    return HttpResponse(json: persons.last!.toJSON())
                case 1:
                    return HttpResponse(json: persons.toJSON())
                default:
                    Swift.fatalError()
                }
            })
        }
        defer {
            if useMockData { setURLProtocol(nil) }
        }
        
        weak var expectationPurge = expectation(description: "Purge")
        
        let query = Query(format: "acl.creator == %@", client.activeUser!.userId)
        store.purge(query) { (count, error) -> Void in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            
            if let count = count {
                XCTAssertEqual(count, 3)
            }
            
            expectationPurge?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPurge = nil
        }
        
        XCTAssertEqual(store.syncCount(), 0)
    }
    
    func testPurgeUpdateTimeoutError() {
        store.clearCache()
        XCTAssertEqual(store.syncCount(), 0)
        
        var persons = [Person]()
        do {
            if useMockData {
                mockResponse(json: [
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Test 1",
                        "age" : 29,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : [
                            "lmt" : Date().toISO8601(),
                            "ect" : Date().toISO8601()
                        ]
                    ],
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Test 2",
                        "age" : 30,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : [
                            "lmt" : Date().toISO8601(),
                            "ect" : Date().toISO8601()
                        ]
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPush = expectation(description: "Push")
            
            store.pull() { (_persons, error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(_persons)
                XCTAssertNil(error)
                
                if let _persons = _persons {
                    XCTAssertGreaterThanOrEqual(_persons.count, 2)
                    persons = _persons
                }
                
                expectationPush?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPush = nil
            }
        }
        
        if let person = persons.first {
            person.name = "Test 1 (Renamed)"
            
            weak var expectationRemove = expectation(description: "Remove")
            
            store.save(person) {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRemove = nil
            }
        }
        if let person = persons.last {
            weak var expectationRemove = expectation(description: "Remove")
            
            store.remove(byId: person.entityId!) {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success(let count):
                    XCTAssertEqual(count, 1)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRemove = nil
            }
        }
        save()
        
        XCTAssertEqual(store.syncCount(), 3)
        
        if useMockData {
            var count = 0
            mockResponse(completionHandler: { (request) -> HttpResponse in
                defer {
                    count += 1
                }
                switch count {
                case 0:
                    return HttpResponse(error: timeoutError)
                case 1:
                    return HttpResponse(json: persons.toJSON())
                default:
                    Swift.fatalError()
                }
            })
        }
        defer {
            if useMockData { setURLProtocol(nil) }
        }
        
        weak var expectationPurge = expectation(description: "Purge")
        
        let query = Query(format: "acl.creator == %@", client.activeUser!.userId)
        store.purge(query) { (count, error) in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(count)
            XCTAssertNotNil(error)
            
            XCTAssertTimeoutError(error)
            
            expectationPurge?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPurge = nil
        }
        
        XCTAssertEqual(store.syncCount(), 1)
    }
    
    func testPurgeInvalidDataStoreType() {
        save()
        
        store = try! DataStore<Person>.collection(.network)
        
        weak var expectationPurge = expectation(description: "Purge")
        
        let query = Query(format: "acl.creator == %@", client.activeUser!.userId)
        store.purge(query) { (count, error) -> Void in
            self.assertThread()
            XCTAssertNil(count)
            XCTAssertNotNil(error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .invalidDataStoreType:
                    break
                default:
                    XCTFail(error.localizedDescription)
                }
            }
            
            expectationPurge?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPurge = nil
        }
    }
    
    func testPurgeTimeoutError() {
        let person = save()
        person.age += 1
        save(person)
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationPurge = expectation(description: "Purge")
        
        let query = Query(format: "acl.creator == %@", client.activeUser!.userId)
        store.purge(query) { (count, error) -> Void in
            XCTAssertNil(count)
            XCTAssertNotNil(error)
            
            XCTAssertTimeoutError(error)
            
            expectationPurge?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPurge = nil
        }
    }
    
    func testPurgeTimeoutErrorSync() {
        let person = save()
        person.age += 1
        save(person)
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        let query = Query(format: "acl.creator == %@", client.activeUser!.userId)
        let request = store.purge(query, options: nil)
        XCTAssertTrue(request.wait(timeout: defaultTimeout))
        guard let result = request.result else {
            return
        }
        switch result {
        case .success:
            XCTFail("A failure result is expected")
        case .failure(let error):
            XCTAssertTimeoutError(error)
        }
    }
    
    func testPurgeTimeoutErrorTryCatchSync() {
        let person = save()
        person.age += 1
        save(person)
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        let query = Query(format: "acl.creator == %@", client.activeUser!.userId)
        let request = store.purge(query, options: nil)
        do {
            let _ = try request.waitForResult(timeout: defaultTimeout).value()
        } catch {
            XCTAssertTimeoutError(error)
        }
    }
    
    func testSync() {
        var person = save()
        
        XCTAssertEqual(store.syncCount(), 1)
        let realm = (store.cache!.cache as! RealmCache<Person>).newRealm
        
        var personMockJson = [JsonDictionary]()
        if useMockData {
            mockResponse { (request) -> HttpResponse in
                let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                switch (request.httpMethod!, urlComponents.path) {
                case ("POST", "/appdata/_kid_/Person"):
                    var json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
                    json[Entity.EntityCodingKeys.entityId] = UUID().uuidString
                    json[Entity.EntityCodingKeys.acl] = [
                        Acl.CodingKeys.creator.rawValue : self.client.activeUser!.userId
                    ]
                    json[Entity.EntityCodingKeys.metadata] = [
                        Metadata.CodingKeys.lastModifiedTime.rawValue : Date().toISO8601(),
                        Metadata.CodingKeys.entityCreationTime.rawValue : Date().toISO8601()
                    ]
                    personMockJson.append(json)
                    return HttpResponse(statusCode: 201, json: json)
                case ("GET", "/appdata/_kid_/Person"), ("GET", "/appdata/_kid_/Person/"):
                    XCTAssertNotNil(personMockJson)
                    return HttpResponse(statusCode: 200, json: personMockJson)
                case ("DELETE", "/appdata/_kid_/Person/\(person.entityId!)"):
                    if let idx = personMockJson.index(where: { $0[Entity.EntityCodingKeys.entityId] as? String == person.entityId }) {
                        personMockJson.remove(at: idx)
                        return HttpResponse(statusCode: 200, json: ["count" : 1])
                    }
                    fallthrough
                default:
                    XCTFail("HTTP Method: \(request.httpMethod!)")
                    XCTFail("URL Path: \(urlComponents.path)")
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
        }
        defer {
            if useMockData { setURLProtocol(nil) }
        }
        
        do {
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync() { count, results, error in
                self.assertThread()
                XCTAssertNotNil(count)
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let count = count {
                    XCTAssertEqual(count, 1)
                }
                
                XCTAssertEqual(realm.objects(Metadata.self).count, 1)
                
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
            
            XCTAssertEqual(store.syncCount(), 0)
        }
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            store.find() {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 1)
                    if let _person = persons.first {
                        person = _person
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                XCTAssertEqual(realm.objects(Metadata.self).count, 1)
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
            
            XCTAssertEqual(store.syncCount(), 0)
        }
        
        do {
            weak var expectationRemove = expectation(description: "Remove")
            
            try store.remove(person) {
                switch $0 {
                case .success(let count):
                    XCTAssertEqual(count, 1)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                XCTAssertEqual(realm.objects(Metadata.self).count, 0)
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRemove = nil
            }
            
            XCTAssertEqual(store.syncCount(), 1)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        do {
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync() { count, results, error in
                self.assertThread()
                XCTAssertNotNil(count)
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let count = count {
                    XCTAssertEqual(count, 1)
                }
                
                XCTAssertEqual(realm.objects(Metadata.self).count, 0)
                
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
            
            XCTAssertEqual(store.syncCount(), 0)
        }
    }
    
    func testSyncPullTimeoutError() {
        save()
        
        XCTAssertEqual(store.syncCount(), 1)
        
        if useMockData {
            var count = 0
            var personMockJson: JsonDictionary? = nil
            mockResponse { (request) -> HttpResponse in
                defer { count += 1 }
                switch count {
                case 0:
                    XCTAssertEqual(request.httpMethod, "POST")
                    var json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
                    json[Entity.EntityCodingKeys.entityId] = UUID().uuidString
                    json[Entity.EntityCodingKeys.acl] = [
                        Acl.CodingKeys.creator.rawValue : self.client.activeUser!.userId
                    ]
                    json[Entity.EntityCodingKeys.metadata] = [
                        Metadata.CodingKeys.lastModifiedTime.rawValue : Date().toISO8601(),
                        Metadata.CodingKeys.entityCreationTime.rawValue : Date().toISO8601()
                    ]
                    personMockJson = json
                    return HttpResponse(statusCode: 201, json: json)
                case 1:
                    return HttpResponse(error: timeoutError)
                default:
                    Swift.fatalError()
                }
            }
        }
        defer {
            if useMockData { setURLProtocol(nil) }
        }
        
        weak var expectationSync = expectation(description: "Sync")
        
        store.sync() { count, results, errors in
            XCTAssertMainThread()
            
            XCTAssertNil(count)
            XCTAssertNil(results)
            XCTAssertNotNil(errors)
            
            XCTAssertEqual(errors?.count, 1)
            XCTAssertTimeoutError(errors?.first)
            
            expectationSync?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSync = nil
        }
        
        XCTAssertEqual(store.syncCount(), 0)
    }
    
    func testSyncInvalidDataStoreType() {
        save()
        
        store = try! DataStore<Person>.collection(.network)
        
        weak var expectationSync = expectation(description: "Sync")
        
        store.sync() { count, results, errors in
            self.assertThread()
            XCTAssertNil(count)
            XCTAssertNotNil(errors)
            
            if let errors = errors {
                if let error = errors.first as? Kinvey.Error {
                    switch error {
                    case .invalidDataStoreType:
                        break
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            
            expectationSync?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSync = nil
        }
    }
    
    func testSyncTimeoutError() {
        save()
        
        setURLProtocol(TimeoutErrorURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationSync = expectation(description: "Sync")
        
        store.sync() { count, results, error in
            self.assertThread()
            XCTAssertNil(count)
            XCTAssertNil(results)
            XCTAssertNotNil(error)
            
            expectationSync?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSync = nil
        }
        XCTAssertEqual(store.syncCount(), 1)
    }
    
    func testSyncNoCompletionHandler() {
        save()
        
        let request = store.sync { (_, _, _) in
        }
        
        XCTAssertTrue(wait(toBeTrue: !request.executing))
    }
    
    func testPush() {
        save()
        
        let bookDataStore = try! DataStore<Book>.collection(.sync)
        
        do {
            let book = Book()
            book.title = "Les Miserables"
            
            weak var expectationSave = expectation(description: "Save Book")
            
            bookDataStore.save(book, options: nil) { (result: Result<Book, Swift.Error>) in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSave = nil
            }
        }
        
        XCTAssertEqual(store.syncCount(), 1)
        
        if useMockData {
            mockResponse { request -> HttpResponse in
                XCTAssertEqual(request.httpMethod, "POST")
                var json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
                json[Entity.EntityCodingKeys.entityId] = UUID().uuidString
                json[Entity.EntityCodingKeys.acl] = [
                    Acl.CodingKeys.creator.rawValue : self.client.activeUser!.userId
                ]
                json[Entity.EntityCodingKeys.metadata] = [
                    Metadata.CodingKeys.lastModifiedTime.rawValue : Date().toISO8601(),
                    Metadata.CodingKeys.entityCreationTime.rawValue : Date().toISO8601()
                ]
                return HttpResponse(statusCode: 201, json: json)
            }
        }
        defer {
            if useMockData { setURLProtocol(nil) }
        }
        
        weak var expectationPush = expectation(description: "Push")
        
        store.push() { count, error in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            
            if let count = count {
                XCTAssertEqual(Int(count), 1)
            }
            
            expectationPush?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPush = nil
        }
        
        XCTAssertEqual(store.syncCount(), 0)
    }
    
    func testPushSync() {
        save()
        
        let bookDataStore = try! DataStore<Book>.collection(.sync)
        
        do {
            let book = Book()
            book.title = "Les Miserables"
            
            weak var expectationSave = expectation(description: "Save Book")
            
            bookDataStore.save(book, options: nil) { (result: Result<Book, Swift.Error>) in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSave = nil
            }
        }
        
        XCTAssertEqual(store.syncCount(), 1)
        
        if useMockData {
            mockResponse { request -> HttpResponse in
                XCTAssertEqual(request.httpMethod, "POST")
                var json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
                json[Entity.EntityCodingKeys.entityId] = UUID().uuidString
                json[Entity.EntityCodingKeys.acl] = [
                    Acl.CodingKeys.creator.rawValue : self.client.activeUser!.userId
                ]
                json[Entity.EntityCodingKeys.metadata] = [
                    Metadata.CodingKeys.lastModifiedTime.rawValue : Date().toISO8601(),
                    Metadata.CodingKeys.entityCreationTime.rawValue : Date().toISO8601()
                ]
                return HttpResponse(statusCode: 201, json: json)
            }
        }
        defer {
            if useMockData { setURLProtocol(nil) }
        }
        
        let request = store.push(options: nil)
        XCTAssertTrue(request.wait(timeout: defaultTimeout))
        guard let result = request.result else {
            return
        }
        switch result {
        case .success(let count):
            XCTAssertEqual(Int(count), 1)
        case .failure(let errors):
            XCTAssertGreaterThan(errors.count, 0)
            XCTAssertNil(errors.first)
            if let error = errors.first {
                XCTFail(error.localizedDescription)
            }
        }
        
        XCTAssertEqual(store.syncCount(), 0)
    }
    
    func testPushTryCatchSync() {
        save()
        
        let bookDataStore = try! DataStore<Book>.collection(.sync)
        
        do {
            let book = Book()
            book.title = "Les Miserables"
            
            let _ = try bookDataStore.save(book, options: nil).waitForResult(timeout: defaultTimeout).value()
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        XCTAssertEqual(store.syncCount(), 1)
        
        if useMockData {
            mockResponse { request -> HttpResponse in
                XCTAssertEqual(request.httpMethod, "POST")
                var json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
                json[Entity.EntityCodingKeys.entityId] = UUID().uuidString
                json[Entity.EntityCodingKeys.acl] = [
                    Acl.CodingKeys.creator.rawValue : self.client.activeUser!.userId
                ]
                json[Entity.EntityCodingKeys.metadata] = [
                    Metadata.CodingKeys.lastModifiedTime.rawValue : Date().toISO8601(),
                    Metadata.CodingKeys.entityCreationTime.rawValue : Date().toISO8601()
                ]
                return HttpResponse(statusCode: 201, json: json)
            }
        }
        defer {
            if useMockData { setURLProtocol(nil) }
        }
        
        do {
            let count = try store.push(options: nil).waitForResult().value()
            XCTAssertEqual(Int(count), 1)
        } catch {
            XCTAssertTrue(error is MultipleErrors)
            if let multipleErrors = error as? MultipleErrors {
                let errors = multipleErrors.errors
                XCTAssertGreaterThan(errors.count, 0)
                XCTAssertNil(errors.first)
                if let error = errors.first {
                    XCTFail(error.localizedDescription)
                }
            }
        }
        
        XCTAssertEqual(store.syncCount(), 0)
    }
    
    func testPushError401EmptyBody() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        XCTAssertEqual(store.syncCount(), 0)
        
        save()
        
        defer {
            store.clearCache()
            
            XCTAssertEqual(store.syncCount(), 0)
        }
        
        XCTAssertEqual(store.syncCount(), 1)
        
        if useMockData {
            mockResponse(statusCode: 401, json: [:])
        }
        defer {
            if useMockData { setURLProtocol(nil) }
        }
        
        weak var expectationPush = expectation(description: "Push")
        
        store.push() { count, error in
            self.assertThread()
            XCTAssertNil(count)
            XCTAssertNotNil(error)
            
            expectationPush?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPush = nil
        }
        
        XCTAssertEqual(store.syncCount(), 0)
        XCTAssertNil(client.activeUser)
    }
    
    func testPushInvalidDataStoreType() {
        save()
        
        store = try! DataStore<Person>.collection(.network)
		defer {
            store.clearCache()
        }
        
        weak var expectationPush = expectation(description: "Push")
        
        store.push() { count, errors in
            self.assertThread()
            XCTAssertNil(count)
            XCTAssertNotNil(errors)
            
            if let errors = errors {
                if let error = errors.first as? Kinvey.Error {
                    switch error {
                    case .invalidDataStoreType:
                        break
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            
            expectationPush?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPush = nil
        }
    }
    
    func testPushNoCompletionHandler() {
        save()
        
        let request = store.push { (_, _) in
        }
        
        XCTAssertTrue(wait(toBeTrue: !request.executing))
    }
    
    func testPull() {
        MockKinveyBackend.kid = client.appKey!
        setURLProtocol(MockKinveyBackend.self)
        defer {
            setURLProtocol(nil)
        }
        
        let md = Metadata()
        md.lastModifiedTime = Date()
        
        MockKinveyBackend.appdata = [
            "Person" : [
                Person { $0.personId = "Victor"; $0.metadata = md }.toJSON(),
                Person { $0.personId = "Hugo"; $0.metadata = md }.toJSON(),
                Person { $0.personId = "Barros"; $0.metadata = md }.toJSON()
            ]
        ]
        
        store.clearCache(query: Query())
        let realm = (store.cache!.cache as! RealmCache<Person>).newRealm
        
        do {
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 3)
                    
                    let cacheCount = Int((self.store.cache?.count(query: nil))!)
                    XCTAssertEqual(cacheCount, results.count)
                }
                
                XCTAssertEqual(realm.objects(Metadata.self).count, 3)
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            let query = Query(format: "personId == %@", "Victor")
            
            weak var expectationPull = expectation(description: "Pull")

			store.clearCache()
            
            store.pull(query) { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 1)
                    
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertEqual(cacheCount, results.count)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.personId, "Victor")
                    }
                }
                
                XCTAssertEqual(realm.objects(Metadata.self).count, 1)
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            weak var expectationPull = expectation(description: "Pull")
            
            store.find {
                self.assertThread()
                switch $0 {
                case .success(let results):
                    XCTAssertEqual(results.count, 1)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        MockKinveyBackend.appdata = [
            "Person" : [
                Person { $0.personId = "Hugo"; $0.metadata = md }.toJSON()
            ]
        ]
        
        do {
            let query = Query(format: "personId == %@", "Victor")
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.clearCache()
            
            store.pull(query) { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 0)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            weak var expectationPull = expectation(description: "Pull")
            
            store.find {
                self.assertThread()
                switch $0 {
                case .success(let results):
                    XCTAssertEqual(results.count, 0)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        MockKinveyBackend.appdata = [
            "Person" : [
                Person { $0.personId = "Victor"; $0.metadata = md }.toJSON()
            ]
        ]
        
        do {
            let query = Query(format: "personId == %@", "Victor")
            
            weak var expectationPull = expectation(description: "Pull")

			store.clearCache()
            
            store.pull(query) { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.personId, "Victor")
                        
                        let cacheCount = self.store.cache?.count(query: nil)
                        XCTAssertEqual(cacheCount, results.count)

                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            weak var expectationPull = expectation(description: "Pull")
            
            store.find {
                self.assertThread()
                switch $0 {
                case .success(let results):
                    XCTAssertEqual(results.count, 1)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
    }
    
    func testPullPendingSyncItems() {
        save()
        
        weak var expectationPull = expectation(description: "Pull")
        
        store.pull {
            self.assertThread()
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                break
            }
            
            expectationPull?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPull = nil
        }
        
    }
    func testPullInvalidDataStoreType() {
        //save()
        
        store = try! DataStore<Person>.collection(.network)
        
        weak var expectationPull = expectation(description: "Pull")
        
        store.pull() { results, error in
            self.assertThread()
            XCTAssertNil(results)
            XCTAssertNotNil(error)
            
            if let error = error {
                XCTAssertEqual(error as NSError, Kinvey.Error.invalidDataStoreType as NSError)
            }
            
            expectationPull?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPull = nil
        }
    }
    
    func testFindById() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        guard let personId = person.personId else { return }
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(personId) {
            self.assertThread()
            switch $0 {
            case .success(let result):
                XCTAssertEqual(result.personId, personId)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testFindByIdSync() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        guard let personId = person.personId else { return }
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        let request = store.find(personId, options: nil)
        XCTAssertTrue(request.wait(timeout: defaultTimeout))
        guard let result = request.result else {
            return
        }
        switch result {
        case .success(let person):
            XCTAssertEqual(person.personId, personId)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testFindByIdTryCatchSync() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        guard let personId = person.personId else { return }
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        let request = store.find(personId, options: nil)
        do {
            let person = try request.waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(person.personId, personId)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testFindByQuery() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        guard let personId = person.personId else { return }
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        let query = Query(format: "personId == %@", personId)
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(query) {
            self.assertThread()
            switch $0 {
            case .success(let results):
                XCTAssertNotNil(results.first)
                if let result = results.first {
                    XCTAssertEqual(result.personId, personId)
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
    
    func testFindByQuerySync() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        guard let personId = person.personId else { return }
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        let query = Query(format: "personId == %@", personId)
        
        let request = store.find(query, options: nil)
        XCTAssertTrue(request.wait(timeout: defaultTimeout))
        guard let result = request.result else {
            return
        }
        switch result {
        case .success(let results):
            XCTAssertNotNil(results.first)
            if let result = results.first {
                XCTAssertEqual(result.personId, personId)
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testFindByQueryTryCatchSync() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        guard let personId = person.personId else { return }
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        let query = Query(format: "personId == %@", personId)
        
        let request = store.find(query, options: nil)
        do {
            let results = try request.waitForResult(timeout: defaultTimeout).value()
            XCTAssertNotNil(results.first)
            if let result = results.first {
                XCTAssertEqual(result.personId, personId)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testRemovePersistable() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectation(description: "Remove")
        
        do {
            try store.remove(person) {
                self.assertThread()
                switch $0 {
                case .success(let count):
                    XCTAssertEqual(count, 1)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationRemove?.fulfill()
            }
        } catch {
            XCTFail(error.localizedDescription)
            expectationRemove?.fulfill()
        }
            
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testRemovePersistableSync() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        do {
            let request = try store.remove(person, options: nil)
            XCTAssertTrue(request.wait(timeout: defaultTimeout))
            guard let result = request.result else {
                return
            }
            switch result {
            case .success(let count):
                XCTAssertEqual(count, 1)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testRemovePersistableTryCatchSync() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        do {
            let request = try store.remove(person, options: nil)
            let count = try request.waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(count, 1)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testRemovePersistableIdMissing() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectation(description: "Remove")
        
        do {
            person.personId = nil
            try store.remove(person) { _ in
                XCTFail("Handler was not expected to be called")
                
                expectationRemove?.fulfill()
            }
            XCTFail("Error is expected")
        } catch {
            expectationRemove?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testRemovePersistableArray() {
        let person1 = save(newPerson)
        let person2 = save(newPerson)
        
        XCTAssertNotNil(person1.personId)
        XCTAssertNotNil(person2.personId)
        
        guard let personId1 = person1.personId, let personId2 = person2.personId else { return }
        
        XCTAssertNotEqual(personId1, personId2)
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectation(description: "Remove")
        
        store.remove([person1, person2]) {
            self.assertThread()
            switch $0 {
            case .success(let count):
                XCTAssertEqual(count, 2)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationRemove?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testRemoveAll() {
        let person1 = save(newPerson)
        let person2 = save(newPerson)
        
        XCTAssertNotNil(person1.personId)
        XCTAssertNotNil(person2.personId)
        
        guard let personId1 = person1.personId, let personId2 = person2.personId else { return }
        
        XCTAssertNotEqual(personId1, personId2)
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectation(description: "Remove")
        
        store.removeAll() {
            self.assertThread()
            switch $0 {
            case .success(let count):
                XCTAssertEqual(count, 2)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationRemove?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testExpiredTTL() {
        store.ttl = 1.seconds
        
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        Thread.sleep(forTimeInterval: 1)
        
        if let personId = person.personId {
            weak var expectationGet = expectation(description: "Get")
            
            let query = Query(format: "personId == %@", personId)
            store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 0)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationGet?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationGet = nil
            }
        }
        
        store.ttl = nil
        
        if let personId = person.personId {
            weak var expectationGet = expectation(description: "Get")
            
            let query = Query(format: "personId == %@", personId)
            store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 1)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationGet?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationGet = nil
            }
        }
    }
    
    func testSaveAndFind10SkipLimit() {
        XCTAssertNotNil(Kinvey.sharedClient.activeUser)
        
        guard let user = Kinvey.sharedClient.activeUser else {
            return
        }
        
        var i = 0
        
        measure {
            let person = Person {
                $0.name = "Person \(i)"
            }
            
            weak var expectationSave = self.expectation(description: "Save")
            
            self.store.save(person, options: try! Options(writePolicy: .forceLocal)) {
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationSave?.fulfill()
            }
            
            self.waitForExpectations(timeout: self.defaultTimeout) { error in
                expectationSave = nil
            }
            
            i += 1
        }
        
        var skip = 0
        let limit = 2
        
        for _ in 0 ..< 5 {
            weak var expectationFind = expectation(description: "Find")
            
            let query = Query {
                $0.skip = skip
                $0.limit = limit
                $0.ascending("name")
            }
            
            store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                switch $0 {
                case .success(let results):
                    XCTAssertEqual(results.count, limit)
                    
                    XCTAssertNotNil(results.first)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Person \(skip)")
                    }
                    
                    XCTAssertNotNil(results.last)
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Person \(skip + 1)")
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                skip += limit
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            let query = Query {
                $0.limit = 5
                $0.ascending("name")
            }
            
            store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                switch $0 {
                case .success(let results):
                    XCTAssertEqual(results.count, 5)
                    
                    XCTAssertNotNil(results.first)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Person 0")
                    }
                    
                    XCTAssertNotNil(results.last)
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Person 4")
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
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            let query = Query {
                $0.skip = 5
                $0.ascending("name")
            }
            
            store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                switch $0 {
                case .success(let results):
                    XCTAssertEqual(results.count, 5)
                    
                    XCTAssertNotNil(results.first)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Person 5")
                    }
                    
                    XCTAssertNotNil(results.last)
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Person 9")
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
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            let query = Query {
                $0.skip = 6
                $0.limit = 6
                $0.ascending("name")
            }
            
            store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                switch $0 {
                case .success(let results):
                    XCTAssertEqual(results.count, 4)
                    
                    XCTAssertNotNil(results.first)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Person 6")
                    }
                    
                    XCTAssertNotNil(results.last)
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Person 9")
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

        do {
            weak var expectationFind = expectation(description: "Find")
            
            let query = Query {
                $0.skip = 10
                $0.ascending("name")
            }
            
            store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                switch $0 {
                case .success(let results):
                    XCTAssertEqual(results.count, 0)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            let query = Query {
                $0.skip = 11
                $0.ascending("name")
            }
            
            store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                switch $0 {
                case .success(let results):
                    XCTAssertEqual(results.count, 0)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        var mockObjects = [JsonDictionary]()
        
        do {
            if useMockData {
                mockResponse { request -> HttpResponse in
                    let json = self.decorateJsonFromPostRequest(request)
                    mockObjects.append(json)
                    return HttpResponse(statusCode: 201, json: json)
                }
            }
            defer {
                if useMockData { setURLProtocol(nil) }
            }
            
            weak var expectationPush = expectation(description: "Push")
            
            store.push { count, error in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                if let count = count {
                    XCTAssertEqual(count, 10)
                }
                
                expectationPush?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPush = nil
            }
        }
        
        skip = 0
        
        if useMockData {
            mockResponse { request -> HttpResponse in
                let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                let skip = Int(urlComponents.queryItems!.filter { $0.name == "skip" }.first!.value!)!
                let limt = Int(urlComponents.queryItems!.filter { $0.name == "limit" }.first!.value!)!
                let mockObjects = mockObjects.sorted(by: { (obj1, obj2) -> Bool in
                    let name1 = obj1["name"] as! String
                    let name2 = obj2["name"] as! String
                    return name1 < name2
                })
                let filteredObjects = [JsonDictionary](mockObjects[skip ..< skip + limit])
                return HttpResponse(json: filteredObjects)
            }
        }
        defer {
            if useMockData { setURLProtocol(nil) }
        }
        
        for _ in 0 ..< 5 {
            weak var expectationFind = expectation(description: "Find")
            
            let query = Query {
                $0.predicate = NSPredicate(format: "acl.creator == %@", user.userId)
                $0.skip = skip
                $0.limit = limit
                $0.ascending("name")
            }
            
            store.pull(query) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, limit)
                    
                    XCTAssertNotNil(results.first)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Person \(skip)")
                    }
                    
                    XCTAssertNotNil(results.last)
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Person \(skip + 1)")
                    }
                }
                
                skip += limit
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
    }
    
//    func testSyncMultithread() {
//        if useMockData {
//            var personMockJson: JsonDictionary? = nil
//            mockResponse { (request) -> HttpResponse in
//                switch request.httpMethod?.uppercased() ?? "GET" {
//                case "POST":
//                    var json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
//                    json[PersistableIdKey] = UUID().uuidString
//                    json[PersistableAclKey] = [
//                        Acl.Key.creator : self.client.activeUser!.userId
//                    ]
//                    json[PersistableMetadataKey] = [
//                        Metadata.LmtKey : Date().toString(),
//                        Metadata.EctKey : Date().toString()
//                    ]
//                    personMockJson = json
//                    return HttpResponse(statusCode: 201, json: json)
//                case "GET":
//                    XCTAssertNotNil(personMockJson)
//                    return HttpResponse(statusCode: 200, json: [personMockJson!])
//                default:
//                    Swift.fatalError()
//                }
//            }
//        }
//        defer {
//            if useMockData {
//                setURLProtocol(nil)
//            }
//        }
//        
//        let timerSave = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (timer) in
//            self.store.save(self.newPerson) { (person, error) -> Void in
//                XCTAssertTrue(Thread.isMainThread)
//                XCTAssertNotNil(person)
//                XCTAssertNil(error)
//                
//                guard timer.isValid else { return }
//                
//                self.store.sync() { count, results, error in
//                    XCTAssertTrue(Thread.isMainThread)
//                    XCTAssertNotNil(count)
//                    XCTAssertNotNil(results)
//                    XCTAssertNil(error)
//                    
//                    guard timer.isValid else { return }
//                }
//            }
//        }
//        
//        weak var expectationSync = expectation(description: "Sync")
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//            timerSave.invalidate()
//            
//            expectationSync?.fulfill()
//        }
//        
//        waitForExpectations(timeout: defaultTimeout) { error in
//            expectationSync = nil
//        }
//        
//        do {
//            weak var expectationPurge = expectation(description: "Purge")
//            
//            store.purge { count, error in
//                expectationPurge?.fulfill()
//            }
//            
//            waitForExpectations(timeout: defaultTimeout) { error in
//                expectationPurge = nil
//            }
//        }
//        
//        XCTAssertEqual(store.syncCount(), 0)
//    }
    
    func testPushMultithread() {
        XCTAssertEqual(store.syncCount(), 0)
        
        var personsArray = [Person]()
        
        do {
            weak var expectationSave = expectation(description: "Save")
            
            let person = Person()
            person.name = "Person 1"
            store.save(person) {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success(let person):
                    personsArray.append(person)
                    XCTAssertEqual(person.name, "Person 1")
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSave = nil
            }
        }
        
        XCTAssertEqual(store.syncCount(), 1)
        
        do {
            weak var expectationSave = expectation(description: "Save")
            
            let person = Person()
            person.name = "Person 2"
            store.save(person) {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success(let person):
                    personsArray.append(person)
                    XCTAssertEqual(person.name, "Person 2")
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSave = nil
            }
        }
        
        do {
            weak var expectationSave = expectation(description: "Save")
            
            let person = Person()
            person.name = "Person 3"
            store.save(person) {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success(let person):
                    personsArray.append(person)
                    XCTAssertEqual(person.name, "Person 3")
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSave = nil
            }
        }
        
        XCTAssertEqual(store.syncCount(), 3)
        
        do {
            personsArray[0].name = "\(personsArray[0].name!) (Renamed)"
            
            weak var expectationSave = expectation(description: "Save")
            
            store.save(personsArray[0]) {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success(let person):
                    personsArray[0] = person
                    XCTAssertEqual(person.name, "Person 1 (Renamed)")
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSave = nil
            }
        }
        
        XCTAssertEqual(store.syncCount(), 3)
        
        do {
            weak var expectationRemove = expectation(description: "Remove")
            
            store.remove(byId: personsArray[2].personId!) {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success(let count):
                    XCTAssertEqual(count, 1)
                    if count == 1 {
                        personsArray.remove(at: 2)
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRemove = nil
            }
        }
        
        XCTAssertEqual(store.syncCount(), 2)
        
        do {
            weak var expectationSave = expectation(description: "Save")
            
            let person = Person()
            person.name = "Person 3"
            store.save(person) {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success(let person):
                    personsArray.append(person)
                    XCTAssertEqual(person.name, "Person 3")
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSave = nil
            }
        }
        
        XCTAssertEqual(store.syncCount(), 3)
        
        var mockResponses = [JsonDictionary]()
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    XCTAssertEqual(request.httpMethod, "POST")
                    var json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
                    json["_id"] = UUID().uuidString
                    json["_acl"] = [
                        "creator" : self.client.activeUser!.userId
                    ]
                    json["_kmd"] = [
                        "lmt" : Date().toISO8601(),
                        "ect" : Date().toISO8601()
                    ]
                    mockResponses.append(json)
                    return HttpResponse(statusCode: 201, json: json)
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPush = expectation(description: "Push")
            
            store.push() { (count, error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                XCTAssertEqual(count, 3)
                
                expectationPush?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPush = nil
            }
        }
        
        XCTAssertEqual(store.syncCount(), 0)
        
        defer {
            do {
                weak var expectationRemove = expectation(description: "Remove")
                
                let query = Query(format: "acl.creator == %@", client.activeUser!.userId)
                
                store.remove(query) {
                    XCTAssertTrue(Thread.isMainThread)
                    switch $0 {
                    case .success(let count):
                        XCTAssertEqual(count, 3)
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationRemove?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationRemove = nil
                }
            }
            
            XCTAssertEqual(store.syncCount(), 1)
            
            do {
                if useMockData {
                    mockResponse(json: ["count" : 3])
                }
                defer {
                    if useMockData {
                        setURLProtocol(nil)
                    }
                }
                
                weak var expectationPush = expectation(description: "Push")
                
                store.push() { (count, error) -> Void in
                    XCTAssertTrue(Thread.isMainThread)
                    XCTAssertNotNil(count)
                    XCTAssertNil(error)
                    
                    XCTAssertEqual(count, 3)
                    
                    expectationPush?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationPush = nil
                }
            }
            
            XCTAssertEqual(store.syncCount(), 0)
        }
        
        do {
            if useMockData {
                mockResponse(json: mockResponses.sorted(by: { (obj1, obj2) -> Bool in
                    let name1 = obj1["name"] as! String
                    let name2 = obj2["name"] as! String
                    return name1 < name2
                }))
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            let query = Query(predicate: NSPredicate(format: "acl.creator == %@", client.activeUser!.userId), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(query, options: try! Options(readPolicy: .forceNetwork)) {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons[0].name, "Person 1 (Renamed)")
                    XCTAssertEqual(persons[0].name, personsArray[0].name)
                    XCTAssertNotEqual(persons[0].personId, personsArray[0].personId)
                    
                    XCTAssertEqual(persons[1].name, "Person 2")
                    XCTAssertEqual(persons[1].name, personsArray[1].name)
                    XCTAssertNotEqual(persons[1].personId, personsArray[1].personId)
                    
                    XCTAssertEqual(persons[2].name, "Person 3")
                    XCTAssertEqual(persons[2].name, personsArray[2].name)
                    XCTAssertNotEqual(persons[2].personId, personsArray[2].personId)
                    
                    personsArray.removeAll()
                    personsArray.append(contentsOf: persons)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
    }
    
    func testQueryWithPropertyNotMapped() {
        let query = Query(format: "propertyNotMapped == %@", 10)
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(query) {
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
    
    func testRealmCacheNotEntity() {
        // swiftlint:disable nesting
        class NotEntityPersistable: NSObject, Persistable {
            
            static func collectionName() -> String {
                return "NotEntityPersistable"
            }
            
            static func translate(property: String) -> String? {
                return nil
            }
            
            required override init() {
            }
            
            required init?(map: Map) {
            }
            
            func mapping(map: Map) {
            }
            
            static func decode<T>(from data: Data) throws -> T where T : JSONDecodable {
                return NotEntityPersistable() as! T
            }
            
            static func decodeArray<T>(from data: Data) throws -> [T] where T : JSONDecodable {
                return [NotEntityPersistable]() as! [T]
            }
            
            static func decode<T>(from dictionary: [String : Any]) throws -> T where T : JSONDecodable {
                return NotEntityPersistable() as! T
            }
            
            func refresh(from dictionary: [String : Any]) throws {
                var _self = self
                try _self.refreshJSONDecodable(from: dictionary)
            }
            
            func encode() throws -> [String : Any] {
                return [:]
            }
            
        }
        // swiftlint:enable nesting
        
        expect {
            try RealmCache<NotEntityPersistable>(persistenceId: UUID().uuidString, schemaVersion: 0)
        }.to(throwError())
    }
    
    func testRealmSyncNotEntity() {
        // swiftlint:disable nesting
        class NotEntityPersistable: NSObject, Persistable {
            
            static func collectionName() -> String {
                return "NotEntityPersistable"
            }
            
            static func translate(property: String) -> String? {
                return nil
            }
            
            required override init() {
            }
            
            required init?(map: Map) {
            }
            
            func mapping(map: Map) {
            }
            
            static func decode<T>(from data: Data) throws -> T where T : JSONDecodable {
                return NotEntityPersistable() as! T
            }
            
            static func decodeArray<T>(from data: Data) throws -> [T] where T : JSONDecodable {
                 return [NotEntityPersistable]() as! [T]
            }
            
            static func decode<T>(from dictionary: [String : Any]) throws -> T where T : JSONDecodable {
                return NotEntityPersistable() as! T
            }
            
            func refresh(from dictionary: [String : Any]) throws {
            }
            
            func encode() throws -> [String : Any] {
                return [:]
            }
            
        }
        // swiftlint:enable nesting
        
        expect {
            try RealmSync<NotEntityPersistable>(persistenceId: UUID().uuidString, schemaVersion: 0)
        }.to(throwError())
    }
    
    func testCancelLocalRequest() {
        let query = Query(format: "propertyNotMapped == %@", 10)
        
        weak var expectationFind = expectation(description: "Find")
        
        let request = store.find(query) {
            switch $0 {
            case .success(let persons):
                XCTAssertEqual(persons.count, 0)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationFind?.fulfill()
            expectationFind = nil
        }
        request.cancel()
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testNewTypeDataStore() {
        var store = try! DataStore<Person>.collection()
        store = try! store.collection(newType: Book.self).collection(newType: Person.self)
    }
    
    func testGroupCustomAggregationError() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.sync)
        
        if useMockData {
            mockResponse(json: [
                ["sum" : 926]
                ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationGroup = expectation(description: "Group")
        
        store.group(
            initialObject: ["sum" : 0],
            reduceJSFunction: "function(doc,out) { out.sum += doc.age; }",
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18)),
            options: nil
        ) {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertNotNil(error as? Kinvey.Error)
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .invalidOperation(let description):
                        XCTAssertEqual(description, "Custom Aggregation not supported against local cache")
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            
            expectationGroup?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationGroup = nil
        }
    }
    
    func testGroupCustomAggregationErrorSync() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.sync)
        
        if useMockData {
            mockResponse(json: [
                ["sum" : 926]
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        let request = store.group(
            initialObject: ["sum" : 0],
            reduceJSFunction: "function(doc,out) { out.sum += doc.age; }",
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18)),
            options: nil
        )
        XCTAssertTrue(request.wait(timeout: defaultTimeout))
        guard let result = request.result else {
            return
        }
        switch result {
        case .success:
            XCTFail("A failure result is expected")
        case .failure(let error):
            XCTAssertNotNil(error as? Kinvey.Error)
            if let error = error as? Kinvey.Error {
                switch error {
                case .invalidOperation(let description):
                    XCTAssertEqual(description, "Custom Aggregation not supported against local cache")
                default:
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }
    
    func testGroupCustomAggregationErrorTryCatchSync() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.sync)
        
        if useMockData {
            mockResponse(json: [
                ["sum" : 926]
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        let request = store.group(
            initialObject: ["sum" : 0],
            reduceJSFunction: "function(doc,out) { out.sum += doc.age; }",
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18)),
            options: nil
        )
        do {
            let _ = try request.waitForResult(timeout: defaultTimeout).value()
            XCTFail("Error is expected")
        } catch {
            XCTAssertNotNil(error as? Kinvey.Error)
            if let error = error as? Kinvey.Error {
                switch error {
                case .invalidOperation(let description):
                    XCTAssertEqual(description, "Custom Aggregation not supported against local cache")
                default:
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }
    
    func testObjectMappingMemoryLeak() {
        var store = try! DataStore<Person>.collection(.network)
        
        mockResponse(json: [
            [
                "_id" : UUID().uuidString,
                "name" : UUID().uuidString,
                "_acl" : [
                    "creator" : UUID().uuidString
                ],
                "_kmd" : [
                    "lmt" : Date().toISO8601(),
                    "ect" : Date().toISO8601()
                ]
            ]
        ])
        defer {
            setURLProtocol(nil)
        }
        
        let memoryBefore = getMegabytesUsed()
        
        for _ in 1...10_000 {
            autoreleasepool {
                weak var expectationFind = expectation(description: "Find")
                
                store.find(options: nil) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                    switch result {
                    case .success(let persons):
                        XCTAssertEqual(persons.count, 1)
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationFind?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationFind = nil
                }
            }
        }
        
        let memoryAfter = getMegabytesUsed()
        
        XCTAssertLessThan(memoryAfter! - memoryBefore!, 10)
    }
    
    func testServerSideDeltaSetSyncAdd1Record() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        var initialCount = 0
        do {
            if !useMockData {
                initialCount = try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value()
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(Int(persons.count), initialCount + 1)
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [
                                    [
                                        "_id": "NEW-58450d87f29e22207c83a236",
                                        "name": "Victor Hugo",
                                        "_acl": [
                                            "creator": "58450d87c077970e38a388ba"
                                        ],
                                        "_kmd": [
                                            "lmt": Date().toISO8601(),
                                            "ect": "2016-12-05T06:47:35.711Z"
                                        ]
                                    ]
                                ],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Hugo"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(Int(persons.count), initialCount + 2)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    if let person = persons.last {
                        XCTAssertEqual(person.name, "Victor Hugo")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
    }
    
    func testServerSideDeltaSetSyncUpdate1Record() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        do {
            mockResponse { (request) -> HttpResponse in
                guard let url = request.url else {
                    XCTAssertNotNil(request.url)
                    return HttpResponse(statusCode: 404, data: Data())
                }
                switch url.path {
                case "/appdata/_kid_/Person":
                    return HttpResponse(
                        headerFields: [
                            "X-Kinvey-Request-Start" : Date().toISO8601()
                        ],
                        json: [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                    )
                default:
                    XCTFail(url.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, 1)
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        do {
            mockResponse { (request) -> HttpResponse in
                guard let url = request.url else {
                    XCTAssertNotNil(request.url)
                    return HttpResponse(statusCode: 404, data: Data())
                }
                switch url.path {
                case "/appdata/_kid_/Person/_deltaset":
                    return HttpResponse(
                        headerFields: [
                            "X-Kinvey-Request-Start" : Date().toISO8601()
                        ],
                        json: [
                            "changed" : [
                                [
                                    "_id": "58450d87f29e22207c83a236",
                                    "name": "Victor Hugo",
                                    "_acl": [
                                        "creator": "58450d87c077970e38a388ba"
                                    ],
                                    "_kmd": [
                                        "lmt": Date().toISO8601(),
                                        "ect": "2016-12-05T06:47:35.711Z"
                                    ]
                                ]
                            ],
                            "deleted" : []
                        ]
                    )
                default:
                    XCTFail(url.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, 1)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Hugo")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
    }
    
    func testServerSideDeltaSetSyncDelete1Record() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        do {
            mockResponse { (request) -> HttpResponse in
                guard let url = request.url else {
                    XCTAssertNotNil(request.url)
                    return HttpResponse(statusCode: 404, data: Data())
                }
                switch url.path {
                case "/appdata/_kid_/Person":
                    return HttpResponse(
                        headerFields: [
                            "X-Kinvey-Request-Start" : Date().toISO8601()
                        ],
                        json: [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                    )
                default:
                    XCTFail(url.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, 1)
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        do {
            mockResponse { (request) -> HttpResponse in
                guard let url = request.url else {
                    XCTAssertNotNil(request.url)
                    return HttpResponse(statusCode: 404, data: Data())
                }
                switch url.path {
                case "/appdata/_kid_/Person/_deltaset":
                    return HttpResponse(
                        headerFields: [
                            "X-Kinvey-Request-Start" : Date().toISO8601()
                        ],
                        json: [
                            "changed" : [],
                            "deleted" : [
                                ["_id": "58450d87f29e22207c83a236"]
                            ]
                        ]
                    )
                default:
                    XCTFail(url.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, 0)
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
    }
    
    func testServerSideDeltaSetSyncAddUpdateDelete2Records() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        do {
            mockResponse { (request) -> HttpResponse in
                guard let url = request.url else {
                    XCTAssertNotNil(request.url)
                    return HttpResponse(statusCode: 404, data: Data())
                }
                switch url.path {
                case "/appdata/_kid_/Person":
                    return HttpResponse(
                        headerFields: [
                            "X-Kinvey-Request-Start" : Date().toISO8601()
                        ],
                        json: [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ],
                            [
                                "_id": "ToBeDeleted-58450d87f29e22207c83a236",
                                "name": "Victor Barros 2",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ],
                            [
                                "_id": "ToBeDeleted-58450d87f29e22207c83a237",
                                "name": "Victor Barros 3",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                    )
                default:
                    XCTFail(url.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, 3)
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        do {
            mockResponse { (request) -> HttpResponse in
                guard let url = request.url else {
                    XCTAssertNotNil(request.url)
                    return HttpResponse(statusCode: 404, data: Data())
                }
                switch url.path {
                case "/appdata/_kid_/Person/_deltaset":
                    return HttpResponse(
                        headerFields: [
                            "X-Kinvey-Request-Start" : Date().toISO8601()
                        ],
                        json: [
                            "changed" : [
                                [
                                    "_id": "58450d87f29e22207c83a236",
                                    "name": "Victor Hugo",
                                    "_acl": [
                                        "creator": "58450d87c077970e38a388ba"
                                    ],
                                    "_kmd": [
                                        "lmt": "2016-12-05T06:47:35.711Z",
                                        "ect": "2016-12-05T06:47:35.711Z"
                                    ]
                                ],
                                [
                                    "_id": "NEW-58450d87f29e22207c83a236",
                                    "name": "Victor C Barros",
                                    "_acl": [
                                        "creator": "58450d87c077970e38a388ba"
                                    ],
                                    "_kmd": [
                                        "lmt": "2016-12-05T06:47:35.711Z",
                                        "ect": "2016-12-05T06:47:35.711Z"
                                    ]
                                ],
                                [
                                    "_id": "NEW-58450d87f29e22207c83a237",
                                    "name": "Victor C B",
                                    "_acl": [
                                        "creator": "58450d87c077970e38a388ba"
                                    ],
                                    "_kmd": [
                                        "lmt": "2016-12-05T06:47:35.711Z",
                                        "ect": "2016-12-05T06:47:35.711Z"
                                    ]
                                ]
                            ],
                            "deleted" : [
                                ["_id": "ToBeDeleted-58450d87f29e22207c83a236"],
                                ["_id": "ToBeDeleted-58450d87f29e22207c83a237"]
                            ]
                        ]
                    )
                default:
                    XCTFail(url.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(
                deltaSetCompletionHandler: {
                    XCTAssertEqual($0.count, 3)
                    XCTAssertEqual($1.count, 2)
                },
                options: nil
            ) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, 3)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Hugo")
                    }
                    if persons.count > 1 {
                        XCTAssertEqual(persons[1].name, "Victor C Barros")
                    }
                    if let person = persons.last {
                        XCTAssertEqual(person.name, "Victor C B")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
    }
    
    func testServerSideDeltaSetSyncClearCacheNoQuery() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        let realm = (store.cache!.cache as! RealmCache<Person>).newRealm
        
        do {
            mockResponse { (request) -> HttpResponse in
                guard let url = request.url else {
                    XCTAssertNotNil(request.url)
                    return HttpResponse(statusCode: 404, data: Data())
                }
                switch url.path {
                case "/appdata/_kid_/Person":
                    return HttpResponse(
                        headerFields: [
                            "X-Kinvey-Request-Start" : Date().toISO8601()
                        ],
                        json: [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                    )
                default:
                    XCTFail(url.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, 1)
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        XCTAssertEqual(realm.objects(Metadata.self).count, 1)
        
        do {
            mockResponse { (request) -> HttpResponse in
                guard let url = request.url else {
                    XCTAssertNotNil(request.url)
                    return HttpResponse(statusCode: 404, data: Data())
                }
                switch url.path {
                case "/appdata/_kid_/Person/_deltaset":
                    return HttpResponse(
                        headerFields: [
                            "X-Kinvey-Request-Start" : Date().toISO8601()
                        ],
                        json: [
                            "changed" : [
                                [
                                    "_id": "58450d87f29e22207c83a236",
                                    "name": "Victor Hugo",
                                    "_acl": [
                                        "creator": "58450d87c077970e38a388ba"
                                    ],
                                    "_kmd": [
                                        "lmt": "2016-12-05T06:47:35.711Z",
                                        "ect": "2016-12-05T06:47:35.711Z"
                                    ]
                                ],
                                [
                                    "_id": "NEW-58450d87f29e22207c83a236",
                                    "name": "Victor C Barros",
                                    "_acl": [
                                        "creator": "58450d87c077970e38a388ba"
                                    ],
                                    "_kmd": [
                                        "lmt": "2016-12-05T06:47:35.711Z",
                                        "ect": "2016-12-05T06:47:35.711Z"
                                    ]
                                ]
                            ],
                            "deleted" : [
                                ["_id": "ToBeDeleted-58450d87f29e22207c83a236"]
                            ]
                        ]
                    )
                default:
                    XCTFail(url.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, 2)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Hugo")
                    }
                    if let person = persons.last {
                        XCTAssertEqual(person.name, "Victor C Barros")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        XCTAssertEqual(realm.objects(Metadata.self).count, 2)
        
        store.clearCache()
        
        XCTAssertEqual(realm.objects(Metadata.self).count, 0)
        
        do {
            mockResponse { (request) -> HttpResponse in
                guard let url = request.url else {
                    XCTAssertNotNil(request.url)
                    return HttpResponse(statusCode: 404, data: Data())
                }
                switch url.path {
                case "/appdata/_kid_/Person":
                    return HttpResponse(json: [
                        [
                            "_id": "58450d87f29e22207c83a236",
                            "name": "Victor Hugo",
                            "_acl": [
                                "creator": "58450d87c077970e38a388ba"
                            ],
                            "_kmd": [
                                "lmt": "2016-12-05T06:47:35.711Z",
                                "ect": "2016-12-05T06:47:35.711Z"
                            ]
                        ],
                        [
                            "_id": "NEW-58450d87f29e22207c83a236",
                            "name": "Victor C Barros",
                            "_acl": [
                                "creator": "58450d87c077970e38a388ba"
                            ],
                            "_kmd": [
                                "lmt": "2016-12-05T06:47:35.711Z",
                                "ect": "2016-12-05T06:47:35.711Z"
                            ]
                        ]
                    ])
                default:
                    XCTFail(url.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, 2)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Hugo")
                    }
                    if let person = persons.last {
                        XCTAssertEqual(person.name, "Victor C Barros")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        XCTAssertEqual(realm.objects(Metadata.self).count, 2)
    }
    
    func testServerSideDeltaSetSyncClearCache() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        let realm = (store.cache!.cache as! RealmCache<Person>).newRealm
        
        do {
            mockResponse { (request) -> HttpResponse in
                guard let url = request.url else {
                    XCTAssertNotNil(request.url)
                    return HttpResponse(statusCode: 404, data: Data())
                }
                switch url.path {
                case "/appdata/_kid_/Person":
                    return HttpResponse(
                        headerFields: [
                            "X-Kinvey-Request-Start" : Date().toISO8601()
                        ],
                        json: [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                    )
                default:
                    XCTFail(url.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, 1)
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        realm.refresh()
        XCTAssertEqual(realm.objects(Metadata.self).count, 1)
        
        do {
            mockResponse { (request) -> HttpResponse in
                guard let url = request.url else {
                    XCTAssertNotNil(request.url)
                    return HttpResponse(statusCode: 404, data: Data())
                }
                switch url.path {
                case "/appdata/_kid_/Person/_deltaset":
                    return HttpResponse(
                        headerFields: [
                            "X-Kinvey-Request-Start" : Date().toISO8601()
                        ],
                        json: [
                            "changed" : [
                                [
                                    "_id": "58450d87f29e22207c83a236",
                                    "name": "Victor Hugo",
                                    "_acl": [
                                        "creator": "58450d87c077970e38a388ba"
                                    ],
                                    "_kmd": [
                                        "lmt": "2016-12-05T06:47:35.711Z",
                                        "ect": "2016-12-05T06:47:35.711Z"
                                    ]
                                ],
                                [
                                    "_id": "NEW-58450d87f29e22207c83a236",
                                    "name": "Victor C Barros",
                                    "_acl": [
                                        "creator": "58450d87c077970e38a388ba"
                                    ],
                                    "_kmd": [
                                        "lmt": "2016-12-05T06:47:35.711Z",
                                        "ect": "2016-12-05T06:47:35.711Z"
                                    ]
                                ]
                            ],
                            "deleted" : [
                                ["_id": "ToBeDeleted-58450d87f29e22207c83a236"]
                            ]
                        ]
                    )
                default:
                    XCTFail(url.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, 2)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Hugo")
                    }
                    if let person = persons.last {
                        XCTAssertEqual(person.name, "Victor C Barros")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        XCTAssertEqual(realm.objects(Metadata.self).count, 2)
        
        let query = Query(format: "name == %@", "Victor")
        store.clearCache(query: query)
        
        do {
            mockResponse { (request) -> HttpResponse in
                guard let url = request.url else {
                    XCTAssertNotNil(request.url)
                    return HttpResponse(statusCode: 404, data: Data())
                }
                switch url.path {
                case "/appdata/_kid_/Person":
                    return HttpResponse(json: [
                        [
                            "_id": "58450d87f29e22207c83a236",
                            "name": "Victor Hugo",
                            "_acl": [
                                "creator": "58450d87c077970e38a388ba"
                            ],
                            "_kmd": [
                                "lmt": "2016-12-05T06:47:35.711Z",
                                "ect": "2016-12-05T06:47:35.711Z"
                            ]
                        ],
                        [
                            "_id": "NEW-58450d87f29e22207c83a236",
                            "name": "Victor C Barros",
                            "_acl": [
                                "creator": "58450d87c077970e38a388ba"
                            ],
                            "_kmd": [
                                "lmt": "2016-12-05T06:47:35.711Z",
                                "ect": "2016-12-05T06:47:35.711Z"
                            ]
                        ]
                    ])
                default:
                    XCTFail(url.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, 2)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Hugo")
                    }
                    if let person = persons.last {
                        XCTAssertEqual(person.name, "Victor C Barros")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        XCTAssertEqual(realm.objects(Metadata.self).count, 2)
    }
    
    func testServerSideDeltaSetSyncResultSetExceed() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        do {
            mockResponse { (request) -> HttpResponse in
                guard let url = request.url else {
                    XCTAssertNotNil(request.url)
                    return HttpResponse(statusCode: 404, data: Data())
                }
                switch url.path {
                case "/appdata/_kid_/Person":
                    return HttpResponse(
                        headerFields: [
                            "X-Kinvey-Request-Start" : Date().toISO8601()
                        ],
                        json: [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                    )
                default:
                    XCTFail(url.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, 1)
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        do {
            mockResponse(
                statusCode: 400,
                json: [
                    "error" : "ResultSetSizeExceeded",
                    "description" : "Your query produced more than 10,000 results. Please rewrite your query to be more selective.",
                    "debug" : "Your query returned 320193 results"
                ]
            )
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success:
                    XCTFail("A failure result is expected")
                case .failure(let errors):
                    XCTAssertEqual(errors.count, 1)
                    if let error = errors.first {
                        XCTAssertTrue(error is Kinvey.Error)
                        if let error = error as? Kinvey.Error {
                            switch error {
                            case .resultSetSizeExceeded(let debug, let description):
                                XCTAssertEqual(description, "Your query produced more than 10,000 results. Please rewrite your query to be more selective.")
                                XCTAssertTrue(debug.hasPrefix("Your query returned "))
                                XCTAssertTrue(debug.hasSuffix(" results"))
                            default:
                                XCTFail(error.debugDescription)
                            }
                        } else {
                            XCTFail(error.localizedDescription)
                        }
                    }
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
    }
    
    func testServerSideDeltaSetSyncMissingConfiguration() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        mockResponse { (request) -> HttpResponse in
            guard let url = request.url else {
                XCTAssertNotNil(request.url)
                return HttpResponse(statusCode: 404, data: Data())
            }
            switch url.path {
            case "/appdata/_kid_/Person":
                return HttpResponse(
                    headerFields: [
                        "X-Kinvey-Request-Start" : Date().toISO8601()
                    ],
                    json: [
                        [
                            "_id": "58450d87f29e22207c83a236",
                            "name": "Victor Barros",
                            "_acl": [
                                "creator": "58450d87c077970e38a388ba"
                            ],
                            "_kmd": [
                                "lmt": "2016-12-05T06:47:35.711Z",
                                "ect": "2016-12-05T06:47:35.711Z"
                            ]
                        ]
                    ]
                )
            case "/appdata/_kid_/Person/_deltaset":
                return HttpResponse(
                    statusCode: 403,
                    json: [
                        "error" : "MissingConfiguration",
                        "description" : "This feature is not properly configured for this app backend. Please configure it through the console first, or contact support for more information.",
                        "debug" : "This collection has not been configured for Delta Set access."
                    ]
                )
            default:
                XCTFail(url.path)
                return HttpResponse(statusCode: 404, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        do {
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, 1)
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        do {
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, 1)
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
    }
    
    func testServerSideDeltaSetSyncParameterValueOutOfRange() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        do {
            mockResponse { (request) -> HttpResponse in
                guard let url = request.url else {
                    XCTAssertNotNil(request.url)
                    return HttpResponse(statusCode: 404, data: Data())
                }
                switch url.path {
                case "/appdata/_kid_/Person":
                    return HttpResponse(
                        headerFields: [
                            "X-Kinvey-Request-Start" : Date().toISO8601()
                        ],
                        json: [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                    )
                default:
                    XCTFail(url.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, 1)
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        do {
            var count = 0
            mockResponse { response in
                defer {
                    count += 1
                }
                switch (count, response.url?.path) {
                case (0, "/appdata/_kid_/Person/_deltaset"?):
                    return HttpResponse(
                        statusCode: 400,
                        json: [
                            "error" : "ParameterValueOutOfRange",
                            "description" : "The value specified for one of the request parameters is out of range",
                            "debug" : "The 'since' timestamp cannot be earlier than the date at which delta set was enabled for this collection."
                        ]
                    )
                case (1, "/appdata/_kid_/Person"?):
                    return HttpResponse(
                        headerFields: [
                            "X-Kinvey-Request-Start" : Date().toISO8601()
                        ],
                        json: [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                    )
                default:
                    XCTFail(response.url?.path ?? "response.url?.path is nil")
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, 1)
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
    }
    
    func testSyncStoreDisabledDeltasetWithPull() {
        let store = try! DataStore<Person>.collection(.sync)
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertEqual(cacheCount, results.count)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ],
                            [
                                "_id": "58450d87f29e22207c83a237",
                                "name": "Victor Hugo",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Hugo"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 2)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    if let secondPerson = results.last {
                        XCTAssertEqual(secondPerson.name, "Victor Hugo")
                    }
                    
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertEqual(cacheCount, results.count)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
    }
    //Create 1 person, Make regular GET, Create 1 more person, Make deltaset request
    func testSyncStoreDeltaset1ExtraItemAddedWithPull() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertEqual(cacheCount, results.count)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [
                                    [
                                        "_id": "58450d87f29e22207c83a237",
                                        "name": "Victor Hugo",
                                        "_acl": [
                                            "creator": "58450d87c077970e38a388ba"
                                        ],
                                        "_kmd": [
                                            "lmt": "2016-12-05T06:47:35.711Z",
                                            "ect": "2016-12-05T06:47:35.711Z"
                                        ]
                                    ]
                                ],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Hugo"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 2)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    if let secondPerson = results.last {
                        XCTAssertEqual(secondPerson.name, "Victor Hugo")
                    }
                    
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertEqual(cacheCount, results.count)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
    }
    
    func testSyncStoreDeltasetSinceIsRespectedWithoutChangesWithPull() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertEqual(cacheCount, results.count)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            }
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertEqual(cacheCount, results.count)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
    }
    //Create 2 persons, pull with regular GET, update 1, deltaset returning 1 changed, delete 1, deltaset returning 1 deleted
    func testSyncStoreDeltaset1ItemAdded1Updated1DeletedWithPull() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        var idToUpdate = ""
        var idToDelete = ""
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ],
                            [
                                "_id": "58450d87f29e22207c83a237",
                                "name": "Victor Hugo",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
                var secondPerson = Person()
                secondPerson.name = "Victor Hugo"
                secondPerson = try! DataStore<Person>.collection(.network).save(secondPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
                idToUpdate = person.personId!
                idToDelete = secondPerson.personId!
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 2)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    if let secondPerson = results.last {
                        XCTAssertEqual(secondPerson.name, "Victor Hugo")
                    }
                    
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertEqual(cacheCount, results.count)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [
                                    [
                                        "_id": "58450d87f29e22207c83a236",
                                        "name": "Victor C Barros",
                                        "_acl": [
                                            "creator": "58450d87c077970e38a388ba"
                                        ],
                                        "_kmd": [
                                            "lmt": "2016-12-05T06:47:35.711Z",
                                            "ect": "2016-12-05T06:47:35.711Z"
                                        ]
                                    ]
                                ],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var updatedPerson = Person()
                updatedPerson.name = "Victor C Barros"
                updatedPerson.personId = idToUpdate
                updatedPerson = try! DataStore<Person>.collection(.network).save(updatedPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 2)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor C Barros")
                    }
                    if let secondPerson = results.last {
                        XCTAssertEqual(secondPerson.name, "Victor Hugo")
                    }
                    
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertEqual(cacheCount, results.count)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [],
                                "deleted" : [["_id":"58450d87f29e22207c83a237"]]
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                try! DataStore<Person>.collection(.network).remove(byId: idToDelete).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor C Barros")
                    }
                    
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertEqual(cacheCount, results.count)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
    }
    //Created 3 items, 2 of which satisfy a query, pull with query with regular GET, delete 1 item that satisfies the query, deltaset returns 1 deleted item
    func testSyncStoreDeltaset1WithQuery1ItemDeletedWithPull() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        var idToDelete = ""
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "age":23,
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ],
                            [
                                "_id": "58450d87f29e22207c83a238",
                                "name": "Victor Emmanuel",
                                "age":23,
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person.age = 23
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
                var secondPerson = Person()
                secondPerson.name = "Victor Hugo"
                secondPerson.age = 24
                secondPerson = try! DataStore<Person>.collection(.network).save(secondPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
                var thirdPerson = Person()
                thirdPerson.name = "Victor Emmanuel"
                thirdPerson.age = 23
                thirdPerson = try! DataStore<Person>.collection(.network).save(thirdPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
                idToDelete = thirdPerson.personId!
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPull = expectation(description: "Pull")
            var query = Query(format: "age == %@", 23)
            store.pull(Query(format: "age == %@", 23)) { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 2)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    
                    if let thirdPerson = results.last {
                        XCTAssertEqual(thirdPerson.name, "Victor Emmanuel")
                    }
                    
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertEqual(cacheCount, results.count)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [],
                                "deleted" : [["_id": "58450d87f29e22207c83a238"]]
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                try! DataStore<Person>.collection(.network).remove(byId:idToDelete).waitForResult(timeout: defaultTimeout)
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            weak var expectationPull = expectation(description: "Pull")
            var query = Query(format: "age == %@", 23)
            store.pull(query) { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertEqual(cacheCount, results.count)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
    }
    
    //Created 3 items, 2 of which satisfy a query, pull with query with regular GET, update 1 item that satisfies the query, deltaset returns 1 changed item
    func testSyncStoreDeltasetWithQuery1ItemUpdatedWithPull() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        var idToUpdate = ""
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "age":23,
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ],
                            [
                                "_id": "58450d87f29e22207c83a238",
                                "name": "Victor Emmanuel",
                                "age":23,
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person.age = 23
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
                idToUpdate = person.personId!
                var secondPerson = Person()
                secondPerson.name = "Victor Hugo"
                secondPerson.age = 24
                secondPerson = try! DataStore<Person>.collection(.network).save(secondPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
                var thirdPerson = Person()
                thirdPerson.name = "Victor Emmanuel"
                thirdPerson.age = 23
                thirdPerson = try! DataStore<Person>.collection(.network).save(thirdPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPull = expectation(description: "Pull")
            var query = Query(format: "age == %@", 23)
            store.pull(query) { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 2)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    
                    if let thirdPerson = results.last {
                        XCTAssertEqual(thirdPerson.name, "Victor Emmanuel")
                    }
                    
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertEqual(cacheCount, results.count)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [
                                    [
                                        "_id": "58450d87f29e22207c83a236",
                                        "name": "Victor C Barros",
                                        "age":23,
                                        "_acl": [
                                            "creator": "58450d87c077970e38a388ba"
                                        ],
                                        "_kmd": [
                                            "lmt": "2016-12-05T06:47:35.711Z",
                                            "ect": "2016-12-05T06:47:35.711Z"
                                        ]
                                    ]
                                ],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var updatedPerson = Person()
                updatedPerson.name = "Victor C Barros"
                updatedPerson.personId = idToUpdate
                updatedPerson.age = 23
                updatedPerson = try! DataStore<Person>.collection(.network).save(updatedPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            weak var expectationPull = expectation(description: "Pull")
            var query = Query(format: "age == %@", 23)
            store.pull(query) { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 2)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor C Barros")
                    }
                    if let secondPerson = results.last {
                        XCTAssertEqual(secondPerson.name, "Victor Emmanuel")
                    }
                    
                    let cacheCount = self.store.cache?.count(query: nil)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
    }
    //Create 1 item, pull with regular GET, create another item, deltaset returns 1 changed, switch off deltaset, pull with regular GET
    func testSyncStoreDeltasetTurnedOffSendsRegularGETWithPull() {
        var store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertEqual(cacheCount, results.count)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [
                                    [
                                        "_id": "58450d87f29e22207c83a237",
                                        "name": "Victor Hugo",
                                        "_acl": [
                                            "creator": "58450d87c077970e38a388ba"
                                        ],
                                        "_kmd": [
                                            "lmt": "2016-12-05T06:47:35.711Z",
                                            "ect": "2016-12-05T06:47:35.711Z"
                                        ]
                                    ]
                                ],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Hugo"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 2)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    
                    if let secondPerson = results.last {
                        XCTAssertEqual(secondPerson.name, "Victor Hugo")
                    }
                    
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertEqual(cacheCount, results.count)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: false))
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                [
                                    "_id": "58450d87f29e22207c83a236",
                                    "name": "Victor Barros",
                                    "_acl": [
                                        "creator": "58450d87c077970e38a388ba"
                                    ],
                                    "_kmd": [
                                        "lmt": "2016-12-05T06:47:35.711Z",
                                        "ect": "2016-12-05T06:47:35.711Z"
                                    ]
                                ],
                                [
                                    "_id": "58450d87f29e22207c83a237",
                                    "name": "Victor Hugo",
                                    "_acl": [
                                        "creator": "58450d87c077970e38a388ba"
                                    ],
                                    "_kmd": [
                                        "lmt": "2016-12-05T06:47:35.711Z",
                                        "ect": "2016-12-05T06:47:35.711Z"
                                    ]
                                ]
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            }
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 2)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    if let secondPerson = results.last {
                        XCTAssertEqual(secondPerson.name, "Victor Hugo")
                    }
                    
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertEqual(cacheCount, results.count)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
    }

    func testSyncStoreDisabledDeltasetWithSync() {
        let store = try! DataStore<Person>.collection(.sync)
        
        var initialCount = 0
        do {
            if !useMockData {
                initialCount = try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value()
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, initialCount + 2)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ],
                            [
                                "_id": "58450d87f29e22207c83a237",
                                "name": "Victor Hugo",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Hugo"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(persons.count, initialCount + 2)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    if let secondPerson = persons.last {
                        XCTAssertEqual(secondPerson.name, "Victor Hugo")
                    }
                    
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
    }

    func testSyncStoreDeltaset1ExtraItemAddedWithSync() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(Int64(persons.count), initialCount + 1)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [
                                    [
                                        "_id": "58450d87f29e22207c83a237",
                                        "name": "Victor Hugo",
                                        "_acl": [
                                            "creator": "58450d87c077970e38a388ba"
                                        ],
                                        "_kmd": [
                                            "lmt": "2016-12-05T06:47:35.711Z",
                                            "ect": "2016-12-05T06:47:35.711Z"
                                        ]
                                    ]
                                ],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Hugo"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            weak var expectationSync = expectation(description: "Pull")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(Int64(persons.count), initialCount + 2)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    if let secondPerson = persons.last {
                        XCTAssertEqual(secondPerson.name, "Victor Hugo")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
    }

    func testSyncStoreDeltasetSinceIsRespectedWithoutChangesWithSync() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(Int64(persons.count), initialCount + 1)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            }
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(Int64(persons.count), initialCount + 1)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
    }

    func testSyncStoreDeltaset1ItemAdded1Updated1DeletedWithSync() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        var idToUpdate = ""
        var idToDelete = ""
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ],
                            [
                                "_id": "58450d87f29e22207c83a237",
                                "name": "Victor Hugo",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
                var secondPerson = Person()
                secondPerson.name = "Victor Hugo"
                secondPerson = try! DataStore<Person>.collection(.network).save(secondPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
                idToUpdate = person.personId!
                idToDelete = secondPerson.personId!
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(Int64(persons.count), initialCount + 2)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    if let secondPerson = persons.last {
                        XCTAssertEqual(secondPerson.name, "Victor Hugo")
                    }
                    
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [
                                    [
                                        "_id": "58450d87f29e22207c83a236",
                                        "name": "Victor C Barros",
                                        "_acl": [
                                            "creator": "58450d87c077970e38a388ba"
                                        ],
                                        "_kmd": [
                                            "lmt": "2016-12-05T06:47:35.711Z",
                                            "ect": "2016-12-05T06:47:35.711Z"
                                        ]
                                    ]
                                ],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var updatedPerson = Person()
                updatedPerson.name = "Victor C Barros"
                updatedPerson.personId = idToUpdate
                updatedPerson = try! DataStore<Person>.collection(.network).save(updatedPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(Int64(persons.count), initialCount + 2)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor C Barros")
                    }
                    if let secondPerson = persons.last {
                        XCTAssertEqual(secondPerson.name, "Victor Hugo")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [],
                                "deleted" : [["_id":"58450d87f29e22207c83a237"]]
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                try! DataStore<Person>.collection(.network).remove(byId: idToDelete).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            weak var expectationSync = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(Int64(persons.count), initialCount + 1)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor C Barros")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
    }
    
    func testSyncStoreDeltaset1WithQuery1ItemDeletedWithSync() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        var idToDelete = ""
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "age":23,
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ],
                            [
                                "_id": "58450d87f29e22207c83a238",
                                "name": "Victor Emmanuel",
                                "age":23,
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person.age = 23
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
                var secondPerson = Person()
                secondPerson.name = "Victor Hugo"
                secondPerson.age = 24
                secondPerson = try! DataStore<Person>.collection(.network).save(secondPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
                var thirdPerson = Person()
                thirdPerson.name = "Victor Emmanuel"
                thirdPerson.age = 23
                thirdPerson = try! DataStore<Person>.collection(.network).save(thirdPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
                idToDelete = thirdPerson.personId!
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSync = expectation(description: "Sync")
            var query = Query(format: "age == %@", 23)
            store.sync(query, options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(Int64(persons.count), initialCount + 2)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    
                    if let thirdPerson = persons.last {
                        XCTAssertEqual(thirdPerson.name, "Victor Emmanuel")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [],
                                "deleted" : [["_id": "58450d87f29e22207c83a238"]]
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                try! DataStore<Person>.collection(.network).remove(byId:idToDelete).waitForResult(timeout: defaultTimeout)
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            weak var expectationSync = expectation(description: "Sync")
            var query = Query(format: "age == %@", 23)
            store.sync(query, options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(Int64(persons.count), initialCount + 1)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
    }

    func testSyncStoreDeltasetWithQuery1ItemUpdatedWithSync() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        var idToUpdate = ""
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "age":23,
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ],
                            [
                                "_id": "58450d87f29e22207c83a238",
                                "name": "Victor Emmanuel",
                                "age":23,
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person.age = 23
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
                idToUpdate = person.personId!
                var secondPerson = Person()
                secondPerson.name = "Victor Hugo"
                secondPerson.age = 24
                secondPerson = try! DataStore<Person>.collection(.network).save(secondPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
                var thirdPerson = Person()
                thirdPerson.name = "Victor Emmanuel"
                thirdPerson.age = 23
                thirdPerson = try! DataStore<Person>.collection(.network).save(thirdPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSync = expectation(description: "Sync")
            var query = Query(format: "age == %@", 23)
            store.sync(query, options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(Int64(persons.count), initialCount + 2)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    
                    if let thirdPerson = persons.last {
                        XCTAssertEqual(thirdPerson.name, "Victor Emmanuel")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [
                                    [
                                        "_id": "58450d87f29e22207c83a236",
                                        "name": "Victor C Barros",
                                        "age":23,
                                        "_acl": [
                                            "creator": "58450d87c077970e38a388ba"
                                        ],
                                        "_kmd": [
                                            "lmt": "2016-12-05T06:47:35.711Z",
                                            "ect": "2016-12-05T06:47:35.711Z"
                                        ]
                                    ]
                                ],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var updatedPerson = Person()
                updatedPerson.name = "Victor C Barros"
                updatedPerson.personId = idToUpdate
                updatedPerson.age = 23
                updatedPerson = try! DataStore<Person>.collection(.network).save(updatedPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            weak var expectationSync = expectation(description: "Sync")
            
            var query = Query(format: "age == %@", 23)
            store.sync(query, options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(Int64(persons.count), initialCount + 2)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor C Barros")
                    }
                    
                    if let thirdPerson = persons.last {
                        XCTAssertEqual(thirdPerson.name, "Victor Emmanuel")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
    }

    func testSyncStoreDeltasetTurnedOffSendsRegularGETWithSync() {
        var store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSync = expectation(description: "Pull")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(Int64(persons.count), initialCount + 1)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [
                                    [
                                        "_id": "58450d87f29e22207c83a237",
                                        "name": "Victor Hugo",
                                        "_acl": [
                                            "creator": "58450d87c077970e38a388ba"
                                        ],
                                        "_kmd": [
                                            "lmt": "2016-12-05T06:47:35.711Z",
                                            "ect": "2016-12-05T06:47:35.711Z"
                                        ]
                                    ]
                                ],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Hugo"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSync = expectation(description: "Pull")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(Int64(persons.count), initialCount + 2)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    
                    if let thirdPerson = persons.last {
                        XCTAssertEqual(thirdPerson.name, "Victor Hugo")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
        store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: false))
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                [
                                    "_id": "58450d87f29e22207c83a236",
                                    "name": "Victor Barros",
                                    "_acl": [
                                        "creator": "58450d87c077970e38a388ba"
                                    ],
                                    "_kmd": [
                                        "lmt": "2016-12-05T06:47:35.711Z",
                                        "ect": "2016-12-05T06:47:35.711Z"
                                    ]
                                ],
                                [
                                    "_id": "58450d87f29e22207c83a237",
                                    "name": "Victor Hugo",
                                    "_acl": [
                                        "creator": "58450d87c077970e38a388ba"
                                    ],
                                    "_kmd": [
                                        "lmt": "2016-12-05T06:47:35.711Z",
                                        "ect": "2016-12-05T06:47:35.711Z"
                                    ]
                                ]
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            }
            
            weak var expectationSync = expectation(description: "Pull")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let persons):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(Int64(persons.count), initialCount + 2)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    
                    if let thirdPerson = persons.last {
                        XCTAssertEqual(thirdPerson.name, "Victor Hugo")
                    }
                case .failure(let error):
                    XCTFail(error.description)
                }
                expectationSync?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSync = nil
            }
        }
    }
    
    func testSyncStoreDeltaset1ItemAdded1Updated1DeletedWithFindNetworkReadPolicy() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        var idToUpdate = ""
        var idToDelete = ""
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ],
                            [
                                "_id": "58450d87f29e22207c83a237",
                                "name": "Victor Hugo",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
                var secondPerson = Person()
                secondPerson.name = "Victor Hugo"
                secondPerson = try! DataStore<Person>.collection(.network).save(secondPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
                idToUpdate = person.personId!
                idToDelete = secondPerson.personId!
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            var options = try! Options()
            options.readPolicy = .forceNetwork
            var query = Query()
            store.find(query, options: options) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success(let persons):
                    XCTAssertNotNil(persons)
                    
                    XCTAssertEqual(Int64(persons.count), initialCount + 2)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    
                    if let person = persons.last {
                        XCTAssertEqual(person.name, "Victor Hugo")
                    }
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertNotNil(cacheCount)
                    if let cacheCount = cacheCount {
                        XCTAssertEqual(cacheCount, persons.count)
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
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [
                                    [
                                        "_id": "58450d87f29e22207c83a236",
                                        "name": "Victor C Barros",
                                        "_acl": [
                                            "creator": "58450d87c077970e38a388ba"
                                        ],
                                        "_kmd": [
                                            "lmt": "2016-12-05T06:47:35.711Z",
                                            "ect": "2016-12-05T06:47:35.711Z"
                                        ]
                                    ]
                                ],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var updatedPerson = Person()
                updatedPerson.name = "Victor C Barros"
                updatedPerson.personId = idToUpdate
                updatedPerson = try! DataStore<Person>.collection(.network).save(updatedPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            weak var expectationFind = expectation(description: "Find")
            var options = try! Options()
            options.readPolicy = .forceNetwork
            var query = Query()
            store.find(query, options: options) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success(let persons):
                    XCTAssertNotNil(persons)
                    
                    XCTAssertEqual(Int64(persons.count), initialCount + 2)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor C Barros")
                    }
                    
                    if let person = persons.last {
                        XCTAssertEqual(person.name, "Victor Hugo")
                    }
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertNotNil(cacheCount)
                    if let cacheCount = cacheCount {
                        XCTAssertEqual(cacheCount, persons.count)
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
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [],
                                "deleted" : [["_id":"58450d87f29e22207c83a237"]]
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                try! DataStore<Person>.collection(.network).remove(byId: idToDelete).waitForResult(timeout: defaultTimeout)
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            weak var expectationFind = expectation(description: "Find")
            var options = try! Options()
            options.readPolicy = .forceNetwork
            var query = Query()
            store.find(query, options: options) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success(let persons):
                    XCTAssertNotNil(persons)
                    
                    XCTAssertEqual(Int64(persons.count), initialCount + 1)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor C Barros")
                    }
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertNotNil(cacheCount)
                    if let cacheCount = cacheCount {
                        XCTAssertEqual(cacheCount, persons.count)
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
    }

    func testSyncStoreDeltaset1WithQuery1ItemDeletedWithFindWithNetworkPolicy() {
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        var idToDelete = ""
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())":
                        let json = [
                            [
                                "_id": "58450d87f29e22207c83a236",
                                "name": "Victor Barros",
                                "age":23,
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ],
                            [
                                "_id": "58450d87f29e22207c83a238",
                                "name": "Victor Emmanuel",
                                "age":23,
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
                            ]
                        ]
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: json
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person.age = 23
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
                var secondPerson = Person()
                secondPerson.name = "Victor Hugo"
                secondPerson.age = 24
                secondPerson = try! DataStore<Person>.collection(.network).save(secondPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
                var thirdPerson = Person()
                thirdPerson.name = "Victor Emmanuel"
                thirdPerson.age = 23
                thirdPerson = try! DataStore<Person>.collection(.network).save(thirdPerson, options: nil).waitForResult(timeout: defaultTimeout).value()
                idToDelete = thirdPerson.personId!
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            var options = try! Options()
            options.readPolicy = .forceNetwork
            var query = Query(format: "age == %@", 23)
            store.find(query, options: options) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success(let persons):
                    XCTAssertNotNil(persons)
                    
                    XCTAssertEqual(Int64(persons.count), initialCount + 2)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    
                    if let person = persons.last {
                        XCTAssertEqual(person.name, "Victor Emmanuel")
                    }
                    
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertNotNil(cacheCount)
                    if let cacheCount = cacheCount {
                        XCTAssertEqual(cacheCount, persons.count)
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
        
        do {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "changed" : [],
                                "deleted" : [["_id": "58450d87f29e22207c83a238"]]
                            ]
                        )
                    default:
                        XCTFail(url.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                try! DataStore<Person>.collection(.network).remove(byId:idToDelete).waitForResult(timeout: defaultTimeout)
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            weak var expectationFind = expectation(description: "Find")
            var options = try! Options()
            options.readPolicy = .forceNetwork
            var query = Query(format: "age == %@", 23)
            store.find(query, options: options) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success(let persons):
                    XCTAssertNotNil(persons)
                    
                    XCTAssertEqual(Int64(persons.count), initialCount + 1)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertNotNil(cacheCount)
                    if let cacheCount = cacheCount {
                        XCTAssertEqual(cacheCount, persons.count)
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
    }
    
    func testPullMemoryConsumption() {
        let size = 100_000
        mockResponse { request in
            switch request.url!.path {
            case "/appdata/_kid_/Person/_count":
                return HttpResponse(json: ["count" : size])
            case "/appdata/_kid_/Person":
                let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                let skip = Int(urlComponents.queryItems!.filter({ $0.name == "skip" }).first!.value!)!
                let limit = Int(urlComponents.queryItems!.filter({ $0.name == "limit" }).first!.value!)!
                
                var entities = [JsonDictionary]()
                for index in 1 ... limit {
                    var entity = JsonDictionary()
                    entity["_id"] = "ID-\(skip + index)"
                    entity["name"] = "Person \(skip + index)"
                    entity["_acl"] = [
                        "creator" : UUID().uuidString
                    ]
                    entity["_kmd"] = [
                        "lmt" : Date().toISO8601(),
                        "ect" : Date().toISO8601()
                    ]
                    entities.append(entity)
                }
                return HttpResponse(json: entities)
            default:
                XCTFail(request.url!.path)
                return HttpResponse(statusCode: 404, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let store = try! DataStore<Person>.collection(.sync, autoPagination: true)
        
        let startMemory = getMegabytesUsed()
        XCTAssertNotNil(startMemory)
        
        weak var expectationPull = expectation(description: "Pull")
        
        store.pull(options: nil) {
            switch $0 {
            case .success(let results):
                XCTAssertEqual(results.count, size)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            if let startMemory = startMemory, let endMemory = getMegabytesUsed() {
                let diffMemory = endMemory - startMemory
                XCTAssertLessThan(diffMemory, 200)
            }
            
            expectationPull?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout * (Double(size) / 10_000.0)) { error in
            expectationPull = nil
        }
    }
    
    func testObjectObserve() {
        let dataStore = try! DataStore<Person>.collection(.sync)
        
        let personId = UUID().uuidString
        
        let person = Person()
        person.personId = personId
        person.name = "Victor"
        XCTAssertNil(person.realm)
        XCTAssertNil(person.realmConfiguration)
        XCTAssertNil(person.entityIdReference)
        
        let person2 = try! dataStore.save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
        XCTAssertNil(person2.realm)
        XCTAssertNotNil(person2.realmConfiguration)
        XCTAssertNotNil(person2.entityIdReference)
        
        var notified = false
        
        weak var expectationObserve = expectation(description: "Observe")
        
        let notificationToken = person2.observe { (objectChange: Kinvey.ObjectChange<Person>) in
            notified = true
            switch objectChange {
            case .change(let person):
                XCTAssertEqual(person.name, "Victor Barros")
            case .deleted:
                XCTFail("Delete changes was not expected")
            case .error(let error):
                XCTFail(error.localizedDescription)
            }
            expectationObserve?.fulfill()
        }
        
        let realm = try! Realm(configuration: person2.realmConfiguration!)
        let person3 = Person()
        person3.personId = personId
        person3.name = "Victor Barros"
        try! realm.write {
            realm.add(person3, update: true)
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            notificationToken?.invalidate()
            expectationObserve = nil
        }
        
        XCTAssertTrue(notified)
        
        XCTAssertEqual(person.name, "Victor Barros")
        XCTAssertEqual(person2.name, "Victor Barros")
    }
    
    func testCollectionObserve() {
        let dataStore = try! DataStore<Person>.collection(.sync)
        
        let personId = UUID().uuidString
        let personName = "Victor"
        
        var count = 0
        weak var expectationObserveInitial = expectation(description: "Observe Initial")
        weak var expectationObserveUpdate = expectation(description: "Observe Update")
        
        let notificationToken = dataStore.observe {
            defer {
                count += 1
            }
            switch $0 {
            case .initial(let results):
                XCTAssertEqual(count, 0)
                XCTAssertEqual(results.count, 0)
                expectationObserveInitial?.fulfill()
            case .update(let results, let deletions, let insertions, let modifications):
                XCTAssertEqual(count, 1)
                XCTAssertEqual(results.count, 1)
                XCTAssertNotNil(results.first)
                if let person = results.first {
                    XCTAssertEqual(person.personId, personId)
                    XCTAssertEqual(person.name, personName)
                }
                XCTAssertEqual(deletions.count, 0)
                XCTAssertEqual(insertions.count, 1)
                XCTAssertEqual(insertions.first, 0)
                XCTAssertEqual(modifications.count, 0)
                expectationObserveUpdate?.fulfill()
            case .error(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        let person = Person()
        person.personId = personId
        person.name = personName
        XCTAssertNil(person.realm)
        XCTAssertNil(person.realmConfiguration)
        XCTAssertNil(person.entityIdReference)
        
        let person2 = try! dataStore.save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
        XCTAssertNil(person2.realm)
        XCTAssertNotNil(person2.realmConfiguration)
        XCTAssertNotNil(person2.entityIdReference)
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            notificationToken?.invalidate()
            expectationObserveInitial = nil
            expectationObserveUpdate = nil
        }
        
        XCTAssertEqual(count, 2)
    }
    
    func testPullWithSkip() {
        signUp(client: self.client)
        
        var json = [JsonDictionary]()
        for i in 1 ... 10 {
            json.append([
                "_id" : UUID().uuidString,
                "name" : UUID().uuidString,
                "age" : i,
                "_acl" : [
                    "creator" : self.client.activeUser!.userId
                ],
                "_kmd" : [
                    "lmt" : Date().toISO8601(),
                    "ect" : Date().toISO8601()
                ]
            ])
        }
        
        mockResponse { request in
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            switch urlComponents.path {
            case "/appdata/_kid_/Person/":
                if let skipString = urlComponents.queryItems?.filter({ $0.name == "skip" }).first?.value,
                    let skip = Int(skipString)
                {
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                        json: Array(json[skip...])
                    )
                }
                return HttpResponse(
                    headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                    json: json
                )
            case "/appdata/_kid_/Person/_deltaset":
                return HttpResponse(
                    headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                    json: [
                        "changed" : [],
                        "deleted" : []
                    ]
                )
            default:
                XCTFail(urlComponents.path)
                return HttpResponse(statusCode: 404, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let dataStore = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        do {
            var results = try dataStore.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(results.count, json.count)
            results = try dataStore.find().waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(results.count, json.count)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        do {
            let skip = 2
            let query = Query()
            query.skip = skip
            var results = try dataStore.pull(query, options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(results.count, json.count - skip)
            results = try dataStore.find().waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(results.count, json.count)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        do {
            var results = try dataStore.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(results.count, json.count)
            results = try dataStore.find().waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(results.count, json.count)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testIssue311() {
        signUp()
        
        let store = try! DataStore<Issue311_MyModel>.collection(.sync)
        
        do {
            var myModel = Issue311_MyModel()
            myModel.someSimpleProperty = "A"
            
            let complexType = Issue311_ComplexType()
            complexType.someSimpleProperty = "B"
            complexType.someListProperty.append("C")
            complexType.someListProperty.append("D")
            myModel.someComplexProperty = complexType
            
            myModel = try store.save(myModel, options: nil).waitForResult(timeout: defaultTimeout).value()
            
            XCTAssertTrue(myModel.entityId!.hasPrefix("tmp_"))
            XCTAssertEqual(myModel.someSimpleProperty, "A")
            XCTAssertEqual(myModel.someComplexProperty?.someSimpleProperty, "B")
            XCTAssertEqual(myModel.someComplexProperty?.someListProperty.first, "C")
            XCTAssertTrue(myModel.someComplexProperty?.someListProperty.first == "C")
            XCTAssertTrue(myModel.someComplexProperty?.someListProperty.first?.isEqual("C") ?? false)
            XCTAssertEqual(myModel.someComplexProperty?.someListProperty.last, "D")
            XCTAssertTrue(myModel.someComplexProperty?.someListProperty.last == "D")
            XCTAssertTrue(myModel.someComplexProperty?.someListProperty.last?.isEqual("D") ?? false)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        do {
            mockResponse { request in
                let urlComponents = request.url!
                switch (request.httpMethod!, urlComponents.path) {
                case ("POST", "/appdata/\(self.client.appKey!)/\(Issue311_MyModel.collectionName())"):
                    guard let object = try? JSONSerialization.jsonObject(with: request), var json = object as? [String : Any] else {
                        fallthrough
                    }
                    XCTAssertNil(json["_id"])
                    json["_id"] = UUID().uuidString
                    XCTAssertEqual(json["someSimpleProperty"] as? String, "A")
                    let someComplexProperty = json["someComplexProperty"] as? [String : Any]
                    let someListProperty = someComplexProperty?["someListProperty"] as? [String]
                    XCTAssertEqual(someComplexProperty?["someSimpleProperty"] as? String, "B")
                    XCTAssertEqual(someListProperty?.count, 2)
                    XCTAssertEqual(someListProperty?.first, "C")
                    XCTAssertEqual(someListProperty?.last, "D")
                    return HttpResponse(json: json)
                default:
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }

            let count = try store.push(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(count, 1)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let myModels = try store.find(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(myModels.count, 1)
            XCTAssertNotNil(myModels.first)
            if let myModel = myModels.first {
                XCTAssertFalse(myModel.entityId!.hasPrefix("tmp_"))
                XCTAssertEqual(myModel.someSimpleProperty, "A")
                XCTAssertEqual(myModel.someComplexProperty?.someSimpleProperty, "B")
                XCTAssertEqual(myModel.someComplexProperty?.someListProperty.count, 2)
                XCTAssertEqual(myModel.someComplexProperty?.someListProperty.first, "C")
                XCTAssertEqual(myModel.someComplexProperty?.someListProperty.last, "D")
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testIssue311Codable() {
        signUp()
        
        Kinvey.logLevel = .debug
        
        let store = try! DataStore<Issue311_MyModelCodable>.collection(.sync)
        
        do {
            var myModel = Issue311_MyModelCodable()
            myModel.someSimpleProperty = "A"
            
            let complexType = Issue311_ComplexTypeCodable()
            complexType.someSimpleProperty = "B"
            complexType.someListProperty.append("C")
            complexType.someListProperty.append("D")
            myModel.someComplexProperty = complexType
            
            myModel = try store.save(myModel, options: nil).waitForResult(timeout: defaultTimeout).value()
            
            XCTAssertTrue(myModel.entityId!.hasPrefix("tmp_"))
            XCTAssertEqual(myModel.someSimpleProperty, "A")
            XCTAssertEqual(myModel.someComplexProperty?.someSimpleProperty, "B")
            XCTAssertEqual(myModel.someComplexProperty?.someListProperty.first, "C")
            XCTAssertEqual(myModel.someComplexProperty?.someListProperty.last, "D")
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        do {
            mockResponse { request in
                let urlComponents = request.url!
                switch (request.httpMethod!, urlComponents.path) {
                case ("POST", "/appdata/\(self.client.appKey!)/\(Issue311_MyModelCodable.collectionName())"):
                    guard let object = try? JSONSerialization.jsonObject(with: request), var json = object as? [String : Any] else {
                        fallthrough
                    }
                    XCTAssertNil(json["_id"])
                    json["_id"] = UUID().uuidString
                    XCTAssertEqual(json["someSimpleProperty"] as? String, "A")
                    let someComplexProperty = json["someComplexProperty"] as? [String : Any]
                    let someListProperty = someComplexProperty?["someListProperty"] as? [String]
                    XCTAssertEqual(someComplexProperty?["someSimpleProperty"] as? String, "B")
                    XCTAssertEqual(someListProperty?.count, 2)
                    XCTAssertEqual(someListProperty?.first, "C")
                    XCTAssertEqual(someListProperty?.last, "D")
                    return HttpResponse(json: json)
                default:
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            let count = try store.push(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(count, 1)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        do {
            let myModels = try store.find(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(myModels.count, 1)
            XCTAssertNotNil(myModels.first)
            if let myModel = myModels.first {
                XCTAssertFalse(myModel.entityId!.hasPrefix("tmp_"))
                XCTAssertEqual(myModel.someSimpleProperty, "A")
                XCTAssertEqual(myModel.someComplexProperty?.someSimpleProperty, "B")
                XCTAssertEqual(myModel.someComplexProperty?.someListProperty.count, 2)
                XCTAssertEqual(myModel.someComplexProperty?.someListProperty.first, "C")
                XCTAssertEqual(myModel.someComplexProperty?.someListProperty.last, "D")
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testPushCodable() {
        signUp()
        
        let store = try! DataStore<PersonCodable>.collection(.sync)
        
        let name = UUID().uuidString
        
        do {
            var person = PersonCodable()
            person.name = name
            
            var address = AddressCodable()
            address.city = "Boston"
            person.address = address
            
            address = AddressCodable()
            address.city = "Vancouver"
            person.addresses.append(address)
            
            person.stringValues.append("A")
            person.intValues.append(1)
            person.floatValues.append(2.5)
            person.doubleValues.append(3.5)
            person.boolValues.append(true)
            
            person = try store.save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            
            XCTAssertTrue(person.entityId!.hasPrefix("tmp_"))
            XCTAssertEqual(person.name, name)
            XCTAssertEqual(person.address?.city, "Boston")
            XCTAssertEqual(person.addresses.first?.city, "Vancouver")
            XCTAssertEqual(person.stringValues.first, "A")
            XCTAssertEqual(person.intValues.first, 1)
            XCTAssertEqual(person.floatValues.first, 2.5)
            XCTAssertEqual(person.doubleValues.first, 3.5)
            XCTAssertEqual(person.boolValues.first, true)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        do {
            mockResponse { request in
                let urlComponents = request.url!
                switch (request.httpMethod!, urlComponents.path) {
                case ("POST", "/appdata/\(self.client.appKey!)/\(PersonCodable.collectionName())"):
                    guard let object = try? JSONSerialization.jsonObject(with: request), var json = object as? [String : Any] else {
                        fallthrough
                    }
                    XCTAssertNil(json["_id"])
                    json["_id"] = UUID().uuidString
                    XCTAssertEqual(json["name"] as? String, name)
                    let address = json["address"] as? [String : Any]
                    let addresses = json["addresses"] as? [[String : Any]]
                    let stringValues = json["stringValues"] as? [String]
                    let intValues = json["intValues"] as? [Int]
                    let floatValues = json["floatValues"] as? [Float]
                    let doubleValues = json["doubleValues"] as? [Double]
                    let boolValues = json["boolValues"] as? [Bool]
                    XCTAssertEqual(address?["city"] as? String, "Boston")
                    XCTAssertEqual(addresses?.count, 1)
                    XCTAssertEqual(addresses?.first?["city"] as? String, "Vancouver")
                    XCTAssertEqual(stringValues?.first, "A")
                    XCTAssertEqual(intValues?.first, 1)
                    XCTAssertEqual(floatValues?.first, 2.5)
                    XCTAssertEqual(doubleValues?.first, 3.5)
                    XCTAssertEqual(boolValues?.first, true)
                    return HttpResponse(json: json)
                default:
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            let count = try store.push(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(count, 1)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        do {
            let persons = try store.find(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(persons.count, 1)
            XCTAssertNotNil(persons.first)
            if let person = persons.first {
                XCTAssertFalse(person.entityId!.hasPrefix("tmp_"))
                XCTAssertEqual(person.name, name)
                XCTAssertEqual(person.address?.city, "Boston")
                XCTAssertEqual(person.addresses.first?.city, "Vancouver")
                XCTAssertEqual(person.stringValues.first, "A")
                XCTAssertEqual(person.intValues.first, 1)
                XCTAssertEqual(person.floatValues.first, 2.5)
                XCTAssertEqual(person.doubleValues.first, 3.5)
                XCTAssertEqual(person.boolValues.first, true)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testPullCodable() {
        let id1 = UUID().uuidString
        let name1 = UUID().uuidString
        let age1 = Int(arc4random())
        let creator1 = UUID().uuidString
        let lmt1 = Date().toISO8601()
        let ect1 = Date().toISO8601()
        
        let id2 = UUID().uuidString
        let name2 = UUID().uuidString
        let age2 = Int(arc4random())
        let creator2 = UUID().uuidString
        let lmt2 = Date().toISO8601()
        let ect2 = Date().toISO8601()
        
        let mockObjs: [[String : Any]] = [
            [
                "_id": id1,
                "name": name1,
                "age": age1,
                "_acl": [
                    "creator": creator1
                ],
                "_kmd": [
                    "lmt": lmt1,
                    "ect": ect1
                ]
            ],
            [
                "_id": id2,
                "name": name2,
                "age": age2,
                "_acl": [
                    "creator": creator2
                ],
                "_kmd": [
                    "lmt": lmt2,
                    "ect": ect2
                ]
            ]
        ]
        
        let store = try! DataStore<PersonCodable>.collection(.sync)
        
        do {
            mockResponse(json: mockObjs)
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 2)
                    if let person = persons.first {
                        XCTAssertEqual(person.entityId, id1)
                        XCTAssertEqual(person.personId, id1)
                        XCTAssertEqual(person.name, name1)
                        XCTAssertEqual(person.age, age1)
                        XCTAssertEqual(person.acl?.creator, creator1)
                        XCTAssertEqual(person.metadata?.lmt, lmt1)
                        XCTAssertEqual(person.metadata?.ect, ect1)
                    }
                    if let person = persons.last {
                        XCTAssertEqual(person.entityId, id2)
                        XCTAssertEqual(person.personId, id2)
                        XCTAssertEqual(person.name, name2)
                        XCTAssertEqual(person.age, age2)
                        XCTAssertEqual(person.acl?.creator, creator2)
                        XCTAssertEqual(person.metadata?.lmt, lmt2)
                        XCTAssertEqual(person.metadata?.ect, ect2)
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout, handler: { (error) in
                expectationPull = nil
            })
        }
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            store.find() {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 2)
                    if let person = persons.first {
                        XCTAssertEqual(person.entityId, id1)
                        XCTAssertEqual(person.personId, id1)
                        XCTAssertEqual(person.name, name1)
                        XCTAssertEqual(person.age, age1)
                        XCTAssertEqual(person.acl?.creator, creator1)
                        XCTAssertEqual(person.metadata?.lmt, lmt1)
                        XCTAssertEqual(person.metadata?.ect, ect1)
                    }
                    if let person = persons.last {
                        XCTAssertEqual(person.entityId, id2)
                        XCTAssertEqual(person.personId, id2)
                        XCTAssertEqual(person.name, name2)
                        XCTAssertEqual(person.age, age2)
                        XCTAssertEqual(person.acl?.creator, creator2)
                        XCTAssertEqual(person.metadata?.lmt, lmt2)
                        XCTAssertEqual(person.metadata?.ect, ect2)
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout, handler: { (error) in
                expectationFind = nil
            })
        }
    }
    
    func testPullAutoPaginationDeltaSetCodable() {
        let id1 = UUID().uuidString
        let name1 = UUID().uuidString
        let age1 = Int(arc4random())
        let creator1 = UUID().uuidString
        let lmt1 = Date().toISO8601()
        let ect1 = Date().toISO8601()
        
        let id2 = UUID().uuidString
        let name2 = UUID().uuidString
        let age2 = Int(arc4random())
        let creator2 = UUID().uuidString
        let lmt2 = Date().toISO8601()
        let ect2 = Date().toISO8601()
        
        let mockObjs: [[String : Any]] = [
            [
                "_id": id1,
                "name": name1,
                "age": age1,
                "_acl": [
                    "creator": creator1
                ],
                "_kmd": [
                    "lmt": lmt1,
                    "ect": ect1
                ]
            ],
            [
                "_id": id2,
                "name": name2,
                "age": age2,
                "_acl": [
                    "creator": creator2
                ],
                "_kmd": [
                    "lmt": lmt2,
                    "ect": ect2
                ]
            ]
        ]
        
        let maxSizePerResultSet = 1
        let store = try! DataStore<PersonCodable>.collection(.sync, autoPagination: true, options: try! Options(deltaSet: true, maxSizePerResultSet: maxSizePerResultSet))
        
        XCTContext.runActivity(named: "Pull Data") { activity in
            var count = 0
            mockResponse { request in
                let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                switch urlComponents.path {
                case "/appdata/\(self.client.appKey!)/\(PersonCodable.collectionName())/_count":
                    return HttpResponse(json: ["count" : mockObjs.count])
                case "/appdata/\(self.client.appKey!)/\(PersonCodable.collectionName())/":
                    let skip = Int(urlComponents.queryItems!.filter({ $0.name == "skip" }).first!.value!)!
                    XCTAssertEqual(skip, count)
                    let limit = Int(urlComponents.queryItems!.filter({ $0.name == "limit" }).first!.value!)!
                    XCTAssertEqual(limit, maxSizePerResultSet)
                    count += limit
                    return HttpResponse(json: Array(mockObjs[skip ..< skip + limit]))
                default:
                    XCTFail(request.url!.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 2)
                    if let person = persons.first {
                        XCTAssertEqual(person.entityId, id1)
                        XCTAssertEqual(person.personId, id1)
                        XCTAssertEqual(person.name, name1)
                        XCTAssertEqual(person.age, age1)
                        XCTAssertEqual(person.acl?.creator, creator1)
                        XCTAssertEqual(person.metadata?.lmt, lmt1)
                        XCTAssertEqual(person.metadata?.ect, ect1)
                    }
                    if let person = persons.last {
                        XCTAssertEqual(person.entityId, id2)
                        XCTAssertEqual(person.personId, id2)
                        XCTAssertEqual(person.name, name2)
                        XCTAssertEqual(person.age, age2)
                        XCTAssertEqual(person.acl?.creator, creator2)
                        XCTAssertEqual(person.metadata?.lmt, lmt2)
                        XCTAssertEqual(person.metadata?.ect, ect2)
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout, handler: { (error) in
                expectationPull = nil
            })
        }
        
        XCTContext.runActivity(named: "Find Local Data") { activity in
            weak var expectationFind = expectation(description: "Find")
            
            store.find() {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 2)
                    if let person = persons.first {
                        XCTAssertEqual(person.entityId, id1)
                        XCTAssertEqual(person.personId, id1)
                        XCTAssertEqual(person.name, name1)
                        XCTAssertEqual(person.age, age1)
                        XCTAssertEqual(person.acl?.creator, creator1)
                        XCTAssertEqual(person.metadata?.lmt, lmt1)
                        XCTAssertEqual(person.metadata?.ect, ect1)
                    }
                    if let person = persons.last {
                        XCTAssertEqual(person.entityId, id2)
                        XCTAssertEqual(person.personId, id2)
                        XCTAssertEqual(person.name, name2)
                        XCTAssertEqual(person.age, age2)
                        XCTAssertEqual(person.acl?.creator, creator2)
                        XCTAssertEqual(person.metadata?.lmt, lmt2)
                        XCTAssertEqual(person.metadata?.ect, ect2)
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout, handler: { (error) in
                expectationFind = nil
            })
        }
    }
    
    func testCascadeDeleteItemsWithOtherReferences() {
        let referenceId = UUID().uuidString
        let referenceData = try! JSONEncoder().encode(Reference(referenceId))
        let reference = try! JSONSerialization.jsonObject(with: referenceData) as! JsonDictionary
        
        let id1 = UUID().uuidString
        let name1 = UUID().uuidString
        let age1 = Int(arc4random())
        let creator1 = UUID().uuidString
        let lmt1 = Date().toISO8601()
        let ect1 = Date().toISO8601()
        
        let id2 = UUID().uuidString
        let name2 = UUID().uuidString
        let age2 = Int(arc4random())
        let creator2 = UUID().uuidString
        let lmt2 = Date().toISO8601()
        let ect2 = Date().toISO8601()
        
        let mockObjs: [[String : Any]] = [
            [
                "_id": id1,
                "name": name1,
                "age": age1,
                "reference" : reference,
                "_acl": [
                    "creator": creator1
                ],
                "_kmd": [
                    "lmt": lmt1,
                    "ect": ect1
                ]
            ],
            [
                "_id": id2,
                "name": name2,
                "age": age2,
                "reference" : reference,
                "_acl": [
                    "creator": creator2
                ],
                "_kmd": [
                    "lmt": lmt2,
                    "ect": ect2
                ]
            ]
        ]
        
        var count = 0
        mockResponse { request in
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            switch urlComponents.path {
            case "/appdata/\(self.client.appKey!)/\(PersonCodable.collectionName())/":
                return HttpResponse(json: mockObjs)
            default:
                XCTFail(request.url!.path)
                return HttpResponse(statusCode: 404, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let store = try! DataStore<PersonCodable>.collection(.sync)
        let realm = (store.cache!.cache as! RealmCache<PersonCodable>).newRealm
        let items = try! store.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
        XCTAssertEqual(mockObjs.count, items.count)
        XCTAssertEqual(mockObjs.count, store.cache!.count(query: nil))
        XCTAssertEqual(1, realm.objects(Reference.self).count)
        
        if let person = items.first {
            let count = try! store.remove(person).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(1, count)
            XCTAssertEqual(1, realm.objects(Reference.self).count)
        }
        
        if let person = items.last {
            XCTAssertEqual(person.reference?.entityId, referenceId)
            let refreshedInstance = try! store.find(person.entityId!).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(refreshedInstance.reference?.entityId, referenceId)
        }
    }
    
    func testCascadeDeleteItemsWithOtherReferencesInALists() {
        let referenceId = UUID().uuidString
        let referenceData = try! JSONEncoder().encode(Reference(referenceId))
        let reference = try! JSONSerialization.jsonObject(with: referenceData) as! JsonDictionary
        
        let id1 = UUID().uuidString
        let name1 = UUID().uuidString
        let age1 = Int(arc4random())
        let creator1 = UUID().uuidString
        let lmt1 = Date().toISO8601()
        let ect1 = Date().toISO8601()
        
        let id2 = UUID().uuidString
        let name2 = UUID().uuidString
        let age2 = Int(arc4random())
        let creator2 = UUID().uuidString
        let lmt2 = Date().toISO8601()
        let ect2 = Date().toISO8601()
        
        let mockObjs: [[String : Any]] = [
            [
                "_id": id1,
                "name": name1,
                "age": age1,
                "references" : [reference],
                "_acl": [
                    "creator": creator1
                ],
                "_kmd": [
                    "lmt": lmt1,
                    "ect": ect1
                ]
            ],
            [
                "_id": id2,
                "name": name2,
                "age": age2,
                "references" : [reference],
                "_acl": [
                    "creator": creator2
                ],
                "_kmd": [
                    "lmt": lmt2,
                    "ect": ect2
                ]
            ]
        ]
        
        var count = 0
        mockResponse { request in
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            switch urlComponents.path {
            case "/appdata/\(self.client.appKey!)/\(PersonCodable.collectionName())/":
                return HttpResponse(json: mockObjs)
            default:
                XCTFail(request.url!.path)
                return HttpResponse(statusCode: 404, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let store = try! DataStore<PersonCodable>.collection(.sync)
        let realm = (store.cache!.cache as! RealmCache<PersonCodable>).newRealm
        let items = try! store.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
        XCTAssertEqual(mockObjs.count, items.count)
        XCTAssertEqual(mockObjs.count, store.cache!.count(query: nil))
        XCTAssertEqual(1, realm.objects(Reference.self).count)
        
        if let person = items.first {
            let count = try! store.remove(person).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(1, count)
            XCTAssertEqual(1, realm.objects(Reference.self).count)
        }
        
        if let person = items.last {
            XCTAssertEqual(person.references.first?.entityId, referenceId)
            let refreshedInstance = try! store.find(person.entityId!).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(refreshedInstance.references.first?.entityId, referenceId)
        }
    }
    
    func testCascadeDeleteItemsWithOtherReferencesInAList() {
        let referenceId = UUID().uuidString
        let referenceData = try! JSONEncoder().encode(Reference(referenceId))
        let reference = try! JSONSerialization.jsonObject(with: referenceData) as! JsonDictionary
        
        let id1 = UUID().uuidString
        let name1 = UUID().uuidString
        let age1 = Int(arc4random())
        let creator1 = UUID().uuidString
        let lmt1 = Date().toISO8601()
        let ect1 = Date().toISO8601()
        
        let id2 = UUID().uuidString
        let name2 = UUID().uuidString
        let age2 = Int(arc4random())
        let creator2 = UUID().uuidString
        let lmt2 = Date().toISO8601()
        let ect2 = Date().toISO8601()
        
        let mockObjs: [[String : Any]] = [
            [
                "_id": id1,
                "name": name1,
                "age": age1,
                "reference" : reference,
                "_acl": [
                    "creator": creator1
                ],
                "_kmd": [
                    "lmt": lmt1,
                    "ect": ect1
                ]
            ],
            [
                "_id": id2,
                "name": name2,
                "age": age2,
                "references" : [reference],
                "_acl": [
                    "creator": creator2
                ],
                "_kmd": [
                    "lmt": lmt2,
                    "ect": ect2
                ]
            ]
        ]
        
        var count = 0
        mockResponse { request in
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            switch urlComponents.path {
            case "/appdata/\(self.client.appKey!)/\(PersonCodable.collectionName())/":
                return HttpResponse(json: mockObjs)
            default:
                XCTFail(request.url!.path)
                return HttpResponse(statusCode: 404, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let store = try! DataStore<PersonCodable>.collection(.sync)
        let realm = (store.cache!.cache as! RealmCache<PersonCodable>).newRealm
        let items = try! store.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
        XCTAssertEqual(mockObjs.count, items.count)
        XCTAssertEqual(mockObjs.count, store.cache!.count(query: nil))
        XCTAssertEqual(1, realm.objects(Reference.self).count)
        
        if let person = items.first {
            let count = try! store.remove(person).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(1, count)
            XCTAssertEqual(1, realm.objects(Reference.self).count)
        }
        
        if let person = items.last {
            XCTAssertEqual(person.references.first?.entityId, referenceId)
            let refreshedInstance = try! store.find(person.entityId!).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(refreshedInstance.references.first?.entityId, referenceId)
        }
    }
    
    func testCascadeDeleteItemsWithOtherReferencesInAListReverse() {
        Kinvey.logLevel = .debug
        let referenceId = UUID().uuidString
        let referenceData = try! JSONEncoder().encode(Reference(referenceId))
        let reference = try! JSONSerialization.jsonObject(with: referenceData) as! JsonDictionary
        
        let id1 = UUID().uuidString
        let name1 = UUID().uuidString
        let age1 = Int(arc4random())
        let creator1 = UUID().uuidString
        let lmt1 = Date().toISO8601()
        let ect1 = Date().toISO8601()
        
        let id2 = UUID().uuidString
        let name2 = UUID().uuidString
        let age2 = Int(arc4random())
        let creator2 = UUID().uuidString
        let lmt2 = Date().toISO8601()
        let ect2 = Date().toISO8601()
        
        let mockObjs: [[String : Any]] = [
            [
                "_id": id2,
                "name": name2,
                "age": age2,
                "references" : [reference],
                "_acl": [
                    "creator": creator2
                ],
                "_kmd": [
                    "lmt": lmt2,
                    "ect": ect2
                ]
            ],
            [
                "_id": id1,
                "name": name1,
                "age": age1,
                "reference" : reference,
                "_acl": [
                    "creator": creator1
                ],
                "_kmd": [
                    "lmt": lmt1,
                    "ect": ect1
                ]
            ]
        ]
        
        var count = 0
        mockResponse { request in
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            switch urlComponents.path {
            case "/appdata/\(self.client.appKey!)/\(PersonCodable.collectionName())/":
                return HttpResponse(json: mockObjs)
            default:
                XCTFail(request.url!.path)
                return HttpResponse(statusCode: 404, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let store = try! DataStore<PersonCodable>.collection(.sync)
        let realm = (store.cache!.cache as! RealmCache<PersonCodable>).newRealm
        let items = try! store.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
        XCTAssertEqual(mockObjs.count, items.count)
        XCTAssertEqual(mockObjs.count, store.cache!.count(query: nil))
        XCTAssertEqual(1, realm.objects(Reference.self).count)
        
        if let person = items.first {
            let count = try! store.remove(person).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(1, count)
            XCTAssertEqual(1, realm.objects(Reference.self).count)
        }
        
        if let person = items.last {
            XCTAssertEqual(person.reference?.entityId, referenceId)
            let refreshedInstance = try! store.find(person.entityId!).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(refreshedInstance.reference?.entityId, referenceId)
        }
    }
    
    func testCascadeDeleteItemsWithOtherReferencesInAnotherCollectionInAList() {
        let referenceId = UUID().uuidString
        let referenceData = try! JSONEncoder().encode(Reference(referenceId))
        let reference = try! JSONSerialization.jsonObject(with: referenceData) as! JsonDictionary
        
        let id1 = UUID().uuidString
        let name1 = UUID().uuidString
        let age1 = Int(arc4random())
        let creator1 = UUID().uuidString
        let lmt1 = Date().toISO8601()
        let ect1 = Date().toISO8601()
        
        var count = 0
        mockResponse { request in
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            switch urlComponents.path {
            case "/appdata/\(self.client.appKey!)/\(PersonCodable.collectionName())/":
                return HttpResponse(json: [
                    [
                        "_id": id1,
                        "name": name1,
                        "age": age1,
                        "reference" : reference,
                        "_acl": [
                            "creator": creator1
                        ],
                        "_kmd": [
                            "lmt": lmt1,
                            "ect": ect1
                        ]
                    ]
                ])
            case "/appdata/\(self.client.appKey!)/\(EntityWithRefenceCodable.collectionName())/":
                return HttpResponse(json: [
                    [
                        "_id": id1,
                        "references" : [reference],
                        "_acl": [
                            "creator": creator1
                        ],
                        "_kmd": [
                            "lmt": lmt1,
                            "ect": ect1
                        ]
                    ]
                ])
            default:
                XCTFail(request.url!.path)
                return HttpResponse(statusCode: 404, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let personStore = try! DataStore<PersonCodable>.collection(.sync)
        let entityWithRefenceStore = try! DataStore<EntityWithRefenceCodable>.collection(.sync)
        let realm = (personStore.cache!.cache as! RealmCache<PersonCodable>).newRealm
        let persons = try! personStore.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
        let entities = try! entityWithRefenceStore.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
        XCTAssertEqual(1, persons.count)
        XCTAssertEqual(1, entities.count)
        XCTAssertEqual(1, personStore.cache!.count(query: nil))
        XCTAssertEqual(1, entityWithRefenceStore.cache!.count(query: nil))
        XCTAssertEqual(1, realm.objects(Reference.self).count)
        
        if let person = persons.first {
            let count = try! personStore.remove(person).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(1, count)
            XCTAssertEqual(1, realm.objects(Reference.self).count)
            XCTAssertEqual(entities.first?.references.first?.entityId, referenceId)
            
            let refreshedInstance = try! entityWithRefenceStore.find(entities.first!.entityId!).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(refreshedInstance.references.first?.entityId, referenceId)
        }
    }
    
    func testCascadeDeleteItemsWithOtherReferencesInAnotherCollectionInAListReverse() {
        let referenceId = UUID().uuidString
        let referenceData = try! JSONEncoder().encode(Reference(referenceId))
        let reference = try! JSONSerialization.jsonObject(with: referenceData) as! JsonDictionary
        
        let id1 = UUID().uuidString
        let name1 = UUID().uuidString
        let age1 = Int(arc4random())
        let creator1 = UUID().uuidString
        let lmt1 = Date().toISO8601()
        let ect1 = Date().toISO8601()
        
        var count = 0
        mockResponse { request in
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            switch urlComponents.path {
            case "/appdata/\(self.client.appKey!)/\(PersonCodable.collectionName())/":
                return HttpResponse(json: [
                    [
                        "_id": id1,
                        "name": name1,
                        "age": age1,
                        "reference" : reference,
                        "_acl": [
                            "creator": creator1
                        ],
                        "_kmd": [
                            "lmt": lmt1,
                            "ect": ect1
                        ]
                    ]
                    ])
            case "/appdata/\(self.client.appKey!)/\(EntityWithRefenceCodable.collectionName())/":
                return HttpResponse(json: [
                    [
                        "_id": id1,
                        "references" : [reference],
                        "_acl": [
                            "creator": creator1
                        ],
                        "_kmd": [
                            "lmt": lmt1,
                            "ect": ect1
                        ]
                    ]
                    ])
            default:
                XCTFail(request.url!.path)
                return HttpResponse(statusCode: 404, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let personStore = try! DataStore<PersonCodable>.collection(.sync)
        let entityWithRefenceStore = try! DataStore<EntityWithRefenceCodable>.collection(.sync)
        let realm = (personStore.cache!.cache as! RealmCache<PersonCodable>).newRealm
        let persons = try! personStore.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
        let entities = try! entityWithRefenceStore.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
        XCTAssertEqual(1, persons.count)
        XCTAssertEqual(1, entities.count)
        XCTAssertEqual(1, personStore.cache!.count(query: nil))
        XCTAssertEqual(1, entityWithRefenceStore.cache!.count(query: nil))
        XCTAssertEqual(1, realm.objects(Reference.self).count)
        
        if let entity = entities.first {
            let count = try! entityWithRefenceStore.remove(entity).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(1, count)
            XCTAssertEqual(1, realm.objects(Reference.self).count)
            XCTAssertEqual(persons.first?.reference?.entityId, referenceId)
            
            let refreshedInstance = try! personStore.find(persons.first!.entityId!).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(refreshedInstance.reference?.entityId, referenceId)
        }
    }
    
    func testCascadeDeleteItemsWithOtherReferencesInAnotherCollection() {
        let referenceId = UUID().uuidString
        let referenceData = try! JSONEncoder().encode(Reference(referenceId))
        let reference = try! JSONSerialization.jsonObject(with: referenceData) as! JsonDictionary
        
        let id1 = UUID().uuidString
        let name1 = UUID().uuidString
        let age1 = Int(arc4random())
        let creator1 = UUID().uuidString
        let lmt1 = Date().toISO8601()
        let ect1 = Date().toISO8601()
        
        var count = 0
        mockResponse { request in
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            switch urlComponents.path {
            case "/appdata/\(self.client.appKey!)/\(PersonCodable.collectionName())/":
                return HttpResponse(json: [
                    [
                        "_id": id1,
                        "name": name1,
                        "age": age1,
                        "reference" : reference,
                        "_acl": [
                            "creator": creator1
                        ],
                        "_kmd": [
                            "lmt": lmt1,
                            "ect": ect1
                        ]
                    ]
                    ])
            case "/appdata/\(self.client.appKey!)/\(EntityWithRefenceCodable.collectionName())/":
                return HttpResponse(json: [
                    [
                        "_id": id1,
                        "reference" : reference,
                        "_acl": [
                            "creator": creator1
                        ],
                        "_kmd": [
                            "lmt": lmt1,
                            "ect": ect1
                        ]
                    ]
                    ])
            default:
                XCTFail(request.url!.path)
                return HttpResponse(statusCode: 404, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let personStore = try! DataStore<PersonCodable>.collection(.sync)
        let entityWithRefenceStore = try! DataStore<EntityWithRefenceCodable>.collection(.sync)
        let realm = (personStore.cache!.cache as! RealmCache<PersonCodable>).newRealm
        let persons = try! personStore.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
        let entities = try! entityWithRefenceStore.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
        XCTAssertEqual(1, persons.count)
        XCTAssertEqual(1, entities.count)
        XCTAssertEqual(1, personStore.cache!.count(query: nil))
        XCTAssertEqual(1, entityWithRefenceStore.cache!.count(query: nil))
        XCTAssertEqual(1, realm.objects(Reference.self).count)
        
        if let person = persons.first {
            let count = try! personStore.remove(person).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(1, count)
            XCTAssertEqual(1, realm.objects(Reference.self).count)
            XCTAssertEqual(entities.first?.reference?.entityId, referenceId)
            
            let refreshedInstance = try! entityWithRefenceStore.find(entities.first!.entityId!).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(refreshedInstance.reference?.entityId, referenceId)
        }
    }
    
    func testTranslateQueryCodable() {
        let store = try! DataStore<PersonCodable>.collection(.sync)
        let id = UUID().uuidString
        
        if useMockData {
            mockResponse { (request) -> HttpResponse in
                let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                XCTAssertEqual(urlComponents.path, "/appdata/\(self.client.appKey!)/\(PersonCodable.collectionName())/")
                return HttpResponse(json: [
                    [
                        "_id" : id,
                        "age" : 0,
                        ]
                    ])
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationPull = expectation(description: "Pull")
        
        let query = Query(format: "_id == %@", id)
        
        store.pull(query) {
            switch $0 {
            case .success(let persons):
                XCTAssertEqual(persons.count, 1)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationPull?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPull = nil
        }
    }
    
}
