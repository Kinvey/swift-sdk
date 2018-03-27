//
//  CachedStoreTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-15.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey
import RealmSwift

class CacheStoreTests: StoreTestCase {
    
    override func setUp() {
        super.setUp()
        
        signUp()
        
        store = DataStore<Person>.collection(.cache)
    }
    
    var mockCount = 0
    
    override func tearDown() {
        if let activeUser = client.activeUser {
            let store = DataStore<Person>.collection(.network)
            let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
            
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
            
            store.remove(query) { (count, error) -> Void in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                expectationRemoveAll?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationRemoveAll = nil
            }
        }
        
        super.tearDown()
    }
    
    func testSaveAddress() {
        let person = Person()
        person.name = "Victor Barros"
        
        weak var expectationSaveLocal = expectation(description: "Save Local")
        weak var expectationSaveNetwork = expectation(description: "Save Network")
        
        var runCount = 0
        var temporaryObjectId: String? = nil
        var finalObjectId: String? = nil
        
        if useMockData {
            mockResponse {
                let json = try! JSONSerialization.jsonObject(with: $0) as? JsonDictionary
                return HttpResponse(statusCode: 201, json: [
                    "_id" : json?["_id"] as? String ?? UUID().uuidString,
                    "name" : "Victor Barros",
                    "age" : 0,
                    "_acl" : [
                        "creator" : UUID().uuidString
                    ],
                    "_kmd" : [
                        "lmt" : Date().toString(),
                        "ect" : Date().toString()
                    ]
                ])
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        store.save(person) { person, error in
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            switch runCount {
            case 0:
                if let person = person {
                    XCTAssertNotNil(person.personId)
                    if let personId = person.personId {
                        XCTAssertTrue(personId.hasPrefix(ObjectIdTmpPrefix))
                        temporaryObjectId = personId
                    }
                }
                
                expectationSaveLocal?.fulfill()
            case 1:
                if let person = person {
                    XCTAssertNotNil(person.personId)
                    if let personId = person.personId {
                        XCTAssertFalse(personId.hasPrefix(ObjectIdTmpPrefix))
                        finalObjectId = personId
                    }
                }
                
                expectationSaveNetwork?.fulfill()
            default:
                break
            }
            
            runCount += 1
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSaveLocal = nil
            expectationSaveNetwork = nil
        }
        
        XCTAssertEqual(store.syncCount(), 0)
        
        XCTAssertNotNil(temporaryObjectId)
        if let temporaryObjectId = temporaryObjectId {
            weak var expectationFind = expectation(description: "Find")
            
            store.find(byId: temporaryObjectId, readPolicy: .forceLocal) { (person, error) in
                XCTAssertNil(person)
                XCTAssertNotNil(error)
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        XCTAssertNotNil(finalObjectId)
        if let finalObjectId = finalObjectId {
            weak var expectationRemove = expectation(description: "Remove")
            
            store.removeById(finalObjectId, writePolicy: .forceLocal) { (count, error) in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                XCTAssertEqual(count, 1)
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRemove = nil
            }
        }
    }
    
    func testArrayProperty() {
        let book = Book()
        book.title = "Swift for the win!"
        book.authorNames.append("Victor Barros")
        
        do {
            if useMockData {
                mockResponse(completionHandler: { request in
                    var json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
                    json += [
                        "_id" : UUID().uuidString,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : [
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
                        ]
                    ]
                    return HttpResponse(json: json)
                })
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            do {
                weak var expectationSaveNetwork = expectation(description: "Save Network")
                weak var expectationSaveLocal = expectation(description: "Save Local")
                
                let store = DataStore<Book>.collection(.cache)
                store.save(book) { book, error in
                    XCTAssertNotNil(book)
                    XCTAssertNil(error)
                    
                    if let book = book {
                        XCTAssertEqual(book.title, "Swift for the win!")
                        
                        XCTAssertEqual(book.authorNames.count, 1)
                        XCTAssertEqual(book.authorNames.first?.value, "Victor Barros")
                    }
                    
                    if expectationSaveLocal != nil {
                        expectationSaveLocal?.fulfill()
                        expectationSaveLocal = nil
                    } else {
                        expectationSaveNetwork?.fulfill()
                    }
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationSaveNetwork = nil
                    expectationSaveLocal = nil
                }
            }
            
            do {
                weak var expectationFind = expectation(description: "Find")
                
                let store = DataStore<Book>.collection(.sync)
                store.find { books, error in
                    XCTAssertNotNil(books)
                    XCTAssertNil(error)
                    
                    if let books = books {
                        XCTAssertEqual(books.count, 1)
                        if let book = books.first {
                            XCTAssertEqual(book.title, "Swift for the win!")
                            
                            XCTAssertEqual(book.authorNames.count, 1)
                            XCTAssertEqual(book.authorNames.first?.value, "Victor Barros")
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
                
                let store = DataStore<Book>.collection(.sync)
                let query = Query(format: "authorNames contains %@", "Victor Barros")
                store.find(query) { books, error in
                    XCTAssertNotNil(books)
                    XCTAssertNil(error)
                    
                    if let books = books {
                        XCTAssertEqual(books.count, 1)
                        if let book = books.first {
                            XCTAssertEqual(book.title, "Swift for the win!")
                            
                            XCTAssertEqual(book.authorNames.count, 1)
                            XCTAssertEqual(book.authorNames.first?.value, "Victor Barros")
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
                
                let store = DataStore<Book>.collection(.sync)
                let query = Query(format: "subquery(authorNames, $authorNames, $authorNames like[c] %@).@count > 0", "Vic*")
                store.find(query) { books, error in
                    XCTAssertNotNil(books)
                    XCTAssertNil(error)
                    
                    if let books = books {
                        XCTAssertEqual(books.count, 1)
                        if let book = books.first {
                            XCTAssertEqual(book.title, "Swift for the win!")
                            
                            XCTAssertEqual(book.authorNames.count, 1)
                            XCTAssertEqual(book.authorNames.first?.value, "Victor Barros")
                        }
                    }
                    
                    expectationFind?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationFind = nil
                }
            }
        }
    }
    
    func testFindCache() {
        let book = Book()
        book.title = "Swift for the win!"
        book.authorNames.append("Victor Barros")
        
        let book1stEdition = BookEdition()
        book1stEdition.year = 2017
        book.editions.append(book1stEdition)
        
        let book2ndEdition = BookEdition()
        book2ndEdition.year = 2016
        book.editions.append(book2ndEdition)
        
        if useMockData {
            var mockJson: JsonDictionary? = nil
            var count = 0
            mockResponse { request in
                defer {
                    count += 1
                }
                switch count {
                case 0:
                    var json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
                    json += [
                        "_id" : UUID().uuidString,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : [
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
                        ]
                    ]
                    mockJson = json
                    return HttpResponse(json: json)
                case 1:
                    return HttpResponse(json: [mockJson!])
                default:
                    Swift.fatalError()
                }
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        do {
            weak var expectationSaveNetwork = expectation(description: "Save Network")
            weak var expectationSaveLocal = expectation(description: "Save Local")
            
            let store = DataStore<Book>.collection(.cache)
            store.save(book) { book, error in
                XCTAssertNotNil(book)
                XCTAssertNil(error)
                
                if let book = book {
                    XCTAssertEqual(book.title, "Swift for the win!")
                    
                    XCTAssertEqual(book.authorNames.count, 1)
                    XCTAssertEqual(book.authorNames.first?.value, "Victor Barros")
                }
                
                if expectationSaveLocal != nil {
                    expectationSaveLocal?.fulfill()
                    expectationSaveLocal = nil
                } else {
                    expectationSaveNetwork?.fulfill()
                }
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSaveNetwork = nil
                expectationSaveLocal = nil
            }
        }
        
        do {
            weak var expectationFindLocal = expectation(description: "Save Local")
            weak var expectationFindNetwork = expectation(description: "Save Network")
            
            let store = DataStore<Book>.collection(.cache)
            store.find { books, error in
                XCTAssertNotNil(books)
                XCTAssertNil(error)
                
                if let books = books {
                    if expectationFindLocal != nil {
                        expectationFindLocal?.fulfill()
                        expectationFindLocal = nil
                    } else {
                        expectationFindNetwork?.fulfill()
                    }
                    
                    XCTAssertEqual(books.count, 1)
                    if let book = books.first {
                        XCTAssertEqual(book.title, "Swift for the win!")
                        
                        XCTAssertEqual(book.authorNames.count, 1)
                        XCTAssertEqual(book.authorNames.first?.value, "Victor Barros")
                    }
                }
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFindLocal = nil
                expectationFindNetwork = nil
            }
        }
        
        do {
            let basePath = Kinvey.cacheBasePath
            var url = URL(fileURLWithPath: basePath)
            url = url.appendingPathComponent(sharedClient.appKey!)
            url = url.appendingPathComponent("kinvey.realm")
            let realm = try! Realm(fileURL: url)
            XCTAssertEqual(realm.objects(Acl.self).count, 1)
            XCTAssertEqual(realm.objects(StringValue.self).count, 1)
            XCTAssertEqual(realm.objects(BookEdition.self).count, 2)
        }
    }
    
    //Create 1 person, Make regular GET, Create 1 more person, Make regular GET
    func testCacheStoreDisabledDeltasetWithPull() {
        let store = DataStore<Person>.collection(.cache)
        
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    func testCacheStoreDeltaset1ExtraItemAddedWithPull() {
        let store = DataStore<Person>.collection(.cache, deltaSet: true)
        
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    //Create 1 person, Make regular GET,Make deltaset request
    func testCacheStoreDeltasetSinceIsRespectedWithoutChangesWithPull() {
        let store = DataStore<Person>.collection(.cache, deltaSet: true)
        
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    func testCacheStoreDeltaset1ItemAdded1Updated1DeletedWithPull() {
        let store = DataStore<Person>.collection(.cache, deltaSet: true)
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    func testCacheStoreDeltaset1WithQuery1ItemDeletedWithPull() {
        let store = DataStore<Person>.collection(.cache, deltaSet: true)
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    func testCacheStoreDeltasetWithQuery1ItemUpdatedWithPull() {
        let store = DataStore<Person>.collection(.cache, deltaSet: true)
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    func testCacheStoreDeltasetTurnedOffSendsRegularGETWithPull() {
        var store = DataStore<Person>.collection(.cache, deltaSet: true)
        
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
        store = DataStore<Person>.collection(.cache, deltaSet: false)
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    
    //Create 1 person, Make regular GET, Create 1 more person, Make regular GET
    func testCacheStoreDisabledDeltasetWithSync() {
        let store = DataStore<Person>.collection(.cache)
        
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    //Create 1 person, Make regular GET,Make deltaset request
    func testCacheStoreDeltaset1ExtraItemAddedWithSync() {
        let store = DataStore<Person>.collection(.cache, deltaSet: true)
        
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    //Create 1 person, Make regular GET, Make deltaset request
    func testCacheStoreDeltasetSinceIsRespectedWithoutChangesWithSync() {
        let store = DataStore<Person>.collection(.cache, deltaSet: true)
        
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    //Create 2 persons, pull with regular GET, update 1, deltaset returning 1 changed, delete 1, deltaset returning 1 deleted
    func testCacheStoreDeltaset1ItemAdded1Updated1DeletedWithSync() {
        let store = DataStore<Person>.collection(.cache, deltaSet: true)
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    
    //Created 3 items, 2 of which satisfy a query, pull with query with regular GET, delete 1 item that satisfies the query, deltaset returns 1 deleted item
    func testCacheStoreDeltaset1WithQuery1ItemDeletedWithSync() {
        let store = DataStore<Person>.collection(.cache, deltaSet: true)
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    //Created 3 items, 2 of which satisfy a query, pull with query with regular GET, update 1 item that satisfies the query, deltaset returns 1 changed item
    func testCacheStoreDeltasetWithQuery1ItemUpdatedWithSync() {
        let store = DataStore<Person>.collection(.cache, deltaSet: true)
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    //Create 1 item, pull with regular GET, create another item, deltaset returns 1 changed, switch off deltaset, pull with regular GET
    func testCacheStoreDeltasetTurnedOffSendsRegularGETWithSync() {
        var store = DataStore<Person>.collection(.cache, deltaSet: true)
        
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
        store = DataStore<Person>.collection(.cache, deltaSet: false)
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    func testCacheStoreDisabledDeltasetWithFind() {
        let store = DataStore<Person>.collection(.cache)
        
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find() { results, error in
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
            
            store.find() { results, error in
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
    func testCacheStoreDeltaset1ExtraItemAddedWithFind() {
        let store = DataStore<Person>.collection(.sync, options: Options(deltaSet: true))
        
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
            
            store.find(options: Options(readPolicy: .forceNetwork)) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                self.assertThread()
                
                switch result {
                case .success(let results):
                    XCTAssertEqual(results.count, initialCount + 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertNotNil(cacheCount)
                    if let cacheCount = cacheCount {
                        XCTAssertEqual(Int64(cacheCount), results.count)
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
            
            store.find(options: Options(readPolicy: .forceNetwork)) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                self.assertThread()
                
                switch result {
                case .success(let results):
                    XCTAssertEqual(results.count, initialCount + 2)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    if let secondPerson = results.last {
                        XCTAssertEqual(secondPerson.name, "Victor Hugo")
                    }
                    
                    let cacheCount = self.store.cache?.count(query: nil)
                    XCTAssertNotNil(cacheCount)
                    if let cacheCount = cacheCount {
                        XCTAssertEqual(Int64(cacheCount), results.count)
                    }
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
    //Create 1 person, Make regular GET,Make deltaset request
    func testCacheStoreDeltasetSinceIsRespectedWithoutChangesWithFind() {
        let store = DataStore<Person>.collection(.cache, deltaSet: true)
        
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    func testCacheStoreDeltaset1ItemAdded1Updated1DeletedWithFind() {
        let store = DataStore<Person>.collection(.cache, deltaSet: true)
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    func testCacheStoreDeltaset1WithQuery1ItemDeletedWithFind() {
        let store = DataStore<Person>.collection(.cache, deltaSet: true)
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    func testCacheStoreDeltasetWithQuery1ItemUpdatedWithFind() {
        let store = DataStore<Person>.collection(.cache, deltaSet: true)
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
    func testCacheStoreDeltasetTurnedOffSendsRegularGETWithFind() {
        var store = DataStore<Person>.collection(.cache, deltaSet: true)
        
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
        store = DataStore<Person>.collection(.cache, deltaSet: false)
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
                                "X-Kinvey-Request-Start" : Date().toString()
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
}
