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

class SyncStoreTests: StoreTestCase {
    
    class CheckForNetworkURLProtocol: URLProtocol {
        
        override class func canInit(with request: URLRequest) -> Bool {
            XCTFail()
            return false
        }
        
    }
    
    override func setUp() {
        super.setUp()
        
        signUp()
        
        store = DataStore<Person>.collection(.sync)
    }
    
    func testCreate() {
        let person = self.person
        
        weak var expectationCreate = expectation(description: "Create")
        
        store.save(person) { (person, error) -> Void in
            self.assertThread()
            XCTAssertNotNil(person)
            XCTAssertNil(error)
        
            if let person = person {
                XCTAssertNotNil(person.personId)
                XCTAssertNotEqual(person.personId, "")
        
                XCTAssertNotNil(person.age)
                XCTAssertEqual(person.age, 29)
            }
        
            expectationCreate?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCreate = nil
        }
    }
    
    func testUpdate() {
        save()
        
        weak var expectationFind = expectation(description: "Create")
        
        var savedPerson:Person?
        
        store.find() { (persons, error) -> Void in
            self.assertThread()
            XCTAssertNotNil(persons)
            XCTAssertGreaterThan(persons!.count, 0)
            XCTAssertNil(error)
            
            if let person = persons?.first {
                savedPerson = person
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }

        weak var expectationUpdate = expectation(description: "Update")
        
        savedPerson?.age = 30
        
        store.save(savedPerson!) { (person, error) -> Void in
            self.assertThread()
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            if let person = person {
                XCTAssertNotNil(person.personId)
                XCTAssertNotEqual(person.personId, "")
                
                XCTAssertNotNil(person.age)
                XCTAssertEqual(person.age, 30)
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
        
        store = DataStore<Person>.collection(.sync, tag: tag)
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
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
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
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
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
            
            store.save(person) { person, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRemove = nil
            }
        }
        if let person = persons.last {
            weak var expectationRemove = expectation(description: "Remove")
            
            store.remove(byId: person.entityId!) { count, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                XCTAssertEqual(count, 1)
                
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
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
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
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
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
            
            store.save(person) { person, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRemove = nil
            }
        }
        if let person = persons.last {
            weak var expectationRemove = expectation(description: "Remove")
            
            store.remove(byId: person.entityId!) { count, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                XCTAssertEqual(count, 1)
                
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
        
        store = DataStore<Person>.collection(.network)
        
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
                    XCTFail()
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
        person.age = person.age + 1
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
    
    func testSync() {
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
                    json[PersistableIdKey] = UUID().uuidString
                    json[PersistableAclKey] = [
                        Acl.Key.creator : self.client.activeUser!.userId
                    ]
                    json[PersistableMetadataKey] = [
                        Metadata.LmtKey : Date().toString(),
                        Metadata.EctKey : Date().toString()
                    ]
                    personMockJson = json
                    return HttpResponse(statusCode: 201, json: json)
                case 1:
                    XCTAssertEqual(request.httpMethod, "GET")
                    XCTAssertNotNil(personMockJson)
                    return HttpResponse(statusCode: 200, json: [personMockJson!])
                default:
                    Swift.fatalError()
                }
            }
        }
        defer {
            if useMockData { setURLProtocol(nil) }
        }
        
        weak var expectationSync = expectation(description: "Sync")
        
        store.sync() { count, results, error in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let count = count {
                XCTAssertEqual(Int(count), 1)
            }
            
            expectationSync?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSync = nil
        }

        XCTAssertEqual(store.syncCount(), 0)
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
                    json[PersistableIdKey] = UUID().uuidString
                    json[PersistableAclKey] = [
                        Acl.Key.creator : self.client.activeUser!.userId
                    ]
                    json[PersistableMetadataKey] = [
                        Metadata.LmtKey : Date().toString(),
                        Metadata.EctKey : Date().toString()
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
        
        store = DataStore<Person>.collection(.network)
        
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
                        XCTFail()
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
        
        let bookDataStore = DataStore<Book>.collection(.sync)
        
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
                json[PersistableIdKey] = UUID().uuidString
                json[PersistableAclKey] = [
                    Acl.Key.creator : self.client.activeUser!.userId
                ]
                json[PersistableMetadataKey] = [
                    Metadata.LmtKey : Date().toString(),
                    Metadata.EctKey : Date().toString()
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
    
    func testPushError401EmptyBody() {
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
        
        XCTAssertEqual(store.syncCount(), 1)
    }
    
    func testPushInvalidDataStoreType() {
        save()
        
        store = DataStore<Person>.collection(.network)
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
                        XCTFail()
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
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            weak var expectationPull = expectation(description: "Pull")
            
            store.find() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 1)
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
            
            store.find() { results, error in
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
            
            store.find() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 1)
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
        
        store.pull() { results, error in
            self.assertThread()
            XCTAssertNil(results)
            XCTAssertNotNil(error)
            
            expectationPull?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPull = nil
        }
        
    }
    func testPullInvalidDataStoreType() {
        //save()
        
        store = DataStore<Person>.collection(.network)
        
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
        
        store.find(personId) { result, error in
            self.assertThread()
            XCTAssertNotNil(result)
            XCTAssertNil(error)
            
            if let result = result {
                XCTAssertEqual(result.personId, personId)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
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
        
        store.find(query) { results, error in
            self.assertThread()
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertNotNil(results.first)
                if let result = results.first {
                    XCTAssertEqual(result.personId, personId)
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
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
            try store.remove(person) { count, error in
                self.assertThread()
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                if let count = count {
                    XCTAssertEqual(count, 1)
                }
                
                expectationRemove?.fulfill()
            }
        } catch {
            XCTFail()
            expectationRemove?.fulfill()
        }
            
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
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
            try store.remove(person) { count, error in
                XCTFail()
                
                expectationRemove?.fulfill()
            }
            XCTFail()
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
        
        store.remove([person1, person2]) { count, error in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            
            if let count = count {
                XCTAssertEqual(count, 2)
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
        
        store.removeAll() { count, error in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            
            if let count = count {
                XCTAssertEqual(count, 2)
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
            store.find(query, readPolicy: .forceLocal) { (persons, error) -> Void in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 0)
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
            store.find(query, readPolicy: .forceLocal) { (persons, error) -> Void in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 1)
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
            
            self.store.save(person, writePolicy: .forceLocal) { person, error in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
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
            
            store.find(query, readPolicy: .forceLocal) { results, error in
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
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            let query = Query {
                $0.limit = 5
                $0.ascending("name")
            }
            
            store.find(query, readPolicy: .forceLocal) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 5)
                    
                    XCTAssertNotNil(results.first)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Person 0")
                    }
                    
                    XCTAssertNotNil(results.last)
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Person 4")
                    }
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
            
            store.find(query, readPolicy: .forceLocal) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 5)
                    
                    XCTAssertNotNil(results.first)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Person 5")
                    }
                    
                    XCTAssertNotNil(results.last)
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Person 9")
                    }
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
            
            store.find(query, readPolicy: .forceLocal) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 4)
                    
                    XCTAssertNotNil(results.first)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Person 6")
                    }
                    
                    XCTAssertNotNil(results.last)
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Person 9")
                    }
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
            
            store.find(query, readPolicy: .forceLocal) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 0)
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
            
            store.find(query, readPolicy: .forceLocal) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 0)
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
            store.save(person) { (person, error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let person = person {
                    personsArray.append(person)
                    XCTAssertEqual(person.name, "Person 1")
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
            store.save(person) { (person, error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let person = person {
                    personsArray.append(person)
                    XCTAssertEqual(person.name, "Person 2")
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
            store.save(person) { (person, error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let person = person {
                    personsArray.append(person)
                    XCTAssertEqual(person.name, "Person 3")
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
            
            store.save(personsArray[0]) { (person, error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let person = person {
                    personsArray[0] = person
                    XCTAssertEqual(person.name, "Person 1 (Renamed)")
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
            
            store.remove(byId: personsArray[2].personId!) { (count, error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                XCTAssertEqual(count, 1)
                if count == 1 {
                    personsArray.remove(at: 2)
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
            store.save(person) { (person, error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let person = person {
                    personsArray.append(person)
                    XCTAssertEqual(person.name, "Person 3")
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
                        "lmt" : Date().toString(),
                        "ect" : Date().toString()
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
                
                store.remove(query) { (count, error) -> Void in
                    XCTAssertTrue(Thread.isMainThread)
                    XCTAssertNotNil(count)
                    XCTAssertNil(error)
                    
                    XCTAssertEqual(count, 3)
                    
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
            
            store.find(query, readPolicy: .forceNetwork) { (persons, error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
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
        
        store.find(query) { persons, error in
            XCTAssertNotNil(persons)
            XCTAssertNil(error)
            
            XCTAssertEqual(persons?.count, 0)
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testRealmCacheNotEntity() {
        class NotEntityPersistable: NSObject, Persistable {
            
            static func collectionName() -> String {
                return "NotEntityPersistable"
            }
            
            required override init() {
            }
            
            required init?(map: Map) {
            }
            
            func mapping(map: Map) {
            }
            
        }
        
        expect { () -> Void in
            let _ = RealmCache<NotEntityPersistable>(persistenceId: UUID().uuidString, schemaVersion: 0)
        }.to(throwAssertion())
    }
    
    func testRealmSyncNotEntity() {
        class NotEntityPersistable: NSObject, Persistable {
            
            static func collectionName() -> String {
                return "NotEntityPersistable"
            }
            
            required override init() {
            }
            
            required init?(map: Map) {
            }
            
            func mapping(map: Map) {
            }
            
        }
        
        expect { () -> Void in
            let _ = RealmSync<NotEntityPersistable>(persistenceId: UUID().uuidString, schemaVersion: 0)
        }.to(throwAssertion())
    }
    
    func testCancelLocalRequest() {
        let query = Query(format: "propertyNotMapped == %@", 10)
        
        weak var expectationFind = expectation(description: "Find")
        
        let request = store.find(query) { persons, error in
            XCTAssertNotNil(persons)
            XCTAssertNil(error)
            
            XCTAssertEqual(persons?.count, 0)
            
            expectationFind?.fulfill()
            expectationFind = nil
        }
        request.cancel()
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testNewTypeDataStore() {
        var store = DataStore<Person>.getInstance()
        store = store.collection(newType: Book.self).collection(newType: Person.self)
    }
    
}
