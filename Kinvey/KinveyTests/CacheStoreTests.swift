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
        
        store = try! DataStore<Person>.collection(.cache)
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
                case .success(let count):
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
                        "lmt" : Date().toISO8601(),
                        "ect" : Date().toISO8601()
                    ]
                ])
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        store.save(person) {
            switch $0 {
            case .success(let person):
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            switch runCount {
            case 0:
                switch $0 {
                case .success(let person):
                    XCTAssertNotNil(person.personId)
                    if let personId = person.personId {
                        XCTAssertTrue(personId.hasPrefix(ObjectIdTmpPrefix))
                        temporaryObjectId = personId
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationSaveLocal?.fulfill()
            case 1:
                switch $0 {
                case .success(let person):
                    XCTAssertNotNil(person.personId)
                    if let personId = person.personId {
                        XCTAssertFalse(personId.hasPrefix(ObjectIdTmpPrefix))
                        finalObjectId = personId
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
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
            
            store.find(temporaryObjectId, options: try! Options(readPolicy: .forceLocal)) {
                switch $0 {
                case .success(let person):
                    XCTFail("A failure result is expected")
                case .failure(let error):
                    break
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        XCTAssertNotNil(finalObjectId)
        if let finalObjectId = finalObjectId {
            weak var expectationRemove = expectation(description: "Remove")
            
            store.remove(byId: finalObjectId, options: try! Options(writePolicy: .forceLocal)) {
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
    }
    
    func testUpdate() {
        let personId = UUID().uuidString
        let firstName = UUID().uuidString
        let intValue = 1
        let city = "Boston"
        var persons1: [PersonCodable]?
        var persons2: [PersonCodable]?
        let store: DataStore<PersonCodable>
        
        do {
            store = try DataStore<PersonCodable>.collection()
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        XCTContext.runActivity(named: "Find") { (activity) -> Void in
            if useMockData {
                mockResponse(json: [
                    [
                        "_id" : personId,
                        "name" : firstName,
                        "age" : 0,
                        "intValues" : [intValue],
                        "addresses" : [
                            ["city" : city],
                        ],
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
            
            let expectationFind = expectation(description: "Find")
            expectationFind.expectedFulfillmentCount = 2
            
            store.find(options: nil) {
                switch $0 {
                case .success(let persons):
                    if persons1 == nil {
                        XCTAssertEqual(persons.count, 0)
                        persons1 = Array(persons)
                    } else if persons2 == nil {
                        XCTAssertEqual(persons.count, 1)
                        persons2 = Array(persons)
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout)
            
            XCTAssertEqual(persons1?.count, 0)
            XCTAssertEqual(persons2?.count, 1)
            XCTAssertEqual(persons2?.first?.name, firstName)
            XCTAssertEqual(persons2?.first?.intValues.count, 1)
            XCTAssertEqual(persons2?.first?.intValues.first?.value, intValue)
            XCTAssertEqual(persons2?.first?.addresses.count, 1)
            XCTAssertEqual(persons2?.first?.addresses.first?.city, city)
        }
        
        XCTContext.runActivity(named: "Find Local") { (activity) -> Void in
            do {
                let expectationFind = expectation(description: "Find")
                
                store.find(options: try Options(readPolicy: .forceLocal)) {
                    switch $0 {
                    case .success(let persons):
                        XCTAssertEqual(persons.count, 1)
                        persons1 = Array(persons)
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationFind.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout)
                
                XCTAssertEqual(persons1?.count, 1)
                XCTAssertEqual(persons1?.first?.name, firstName)
                XCTAssertEqual(persons1?.first?.intValues.count, 1)
                XCTAssertEqual(persons1?.first?.intValues.first?.value, intValue)
                XCTAssertEqual(persons1?.first?.addresses.count, 1)
                XCTAssertEqual(persons1?.first?.addresses.first?.city, city)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        let secondName = UUID().uuidString
        let int2Value = 2
        let city2 = "New York"
        
        XCTContext.runActivity(named: "Update") { (activity) -> Void in
            if useMockData {
                mockResponse(json: [
                    "_id" : personId,
                    "name" : secondName,
                    "age" : 0,
                    "intValues" : [int2Value, int2Value],
                    "addresses" : [
                        ["city" : city2],
                        ["city" : city2],
                    ],
                    "_acl" : [
                        "creator" : UUID().uuidString
                    ],
                    "_kmd" : [
                        "lmt" : Date().toISO8601(),
                        "ect" : Date().toISO8601()
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            guard let person = persons1?.first else {
                XCTAssertNotNil(persons1?.first)
                return
            }
            XCTAssertEqual(person.personId, personId)
            XCTAssertEqual(person.entityId, personId)
            XCTAssertEqual(person.name, firstName)
            XCTAssertEqual(person.intValues.count, 1)
            person.name = secondName
            person.intValues.first?.value = int2Value
            person.intValues.append(IntValue(int2Value))
            person.addresses.first?.city = city2
            person.addresses.append({
                let address = AddressCodable()
                address.city = city2
                return address
            }())
            
            let expectationSave = expectation(description: "Save")
            expectationSave.expectedFulfillmentCount = 2
            
            store.save(person, options: nil) {
                switch $0 {
                case .success(let person):
                    XCTAssertEqual(person.name, secondName)
                    XCTAssertEqual(person.intValues.count, int2Value)
                    XCTAssertEqual(person.intValues.first?.value, int2Value)
                    XCTAssertEqual(person.intValues.last?.value, int2Value)
                    XCTAssertEqual(person.addresses.count, 2)
                    XCTAssertEqual(person.addresses.first?.city, city2)
                    XCTAssertEqual(person.addresses.last?.city, city2)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationSave.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout)
        }
        
        XCTContext.runActivity(named: "Find Local") { (activity) -> Void in
            do {
                let expectationFind = expectation(description: "Find")
                
                store.find(options: try Options(readPolicy: .forceLocal)) {
                    switch $0 {
                    case .success(let persons):
                        XCTAssertEqual(persons.count, 1)
                        persons1 = Array(persons)
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationFind.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout)
                
                XCTAssertEqual(persons1?.count, 1)
                XCTAssertEqual(persons1?.first?.name, secondName)
                XCTAssertEqual(persons1?.first?.intValues.count, 2)
                XCTAssertEqual(persons1?.first?.intValues.first?.value, int2Value)
                XCTAssertEqual(persons1?.first?.intValues.last?.value, int2Value)
                XCTAssertEqual(persons1?.first?.addresses.count, 2)
                XCTAssertEqual(persons1?.first?.addresses.first?.city, city2)
                XCTAssertEqual(persons1?.first?.addresses.last?.city, city2)
            } catch {
                XCTFail(error.localizedDescription)
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
                            "lmt" : Date().toISO8601(),
                            "ect" : Date().toISO8601()
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
                
                let store = try! DataStore<Book>.collection(.cache)
                store.save(book) {
                    switch $0 {
                    case .success(let book):
                        XCTAssertEqual(book.title, "Swift for the win!")
                        
                        XCTAssertEqual(book.authorNames.count, 1)
                        XCTAssertEqual(book.authorNames.first?.value, "Victor Barros")
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
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
                
                let store = try! DataStore<Book>.collection(.sync)
                store.find {
                    switch $0 {
                    case .success(let books):
                        XCTAssertEqual(books.count, 1)
                        if let book = books.first {
                            XCTAssertEqual(book.title, "Swift for the win!")
                            
                            XCTAssertEqual(book.authorNames.count, 1)
                            XCTAssertEqual(book.authorNames.first?.value, "Victor Barros")
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
                
                let store = try! DataStore<Book>.collection(.sync)
                let query = Query(format: "authorNames contains %@", "Victor Barros")
                store.find(query) {
                    switch $0 {
                    case .success(let books):
                        XCTAssertEqual(books.count, 1)
                        if let book = books.first {
                            XCTAssertEqual(book.title, "Swift for the win!")
                            
                            XCTAssertEqual(book.authorNames.count, 1)
                            XCTAssertEqual(book.authorNames.first?.value, "Victor Barros")
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
                
                let store = try! DataStore<Book>.collection(.sync)
                let query = Query(format: "subquery(authorNames, $authorNames, $authorNames like[c] %@).@count > 0", "Vic*")
                store.find(query) {
                    switch $0 {
                    case .success(let books):
                        XCTAssertEqual(books.count, 1)
                        if let book = books.first {
                            XCTAssertEqual(book.title, "Swift for the win!")
                            
                            XCTAssertEqual(book.authorNames.count, 1)
                            XCTAssertEqual(book.authorNames.first?.value, "Victor Barros")
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
                            "lmt" : Date().toISO8601(),
                            "ect" : Date().toISO8601()
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
            
            let store = try! DataStore<Book>.collection(.cache)
            store.save(book) {
                switch $0 {
                case .success(let book):
                    XCTAssertEqual(book.title, "Swift for the win!")
                    
                    XCTAssertEqual(book.authorNames.count, 1)
                    XCTAssertEqual(book.authorNames.first?.value, "Victor Barros")
                case .failure(let error):
                    XCTFail(error.localizedDescription)
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
            
            let store = try! DataStore<Book>.collection(.cache)
            store.find {
                switch $0 {
                case .success(let books):
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
                case .failure(let error):
                    XCTFail(error.localizedDescription)
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
        let store = try! DataStore<Person>.collection(.cache)
        
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
    func testCacheStoreDeltaset1ExtraItemAddedWithPull() {
        let store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
        var sinceTime = Date().toISO8601()
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
                        sinceTime = Date().toISO8601()
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
                                "X-Kinvey-Request-Start" : sinceTime
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
                        let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
                        let sinceInRequest = urlComponents?.queryItems?.filter { $0.name == "since" }.first?.value
                        XCTAssert(sinceTime == sinceInRequest)
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
    //Create 1 person, Make regular GET,Make deltaset request
    func testCacheStoreDeltasetSinceIsRespectedWithoutChangesWithPull() {
        let store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
        
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
    func testCacheStoreDeltaset1ItemAdded1Updated1DeletedWithPull() {
        let store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
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
    func testCacheStoreDeltaset1WithQuery1ItemDeletedWithPull() {
        let store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
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
    func testCacheStoreDeltasetWithQuery1ItemUpdatedWithPull() {
        let store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
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
    func testCacheStoreDeltasetTurnedOffSendsRegularGETWithPull() {
        var store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
        
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
        store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: false))
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
    
    func testCacheStoreDisabledDeltasetWithSync() {
        let store = try! DataStore<Person>.collection(.cache)
        
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

    func testCacheStoreDeltaset1ExtraItemAddedWithSync() {
        let store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
        
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
 
    func testCacheStoreDeltasetSinceIsRespectedWithoutChangesWithSync() {
        let store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
        
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

    func testCacheStoreDeltaset1ItemAdded1Updated1DeletedWithSync() {
        let store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
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
    
    func testCacheStoreDeltaset1WithQuery1ItemDeletedWithSync() {
        let store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
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

    func testCacheStoreDeltasetWithQuery1ItemUpdatedWithSync() {
        let store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
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

    func testCacheStoreDeltasetTurnedOffSendsRegularGETWithSync() {
        var store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
        
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
        store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: false))
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
    func testCacheStoreDisabledDeltasetWithFind() {
        let store = try! DataStore<Person>.collection(.cache)
        
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
            
            weak var expectationFind = expectation(description: "Find")
            let query = Query()
            var options = try! Options()
            options.readPolicy = .forceNetwork
            store.find(query, options: options) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success(let persons):
                    XCTAssertNotNil(persons)
                    
                    XCTAssertEqual(Int64(persons.count), initialCount + 1)
                    
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
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
            
            weak var expectationFind = expectation(description: "Find")
            let query = Query()
            var options = try! Options()
            options.readPolicy = .forceNetwork
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

    func testCacheStoreDeltaset1ExtraItemAddedWithFind() {
        let store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
        
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
            
            weak var expectationFind = expectation(description: "Find")
            var options = try! Options()
            options.readPolicy = .forceNetwork
            var query = Query()
            store.find(query, options: options) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success(let persons):
                    XCTAssertNotNil(persons)
                    
                    XCTAssertEqual(persons.count, initialCount + 1)
                    
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
            weak var expectationFind = expectation(description: "Find")
            var options = try! Options()
            options.readPolicy = .forceNetwork
            let query = Query()
            store.find(query, options: options) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success(let persons):
                    XCTAssertNotNil(persons)
                    
                    XCTAssertEqual(persons.count, initialCount + 2)
                    
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
    }

    func testCacheStoreDeltasetSinceIsRespectedWithoutChangesWithFind() {
        let store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
        
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

    func testCacheStoreDeltaset1ItemAdded1Updated1DeletedWithFind() {
        let store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
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

    func testCacheStoreDeltaset1WithQuery1ItemDeletedWithFind() {
        let store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
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
    
    func testCacheStoreDeltasetWithQuery1ItemUpdatedWithFind() {
        let store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
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
                        XCTAssertEqual(person.name, "Victor C Barros")
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
    }

    func testCacheStoreDeltasetTurnedOffSendsRegularGETWithFind() {
        var store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
        
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
        store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: false))
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
    }
    
    //Create 1 item, pull with regular GET, create another item, deltaset returns 1 changed, switch off deltaset, pull with regular GET
    func testCacheStoreFindByIdNotUsingDeltaset() {
        var store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
        var idToFind = ""
        var initialCount = 0
        var readPolicy = ReadPolicy.forceNetwork
        do {
            if !useMockData {
                initialCount = try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value()
            }
        }
        
        do {
            if useMockData {
                idToFind = "58450d87f29e22207c83a236"
                mockResponse { (request) -> HttpResponse in
                    guard let url = request.url else {
                        XCTAssertNotNil(request.url)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    switch url.path {
                    case "/appdata/_kid_/\(Person.collectionName())/\(idToFind)":
                        let json = [
                            "_id": idToFind,
                            "name": "Victor Barros",
                            "_acl": [
                                "creator": "58450d87c077970e38a388ba"
                            ],
                            "_kmd": [
                                "lmt": "2016-12-05T06:47:35.711Z",
                                "ect": "2016-12-05T06:47:35.711Z"
                            ]
                        ] as JsonDictionary
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
                idToFind = person.personId!
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(idToFind, options: try! Options(readPolicy: readPolicy)) {
                self.assertThread()
                
                switch $0 {
                case .success(let result):
                    XCTAssertEqual(result.personId, idToFind)
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
                    case "/appdata/_kid_/\(Person.collectionName())/\(idToFind)":
                        return HttpResponse(
                            headerFields: [
                                "X-Kinvey-Request-Start" : Date().toISO8601()
                            ],
                            json: [
                                "_id": idToFind,
                                "name": "Victor Hugo",
                                "_acl": [
                                    "creator": "58450d87c077970e38a388ba"
                                ],
                                "_kmd": [
                                    "lmt": "2016-12-05T06:47:35.711Z",
                                    "ect": "2016-12-05T06:47:35.711Z"
                                ]
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
            weak var expectationFind = expectation(description: "Find")
            
            store.find(idToFind, options: try! Options(readPolicy: readPolicy)) {
                self.assertThread()
                
                switch $0 {
                case .success(let result):
                    XCTAssertEqual(result.personId, idToFind)
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

}
