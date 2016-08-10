//
//  DeltaSetCacheTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class DeltaSetCacheTestCase: KinveyTestCase {
    
    override func tearDown() {
        if let activeUser = client.activeUser {
            let store = DataStore<Person>.collection(.Network)
            let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
            
            weak var expectationRemoveAll = expectationWithDescription("Remove All")
            
            store.remove(query) { (count, error) -> Void in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                expectationRemoveAll?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationRemoveAll = nil
            }
        }
        
        super.tearDown()
    }
    
    func testComputeDelta() {
        let date = NSDate()
        let cache = MemoryCache<Person>()
        do {
            let person = Person()
            person.personId = "update"
            person.metadata = Metadata(JSON: [Metadata.LmtKey : date.toString()])
            cache.saveEntity(person)
        }
        do {
            let person = Person()
            person.personId = "noChange"
            person.metadata = Metadata(JSON: [Metadata.LmtKey : date.toString()])
            cache.saveEntity(person)
        }
        do {
            let person = Person()
            person.personId = "delete"
            person.metadata = Metadata(JSON: [Metadata.LmtKey : date.toString()])
            cache.saveEntity(person)
        }
        let operation = Operation<Person>(cache: cache, client: client)
        let query = Query()
        let refObjs: [JsonDictionary] = [
            [
                PersistableIdKey : "create",
                PersistableMetadataKey : [
                    Metadata.LmtKey : date.toString(),
                ]
            ],
            [
                PersistableIdKey : "update",
                PersistableMetadataKey : [
                    Metadata.LmtKey : NSDate(timeInterval: 1, sinceDate: date).toString()
                ]
            ],
            [
                PersistableIdKey : "noChange",
                PersistableMetadataKey : [
                    Metadata.LmtKey : date.toString()
                ]
            ]
        ]
        
        let idsLmts = operation.reduceToIdsLmts(refObjs)
        let deltaSet = operation.computeDeltaSet(query, refObjs: idsLmts)
        
        XCTAssertEqual(deltaSet.created.count, 1)
        XCTAssertEqual(deltaSet.created.first, "create")
        
        XCTAssertEqual(deltaSet.updated.count, 1)
        XCTAssertEqual(deltaSet.updated.first, "update")
        
        XCTAssertEqual(deltaSet.deleted.count, 1)
        XCTAssertEqual(deltaSet.deleted.first, "delete")
    }
    
    func testCreate() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        guard let activeUser = client.activeUser else {
            return
        }
        
        let store = DataStore<Person>.collection()
        
        let person = Person()
        person.name = "Victor"
        
        do {
            weak var expectationSave = expectationWithDescription("Save")
            
            store.save(person) { (person, error) -> Void in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                expectationSave?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationSave = nil
            }
        }
        
        XCTAssertNotNil(person.personId)
        
        do {
            let person = Person()
            person.name = "Victor Barros"
            
            weak var expectationCreate = expectationWithDescription("Create")
            
            let createOperation = SaveOperation(persistable: person, writePolicy: .ForceNetwork, client: client)
            createOperation.execute { (results, error) -> Void in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                expectationCreate?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationCreate = nil
            }
        }
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = expectationWithDescription("Read")
            
            store.find(query, readPolicy: .ForceLocal) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 1)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor")
                    }
                }
                
                expectationRead?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationRead = nil
            }
        }
        
        do {
            weak var expectationFind = expectationWithDescription("Find")
            
            store.find(query, readPolicy: .ForceNetwork) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 2)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor")
                    }
                    if let person = persons.last {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationFind = nil
            }
        }
    }
    
    func testUpdate() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        guard let activeUser = client.activeUser else {
            return
        }
        
        let store = DataStore<Person>.collection()
        
        let person = Person()
        person.name = "Victor"
        
        do {
            weak var expectationSave = expectationWithDescription("Save")
            
            store.save(person) { (person, error) -> Void in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                expectationSave?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationSave = nil
            }
        }
        
        XCTAssertNotNil(person.personId)
        guard let personId = person.personId else {
            return
        }
        
        do {
            let person = Person()
            person.personId = personId
            person.name = "Victor Barros"
            
            weak var expectationUpdate = expectationWithDescription("Update")
            
            let updateOperation = SaveOperation(persistable: person, writePolicy: .ForceNetwork, client: client)
            updateOperation.execute { (results, error) -> Void in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                expectationUpdate?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationUpdate = nil
            }
        }
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = expectationWithDescription("Read")
            
            store.find(query, readPolicy: .ForceLocal) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 1)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor")
                    }
                }
                
                expectationRead?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationRead = nil
            }
        }
        
        do {
            weak var expectationFind = expectationWithDescription("Find")
            
            store.find(query, readPolicy: .ForceNetwork) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 1)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationFind = nil
            }
        }
    }
    
    func testDelete() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        guard let activeUser = client.activeUser else {
            return
        }
        
        let store = DataStore<Person>.collection()
        
        let person = Person()
        person.name = "Victor"
        
        do {
            weak var expectationSave = expectationWithDescription("Save")
            
            store.save(person) { (person, error) -> Void in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                expectationSave?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationSave = nil
            }
        }
        
        XCTAssertNotNil(person.personId)
        guard let personId = person.personId else {
            return
        }
        
        do {
            weak var expectationDelete = expectationWithDescription("Delete")
            
            let query = Query(format: "personId == %@", personId)
            query.persistableType = Person.self
            let createRemove = RemoveByQueryOperation<Person>(query: query, writePolicy: .ForceNetwork, client: client)
            createRemove.execute { (count, error) -> Void in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                XCTAssertEqual(count, 1)
                
                expectationDelete?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationDelete = nil
            }
        }
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = expectationWithDescription("Read")
            
            store.find(query, readPolicy: .ForceLocal) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 1)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor")
                    }
                }
                
                expectationRead?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationRead = nil
            }
        }
        
        do {
            weak var expectationFind = expectationWithDescription("Find")
            
            store.find(query, readPolicy: .ForceNetwork) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 0)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationFind = nil
            }
        }
    }
    
    func testPull() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        guard let activeUser = client.activeUser else {
            return
        }
        
        let save: (Int) -> Void = { i in
            let person = Person()
            person.name = String(format: "Person %02d", i)
            
            weak var expectationCreate = self.expectationWithDescription("Create")
            
            let createOperation = SaveOperation(persistable: person, writePolicy: .ForceNetwork, client: self.client)
            createOperation.execute { (results, error) -> Void in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                expectationCreate?.fulfill()
            }
            
            self.waitForExpectationsWithTimeout(self.defaultTimeout) { (error) -> Void in
                expectationCreate = nil
            }
        }
        
        let saveAndCache: (Int) -> Void = { i in
            let person = Person()
            person.name = String(format: "Person Cached %02d", i)
            let store = DataStore<Person>.collection()
            
            weak var expectationSave = self.expectationWithDescription("Save")
            
            store.save(person, writePolicy: .ForceNetwork) { (person, error) -> Void in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                expectationSave?.fulfill()
            }
            
            self.waitForExpectationsWithTimeout(self.defaultTimeout) { (error) -> Void in
                expectationSave = nil
            }
        }
        
        for i in 1...10 {
            save(i)
        }
        
        for i in 1...5 {
            saveAndCache(i)
        }
        
        let store = DataStore<Person>.collection(.Sync)
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = expectationWithDescription("Read")
            
            store.find(query, readPolicy: .ForceLocal) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 5)
                    
                    for (i, person) in persons.enumerate() {
                        XCTAssertEqual(person.name, String(format: "Person Cached %02d", i + 1))
                    }
                }
                
                expectationRead?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationRead = nil
            }
        }
        
        do {
            weak var expectationPull = expectationWithDescription("Pull")
            
            store.pull(query) { (persons, error) -> Void in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 15)
                    if persons.count == 15 {
                        for (i, person) in persons[0..<10].enumerate() {
                            XCTAssertEqual(person.name, String(format: "Person %02d", i + 1))
                        }
                        for (i, person) in persons[10..<persons.count].enumerate() {
                            XCTAssertEqual(person.name, String(format: "Person Cached %02d", i + 1))
                        }
                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationPull = nil
            }
        }
    }
    
    func perform(countBackend countBackend: Int, countLocal: Int) {
        self.signUp()
        
        XCTAssertNotNil(self.client.activeUser)
        guard let activeUser = self.client.activeUser else {
            return
        }
        
        let save: (Int) -> Void = { n in
            for i in 1...n {
                let person = Person()
                person.name = String(format: "Person %03d", i)
                
                weak var expectationCreate = self.expectationWithDescription("Create")
                
                let createOperation = SaveOperation(persistable: person, writePolicy: .ForceNetwork, client: self.client)
                createOperation.execute { (results, error) -> Void in
                    XCTAssertNotNil(results)
                    XCTAssertNil(error)
                    
                    expectationCreate?.fulfill()
                }
                
                self.waitForExpectationsWithTimeout(self.defaultTimeout) { (error) -> Void in
                    expectationCreate = nil
                }
            }
        }
        
        let saveAndCache: (Int) -> Void = { n in
            let store = DataStore<Person>.collection()
            
            for i in 1...n {
                let person = Person()
                person.name = String(format: "Person Cached %03d", i)
                
                weak var expectationSave = self.expectationWithDescription("Save")
                
                store.save(person) { (person, error) -> Void in
                    XCTAssertNotNil(person)
                    XCTAssertNil(error)
                    
                    expectationSave?.fulfill()
                }
                
                self.waitForExpectationsWithTimeout(self.defaultTimeout) { (error) -> Void in
                    expectationSave = nil
                }
            }
        }
        
        saveAndCache(countLocal)
        save(countBackend)
        
        let store = DataStore<Person>.collection(.Sync)
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = self.expectationWithDescription("Read")
            
            store.find(query, readPolicy: .ForceLocal) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, countLocal)
                    
                    for (i, person) in persons.enumerate() {
                        XCTAssertEqual(person.name, String(format: "Person Cached %03d", i + 1))
                    }
                }
                
                expectationRead?.fulfill()
            }
            
            self.waitForExpectationsWithTimeout(self.defaultTimeout) { (error) -> Void in
                expectationRead = nil
            }
        }
        
        self.startMeasuring()
        
        do {
            weak var expectationFind = self.expectationWithDescription("Find")
            
            store.find(query, readPolicy: .ForceNetwork) { (persons, error) -> Void in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, countBackend + countLocal)
                    if persons.count > 0 {
                        for (i, person) in persons[0..<countBackend].enumerate() {
                            XCTAssertEqual(person.name, String(format: "Person %03d", i + 1))
                        }
                        for (i, person) in persons[countBackend..<persons.count].enumerate() {
                            XCTAssertEqual(person.name, String(format: "Person Cached %03d", i + 1))
                        }
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            self.waitForExpectationsWithTimeout(self.defaultTimeout) { (error) -> Void in
                expectationFind = nil
            }
        }
        
        self.stopMeasuring()
        
        self.tearDown()
    }
    
    func testPerformance_1_9() {
        measureMetrics(self.dynamicType.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) { () -> Void in
            self.perform(countBackend: 1, countLocal: 9)
        }
    }
    
    func testPerformance_9_1() {
        measureMetrics(self.dynamicType.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) { () -> Void in
            self.perform(countBackend: 9, countLocal: 1)
        }
    }
    
    func testFindEmpty() {
        signUp()
        
        let store = DataStore<Person>.collection()
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", client.activeUser!.userId)
        
        weak var expectationFind = expectationWithDescription("Find")
        
        store.find(query, readPolicy: .ForceNetwork) { results, error in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 0)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { (error) in
            expectationFind = nil
        }
    }
    
    func testFindOneRecord() {
        signUp()
        
        let store = DataStore<Person>.collection()
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", client.activeUser!.userId)
        
        class OnePersonURLProtocol: NSURLProtocol {
            
            static var userId = ""
            
            override class func canInitWithRequest(request: NSURLRequest) -> Bool {
                return true
            }
            
            override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
                return request
            }
            
            override func startLoading() {
                let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                client!.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
                
                let object = [
                    [
                        "_id": NSUUID().UUIDString,
                        "name": "Person 1",
                        "_acl": [
                            "creator": OnePersonURLProtocol.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-03-18T17:48:14.875Z",
                            "ect": "2016-03-18T17:48:14.875Z"
                        ]
                    ]
                ]
                let data = try! NSJSONSerialization.dataWithJSONObject(object, options: [])
                client!.URLProtocol(self, didLoadData: data)
                
                client!.URLProtocolDidFinishLoading(self)
            }
            
            override func stopLoading() {
            }
            
        }
        
        OnePersonURLProtocol.userId = client.activeUser!.userId
        
        setURLProtocol(OnePersonURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectationWithDescription("Find")
        
        store.find(query, readPolicy: .ForceNetwork) { results, error in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
                
                if let person = results.first {
                    XCTAssertEqual(person.name, "Person 1")
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { (error) in
            expectationFind = nil
        }
    }
    
    func testFindOneRecordDeltaSet() {
        signUp()
        
        let store = DataStore<Person>.collection(.Sync, deltaSet: true)
        
        let person = Person()
        person.name = "Victor"
        
        weak var expectationSave = expectationWithDescription("Save")
        
        store.save(person) { (person, error) in
            XCTAssertTrue(NSThread.isMainThread())
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            expectationSave?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { (error) in
            expectationSave = nil
        }
        
        weak var expectationPush = expectationWithDescription("Push")
        
        store.push() { (count, error) in
            XCTAssertTrue(NSThread.isMainThread())
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            
            expectationPush?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { (error) in
            expectationPush = nil
        }
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", client.activeUser!.userId)
        
        class OnePersonURLProtocol: NSURLProtocol {
            
            static var userId = ""
            static var urlProtocolCalled = false
            
            override class func canInitWithRequest(request: NSURLRequest) -> Bool {
                return !urlProtocolCalled
            }
            
            override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
                return request
            }
            
            override func startLoading() {
                OnePersonURLProtocol.urlProtocolCalled = true
                
                var queryParams = [String : String]()
                let components = request.URL?.query?.componentsSeparatedByString("&")
                XCTAssertNotNil(components)
                if let components = components {
                    for component in components {
                        let keyValuePair = component.componentsSeparatedByString("=")
                        queryParams[keyValuePair[0]] = keyValuePair[1]
                    }
                    let fields = queryParams["fields"]
                    XCTAssertNotNil(fields)
                    if let fields = fields {
                        let fieldsArray = fields.componentsSeparatedByString(",").sort()
                        XCTAssertGreaterThanOrEqual(fieldsArray.count, 2)
                        if fieldsArray.count >= 2 {
                            XCTAssertEqual(fieldsArray[0], "_id")
                            XCTAssertEqual(fieldsArray[1], "_kmd.lmt")
                        }
                    }
                }
                
                let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                client!.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
                
                let object = [
                    [
                        "_id": NSUUID().UUIDString,
                        "name": "Victor",
                        "_acl": [
                            "creator": OnePersonURLProtocol.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-03-18T17:48:14.875Z",
                            "ect": "2016-03-18T17:48:14.875Z"
                        ]
                    ]
                ]
                let data = try! NSJSONSerialization.dataWithJSONObject(object, options: [])
                client!.URLProtocol(self, didLoadData: data)
                
                client!.URLProtocolDidFinishLoading(self)
            }
            
            override func stopLoading() {
            }
            
        }
        
        OnePersonURLProtocol.userId = client.activeUser!.userId
        
        setURLProtocol(OnePersonURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectationWithDescription("Find")
        
        store.find(query, readPolicy: .ForceNetwork) { results, error in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
                
                if let person = results.first {
                    XCTAssertEqual(person.name, "Victor")
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { (error) in
            expectationFind = nil
        }
        
        XCTAssertTrue(OnePersonURLProtocol.urlProtocolCalled)
    }
    
}
