//
//  DeltaSetCacheTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey
import Foundation

class DeltaSetCacheTestCase: KinveyTestCase {
    
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
    
    func testComputeDelta() {
        let date = Date()
        let cache = MemoryCache<Person>()
        do {
            let person = Person()
            person.personId = "update"
            person.metadata = Metadata(JSON: [Metadata.LmtKey : date.toString()])
            cache.save(entity: person)
        }
        do {
            let person = Person()
            person.personId = "noChange"
            person.metadata = Metadata(JSON: [Metadata.LmtKey : date.toString()])
            cache.save(entity: person)
        }
        do {
            let person = Person()
            person.personId = "delete"
            person.metadata = Metadata(JSON: [Metadata.LmtKey : date.toString()])
            cache.save(entity: person)
        }
        let operation = Operation(
            cache: AnyCache(cache),
            options: Options(
                client: client
            )
        )
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
                    Metadata.LmtKey : Date(timeInterval: 1, since: date).toString()
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
            if useMockData {
                mockResponse(statusCode: 201, json: [
                    "_id" : UUID().uuidString,
                    "name" : "Victor",
                    "age" : 0,
                    "_acl" : [
                        "creator" : client.activeUser!.userId
                    ],
                    "_kmd" : [
                        "lmt" : Date().toString(),
                        "ect" : Date().toString()
                    ]
                    ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSaveLocal = expectation(description: "Save Local")
            weak var expectationSaveRemote = expectation(description: "Save Remote")
            
            store.save(person) { (person, error) -> Void in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let expectation = expectationSaveLocal {
                    expectation.fulfill()
                    expectationSaveLocal = nil
                } else {
                    expectationSaveRemote?.fulfill()
                }
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationSaveLocal = nil
                expectationSaveRemote = nil
            }
        }
        
        XCTAssertNotNil(person.personId)
        
        do {
            let person = Person()
            person.name = "Victor Barros"
            
            if useMockData {
                mockResponse(statusCode: 201, json: [
                    "_id" : UUID().uuidString,
                    "name" : "Victor Barros",
                    "age" : 0,
                    "_acl" : [
                        "creator" : client.activeUser!.userId
                    ],
                    "_kmd" : [
                        "lmt" : Date().toString(),
                        "ect" : Date().toString()
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationCreate = expectation(description: "Create")
            
            let createOperation = SaveOperation<Person>(
                persistable: person,
                writePolicy: .forceNetwork,
                options: Options(
                    client: client
                )
            )
            createOperation.execute { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    XCTFail()
                }
                
                expectationCreate?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationCreate = nil
            }
        }
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = expectation(description: "Read")
            
            store.find(query, readPolicy: .forceLocal) { persons, error in
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
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationRead = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse(json: [
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Victor",
                        "age" : 0,
                        "_acl" : [
                            "creator" : client.activeUser!.userId
                        ],
                        "_kmd" : [
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
                        ]
                    ],
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Victor Barros",
                        "age" : 0,
                        "_acl" : [
                            "creator" : client.activeUser!.userId
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
                    mockCount = 2
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(query, readPolicy: .forceNetwork) { persons, error in
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
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
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
            if useMockData {
                mockResponse(json: [
                    "_id": UUID().uuidString,
                    "name": "Victor",
                    "age": 0,
                    "_acl": [
                        "creator": client.activeUser?.userId
                    ],
                    "_kmd": [
                        "lmt": Date().toString(),
                        "ect": Date().toString()
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSaveLocal = expectation(description: "Save Local")
            weak var expectationSaveRemote = expectation(description: "Save Remote")
            
            store.save(person) { (person, error) -> Void in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let expectation = expectationSaveLocal {
                    expectation.fulfill()
                    expectationSaveLocal = nil
                } else {
                    expectationSaveRemote?.fulfill()
                }
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationSaveLocal = nil
                expectationSaveRemote = nil
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
            
            if useMockData {
                mockResponse(json: [
                    "name": person.name!,
                    "age": 0,
                    "_id": person.personId!,
                    "_acl": [
                        "creator": client.activeUser?.userId
                    ],
                    "_kmd": [
                        "lmt": Date().toString(),
                        "ect": Date().toString()
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationUpdate = expectation(description: "Update")
            
            let updateOperation = SaveOperation(
                persistable: person,
                writePolicy: .forceNetwork,
                options: Options(
                    client: client
                )
            )
            updateOperation.execute { result in
                switch result {
                case .success:
                    break
                case .failure:
                    XCTFail()
                }
                
                expectationUpdate?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationUpdate = nil
            }
        }
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = expectation(description: "Read")
            
            store.find(query, readPolicy: .forceLocal) { persons, error in
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
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationRead = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse(json: [
                    [
                        "_id": UUID().uuidString,
                        "name": "Victor Barros",
                        "age": 0,
                        "_acl": [
                            "creator": client.activeUser?.userId
                        ],
                        "_kmd": [
                            "lmt": Date().toString(),
                            "ect": Date().toString()
                        ]
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(query, readPolicy: .forceNetwork) { persons, error in
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
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
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
            if useMockData {
                mockResponse(json: [
                    "_id" : UUID().uuidString,
                    "name" : "Victor",
                    "age" : 0,
                    "_acl" : [
                        "creator" : client.activeUser!.userId
                    ],
                    "_kmd" : [
                        "lmt" : Date().toString(),
                        "ect" : Date().toString()
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSaveLocal = expectation(description: "Save Local")
            weak var expectationSaveRemote = expectation(description: "Save Remote")
            
            store.save(person) { (person, error) -> Void in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let expectation = expectationSaveLocal {
                    expectation.fulfill()
                    expectationSaveLocal = nil
                } else {
                    expectationSaveRemote?.fulfill()
                }
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationSaveLocal = nil
                expectationSaveRemote = nil
            }
        }
        
        XCTAssertNotNil(person.personId)
        guard let personId = person.personId else {
            return
        }
        
        do {
            if useMockData {
                mockResponse(json: ["count" : 1])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationDelete = expectation(description: "Delete")
            
            let query = Query(format: "personId == %@", personId)
            query.persistableType = Person.self
            let createRemove = RemoveByQueryOperation<Person>(
                query: query,
                writePolicy: .forceNetwork,
                options: Options(
                    client: client
                )
            )
            createRemove.execute { result in
                switch result {
                case .success(let count):
                    XCTAssertEqual(count, 1)
                case .failure:
                    XCTFail()
                }
                
                expectationDelete?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationDelete = nil
            }
        }
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = expectation(description: "Read")
            
            store.find(query, readPolicy: .forceLocal) { persons, error in
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
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationRead = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse(json: [])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(query, readPolicy: .forceNetwork) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 0)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
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
            
            if self.useMockData {
                self.mockResponse(statusCode: 201, json: [
                    "_id" : UUID().uuidString,
                    "name" : person.name!,
                    "age" : 0,
                    "_acl" : [
                        "creator" : self.client.activeUser?.userId
                    ],
                    "_kmd" : [
                        "lmt" : Date().toString(),
                        "ect" : Date().toString()
                    ]
                ])
            }
            defer {
                if self.useMockData {
                    self.setURLProtocol(nil)
                }
            }
            
            weak var expectationCreate = self.expectation(description: "Create")
            
            let createOperation = SaveOperation(
                persistable: person,
                writePolicy: .forceNetwork,
                options: Options(
                    client: self.client
                )
            )
            createOperation.execute { result in
                switch result {
                case .success:
                    break
                case .failure:
                    XCTFail()
                }
                
                expectationCreate?.fulfill()
            }
            
            self.waitForExpectations(timeout: self.defaultTimeout) { (error) -> Void in
                expectationCreate = nil
            }
        }
        
        let saveAndCache: (Int) -> Void = { i in
            let person = Person()
            person.name = String(format: "Person Cached %02d", i)
            let store = DataStore<Person>.collection()
            
            if self.useMockData {
                self.mockResponse(statusCode: 201, json: [
                    "_id" : UUID().uuidString,
                    "name" : person.name!,
                    "age" : 0,
                    "_acl" : [
                        "creator" : self.client.activeUser?.userId
                    ],
                    "_kmd" : [
                        "lmt" : Date().toString(),
                        "ect" : Date().toString()
                    ]
                ])
            }
            defer {
                if self.useMockData {
                    self.setURLProtocol(nil)
                }
            }
            
            weak var expectationSave = self.expectation(description: "Save")
            
            store.save(person, writePolicy: .forceNetwork) { (person, error) -> Void in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                expectationSave?.fulfill()
            }
            
            self.waitForExpectations(timeout: self.defaultTimeout) { (error) -> Void in
                expectationSave = nil
            }
        }
        
        for i in 1...10 {
            save(i)
        }
        
        for i in 1...5 {
            saveAndCache(i)
        }
        
        let store = DataStore<Person>.collection(.sync)
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = expectation(description: "Read")
            
            store.find(query, readPolicy: .forceLocal) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 5)
                    
                    for (i, person) in persons.enumerated() {
                        XCTAssertEqual(person.name, String(format: "Person Cached %02d", i + 1))
                    }
                }
                
                expectationRead?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationRead = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse(json: [
                    [
                        "_id": "5842214ec62113437f2cd7a7",
                        "name": "Person 01",
                        "age": 0,
                        "_acl": [
                            "creator": client.activeUser?.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-12-03T01:35:10.569Z",
                            "ect": "2016-12-03T01:35:10.569Z"
                        ]
                    ],
                    [
                        "_id": "5842214e101d805b674c5bcf",
                        "name": "Person 02",
                        "age": 0,
                        "_acl": [
                            "creator": client.activeUser?.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-12-03T01:35:10.747Z",
                            "ect": "2016-12-03T01:35:10.747Z"
                        ]
                    ],
                    [
                        "_id": "5842214fd23505ed759c7791",
                        "name": "Person 03",
                        "age": 0,
                        "_acl": [
                            "creator": client.activeUser?.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-12-03T01:35:11.105Z",
                            "ect": "2016-12-03T01:35:11.105Z"
                        ]
                    ],
                    [
                        "_id": "5842214f01bde1035e5246d6",
                        "name": "Person 04",
                        "age": 0,
                        "_acl": [
                            "creator": client.activeUser?.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-12-03T01:35:11.262Z",
                            "ect": "2016-12-03T01:35:11.262Z"
                        ]
                    ],
                    [
                        "_id": "5842214f101d805b674c5bd1",
                        "name": "Person 05",
                        "age": 0,
                        "_acl": [
                            "creator": client.activeUser?.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-12-03T01:35:11.424Z",
                            "ect": "2016-12-03T01:35:11.424Z"
                        ]
                    ],
                    [
                        "_id": "5842214f0ddebc566ac6ead9",
                        "name": "Person 06",
                        "age": 0,
                        "_acl": [
                            "creator": client.activeUser?.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-12-03T01:35:11.687Z",
                            "ect": "2016-12-03T01:35:11.687Z"
                        ]
                    ],
                    [
                        "_id": "5842214f01bde1035e5246d7",
                        "name": "Person 07",
                        "age": 0,
                        "_acl": [
                            "creator": client.activeUser?.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-12-03T01:35:11.850Z",
                            "ect": "2016-12-03T01:35:11.850Z"
                        ]
                    ],
                    [
                        "_id": "584221500ddebc566ac6eadb",
                        "name": "Person 08",
                        "age": 0,
                        "_acl": [
                            "creator": client.activeUser?.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-12-03T01:35:12.010Z",
                            "ect": "2016-12-03T01:35:12.010Z"
                        ]
                    ],
                    [
                        "_id": "58422150c62113437f2cd7aa",
                        "name": "Person 09",
                        "age": 0,
                        "_acl": [
                            "creator": client.activeUser?.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-12-03T01:35:12.164Z",
                            "ect": "2016-12-03T01:35:12.164Z"
                        ]
                    ],
                    [
                        "_id": "584221500ddebc566ac6eadc",
                        "name": "Person 10",
                        "age": 0,
                        "_acl": [
                            "creator": client.activeUser?.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-12-03T01:35:12.312Z",
                            "ect": "2016-12-03T01:35:12.312Z"
                        ]
                    ],
                    [
                        "_id": "58422150249f9f88615bb27d",
                        "name": "Person Cached 01",
                        "age": 0,
                        "_acl": [
                            "creator": client.activeUser?.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-12-03T01:35:12.426Z",
                            "ect": "2016-12-03T01:35:12.426Z"
                        ]
                    ],
                    [
                        "_id": "58422150f29e22207c640121",
                        "name": "Person Cached 02",
                        "age": 0,
                        "_acl": [
                            "creator": client.activeUser?.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-12-03T01:35:12.627Z",
                            "ect": "2016-12-03T01:35:12.627Z"
                        ]
                    ],
                    [
                        "_id": "5842215000d1899109e7d6a4",
                        "name": "Person Cached 03",
                        "age": 0,
                        "_acl": [
                            "creator": client.activeUser?.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-12-03T01:35:12.757Z",
                            "ect": "2016-12-03T01:35:12.757Z"
                        ]
                    ],
                    [
                        "_id": "58422150c62113437f2cd7ac",
                        "name": "Person Cached 04",
                        "age": 0,
                        "_acl": [
                            "creator": client.activeUser?.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-12-03T01:35:12.875Z",
                            "ect": "2016-12-03T01:35:12.875Z"
                        ]
                    ],
                    [
                        "_id": "58422151c62113437f2cd7ad",
                        "name": "Person Cached 05",
                        "age": 0,
                        "_acl": [
                            "creator": client.activeUser?.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-12-03T01:35:13.010Z",
                            "ect": "2016-12-03T01:35:13.010Z"
                        ]
                    ]
                ])
            }
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull(query) { (persons, error) -> Void in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 15)
                    if persons.count == 15 {
                        for (i, person) in persons[0..<10].enumerated() {
                            XCTAssertEqual(person.name, String(format: "Person %02d", i + 1))
                        }
                        for (i, person) in persons[10..<persons.count].enumerated() {
                            XCTAssertEqual(person.name, String(format: "Person Cached %02d", i + 1))
                        }
                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationPull = nil
            }
        }
    }
    
    func perform(countBackend: Int, countLocal: Int) {
        self.signUp()
        
        XCTAssertNotNil(self.client.activeUser)
        guard let activeUser = self.client.activeUser else {
            return
        }
        
        let save: (Int) -> Void = { n in
            for i in 1...n {
                let person = Person()
                person.name = String(format: "Person %03d", i)
                
                weak var expectationCreate = self.expectation(description: "Create")
                
                let createOperation = SaveOperation(
                    persistable: person,
                    writePolicy: .forceNetwork,
                    options: Options(
                        client: self.client
                    )
                )
                createOperation.execute { result in
                    switch result {
                    case .success:
                        break
                    case .failure:
                        XCTFail()
                    }
                    
                    expectationCreate?.fulfill()
                }
                
                self.waitForExpectations(timeout: self.defaultTimeout) { (error) -> Void in
                    expectationCreate = nil
                }
            }
        }
        
        let saveAndCache: (Int) -> Void = { n in
            let store = DataStore<Person>.collection()
            
            for i in 1...n {
                let person = Person()
                person.name = String(format: "Person Cached %03d", i)
                
                weak var expectationSave = self.expectation(description: "Save")
                
                store.save(person) { (person, error) -> Void in
                    XCTAssertNotNil(person)
                    XCTAssertNil(error)
                    
                    expectationSave?.fulfill()
                }
                
                self.waitForExpectations(timeout: self.defaultTimeout) { (error) -> Void in
                    expectationSave = nil
                }
            }
        }
        
        saveAndCache(countLocal)
        save(countBackend)
        
        let store = DataStore<Person>.collection(.sync)
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = self.expectation(description: "Read")
            
            store.find(query, readPolicy: .forceLocal) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, countLocal)
                    
                    for (i, person) in persons.enumerated() {
                        XCTAssertEqual(person.name, String(format: "Person Cached %03d", i + 1))
                    }
                }
                
                expectationRead?.fulfill()
            }
            
            self.waitForExpectations(timeout: self.defaultTimeout) { (error) -> Void in
                expectationRead = nil
            }
        }
        
        self.startMeasuring()
        
        do {
            weak var expectationFind = self.expectation(description: "Find")
            
            store.find(query, readPolicy: .forceNetwork) { (persons, error) -> Void in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, countBackend + countLocal)
                    if persons.count > 0 {
                        for (i, person) in persons[0..<countBackend].enumerated() {
                            XCTAssertEqual(person.name, String(format: "Person %03d", i + 1))
                        }
                        for (i, person) in persons[countBackend..<persons.count].enumerated() {
                            XCTAssertEqual(person.name, String(format: "Person Cached %03d", i + 1))
                        }
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            self.waitForExpectations(timeout: self.defaultTimeout) { (error) -> Void in
                expectationFind = nil
            }
        }
        
        self.stopMeasuring()
        
        self.tearDown()
    }
    
    func testPerformance_1_9() {
        guard !useMockData else {
            return
        }
        measureMetrics(type(of: self).defaultPerformanceMetrics, automaticallyStartMeasuring: false) { () -> Void in
            self.perform(countBackend: 1, countLocal: 9)
        }
    }
    
    func testPerformance_9_1() {
        guard !useMockData else {
            return
        }
        measureMetrics(type(of: self).defaultPerformanceMetrics, automaticallyStartMeasuring: false) { () -> Void in
            self.perform(countBackend: 9, countLocal: 1)
        }
    }
    
    func testFindEmpty() {
        signUp()
        
        let store = DataStore<Person>.collection()
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", client.activeUser!.userId)
        
        if useMockData {
            mockResponse(json: [])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(query, readPolicy: .forceNetwork) { results, error in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 0)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationFind = nil
        }
    }
    
    func testPullAllRecords() {
        signUp()
        
        let store = DataStore<Person>.collection(.sync)
        
        let person = Person()
        person.name = "Victor"
        
        do {
            weak var expectationSave = expectation(description: "Save")
            
            store.save(person) { person, error in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let person = person {
                    XCTAssertEqual(person.name, "Victor")
                }
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationSave = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse(json: [
                    "name": "Victor",
                    "age": 0,
                    "_acl": [
                        "creator": client.activeUser?.userId
                    ],
                    "_kmd": [
                        "lmt": "2016-12-03T01:44:44.642Z",
                        "ect": "2016-12-03T01:44:44.642Z"
                    ],
                    "_id": "5842238cd23505ed759c8887"
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPush = expectation(description: "Push")
            
            store.push() { count, error in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                if let count = count {
                    XCTAssertEqual(count, 1)
                }
                
                expectationPush?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationPush = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse(json: [
                    [
                        "_id": UUID().uuidString,
                        "_acl": [
                            "creator": client.activeUser?.userId
                        ],
                        "_kmd": [
                            "lmt": Date().toString()
                        ]
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", client.activeUser!.userId)
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull(query, deltaSet: true) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertGreaterThanOrEqual(results.count, 1)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationPull = nil
            }
        }
    }
    
    func testFindOneRecord() {
        signUp()
        
        let store = DataStore<Person>.collection()
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", client.activeUser!.userId)
        
        class OnePersonURLProtocol: URLProtocol {
            
            static var userId = ""
            
            override class func canInit(with request: URLRequest) -> Bool {
                return true
            }
            
            override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                return request
            }
            
            override func startLoading() {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                
                let object = [
                    [
                        "_id": UUID().uuidString,
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
                let data = try! JSONSerialization.data(withJSONObject: object)
                client!.urlProtocol(self, didLoad: data)
                
                client!.urlProtocolDidFinishLoading(self)
            }
            
            override func stopLoading() {
            }
            
        }
        
        OnePersonURLProtocol.userId = client.activeUser!.userId
        
        setURLProtocol(OnePersonURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(query, readPolicy: .forceNetwork) { results, error in
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
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationFind = nil
        }
    }
    
    func testFindOneRecordDeltaSetNoChange() {
        signUp()
        
        let store = DataStore<Person>.collection(.sync, deltaSet: true)
        
        let person = Person()
        person.name = "Victor"
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person) { (person, error) in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationSave = nil
        }
        
        var mockObjectId: String? = nil
        var mockDate: Date? = nil
        do {
            if useMockData {
                mockObjectId = UUID().uuidString
                mockDate = Date()
                mockResponse(statusCode: 201, json: [
                    "_id" : mockObjectId!,
                    "name" : "Victor",
                    "age" : 0,
                    "_acl" : [
                        "creator" : client.activeUser?.userId
                    ],
                    "_kmd" : [
                        "lmt" : mockDate?.toString(),
                        "ect" : mockDate?.toString()
                    ]
                    ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPush = expectation(description: "Push")
            
            store.push() { (count, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                expectationPush?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationPush = nil
            }
        }
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", client.activeUser!.userId)
        
        do {
            var mockCount = 0
            if useMockData {
                mockResponse { request in
                    mockCount += 1
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toString()],
                        json: [
                            [
                                "_id" : mockObjectId!,
                                "name" : "Victor",
                                "age" : 0,
                                "_acl" : [
                                    "creator" : self.client.activeUser?.userId
                                ],
                                "_kmd" : [
                                    "lmt" : mockDate?.toString(),
                                    "ect" : mockDate?.toString()
                                ]
                            ]
                        ]
                    )
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                    XCTAssertEqual(mockCount, 1)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(query, readPolicy: .forceNetwork) { results, error in
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
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
        
        do {
            var mockCount = 0
            if useMockData {
                mockResponse { request in
                    mockCount += 1
                    XCTAssertEqual(request.url!.path, "/appdata/_kid_/Person/_deltaset")
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toString()],
                        json: [
                            "changed" : [],
                            "deleted" : []
                        ]
                    )
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                    XCTAssertEqual(mockCount, 1)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(query, options: Options(readPolicy: .forceNetwork)) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success(let results):
                    XCTAssertEqual(results.count, 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor")
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
    }
    
    func testFindOneRecordDeltaSetChanged() {
        signUp()
        
        let store = DataStore<Person>.collection(.sync, deltaSet: true)
        var idToUpdate=""
        
        let person = Person()
        person.name = "Victor"
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person) { (person, error) in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationSave = nil
        }
        
        var mockObjectId: String? = nil
        var mockDate: Date? = nil
        do {
            if useMockData {
                mockObjectId = UUID().uuidString
                mockDate = Date()
                mockResponse(statusCode: 201, json: [
                    "_id" : mockObjectId!,
                    "name" : "Victor",
                    "age" : 0,
                    "_acl" : [
                        "creator" : client.activeUser?.userId
                    ],
                    "_kmd" : [
                        "lmt" : mockDate?.toString(),
                        "ect" : mockDate?.toString()
                    ]
                    ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPush = expectation(description: "Push")
            
            store.push() { (count, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                expectationPush?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationPush = nil
            }
        }
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", client.activeUser!.userId)
        
        do {
            var mockCount = 0
            if useMockData {
                mockResponse { request in
                    mockCount += 1
                    XCTAssertEqual(request.url!.path, "/appdata/_kid_/Person")
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toString()],
                        json: [
                            [
                                "_id" : mockObjectId!,
                                "name" : "Victor",
                                "age" : 0,
                                "_acl" : [
                                    "creator" : self.client.activeUser?.userId
                                ],
                                "_kmd" : [
                                    "lmt" : Date(timeInterval: 1, since: mockDate!).toString(),
                                    "ect" : mockDate?.toString()
                                ]
                            ]
                        ]
                    )
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                    XCTAssertEqual(mockCount, 1)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(query, readPolicy: .forceNetwork) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor")
                        idToUpdate = person.personId!
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
        
        person.name = "Victor Hugo"
        person.personId = idToUpdate
        
        weak var expectationUpdate = expectation(description: "Update")
        
        store.save(person) { (person, error) in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            expectationUpdate?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationUpdate = nil
        }
        
        do {
            if useMockData {
                mockResponse(statusCode: 200, json: [
                    "_id" : idToUpdate,
                    "name" : "Victor",
                    "age" : 0
                    ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPush = expectation(description: "Push")
            
            store.push() { (count, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                expectationPush?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationPush = nil
            }
        }
        
        do {
            var mockCount = 0
            if useMockData {
                mockResponse { request in
                    mockCount += 1
                    XCTAssertEqual(request.url!.path, "/appdata/_kid_/Person/_deltaset")
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toString()],
                        json: [
                            "changed" : [
                                [
                                    "_id" : mockObjectId!,
                                    "name" : "Victor Hugo",
                                    "age" : 0,
                                    "_acl" : [
                                        "creator" : self.client.activeUser?.userId
                                    ],
                                    "_kmd" : [
                                        "lmt" : Date(timeInterval: 1, since: mockDate!).toString(),
                                        "ect" : mockDate?.toString()
                                    ]
                                ]
                            ],
                            "deleted" : []
                        ]
                    )
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                    XCTAssertEqual(mockCount, 1)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(query, options: Options(readPolicy: .forceNetwork)) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success(let results):
                    XCTAssertEqual(results.count, 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Hugo")
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
    }
    
    func testFindOneRecordDeltaSetNoKmd() {
        signUp()
        var idToUpdate=""
        
        let store = DataStore<Person>.collection(.sync, deltaSet: true)
        
        let person = Person()
        person.name = "Victor"
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person) { (person, error) in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationSave = nil
        }
        
        var mockObjectId: String? = nil
        var mockDate: Date? = nil
        do {
            if useMockData {
                mockObjectId = UUID().uuidString
                mockDate = Date()
                mockResponse(
                    statusCode: 201,
                    json: [
                        "_id" : mockObjectId!,
                        "name" : "Victor",
                        "age" : 0,
                        "_acl" : [
                            "creator" : client.activeUser?.userId
                        ]
                    ]
                )
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPush = expectation(description: "Push")
            
            store.push() { (count, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                expectationPush?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationPush = nil
            }
        }
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", client.activeUser!.userId)
        
        do {
            if useMockData {
                mockResponse(
                    headerFields: ["X-Kinvey-Request-Start" : Date().toString()],
                    json: [
                        [
                            "_id" : mockObjectId!,
                            "name" : "Victor",
                            "age" : 0,
                            "_acl" : [
                                "creator" : self.client.activeUser?.userId
                            ]
                        ]
                    ]
                )
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(query, readPolicy: .forceNetwork) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor")
                        idToUpdate = person.personId!
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
        
        weak var expectationUpdate = expectation(description: "Update")
        
        
        person.personId = idToUpdate
        person.name = "Victor Hugo"
        store.save(person) { (person, error) in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            expectationUpdate?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationUpdate = nil
        }
        
        do {
            if useMockData {
                mockResponse(statusCode: 200, json: [
                    "_id" : idToUpdate,
                    "name" : "Victor",
                    "age" : 0
                    ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPush = expectation(description: "Push")
            
            store.push() { (count, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                expectationPush?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationPush = nil
            }
        }
        
        
        
        do {
            var mockCount = 0
            if useMockData {
                mockResponse { request in
                    mockCount += 1
                    XCTAssertEqual(request.url!.path, "/appdata/_kid_/Person/_deltaset")
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toString()],
                        json: [
                            "changed" : [
                                [
                                    "_id" : mockObjectId!,
                                    "name" : "Victor Hugo",
                                    "age" : 0,
                                    "_acl" : [
                                        "creator" : self.client.activeUser?.userId
                                    ],
                                    "_kmd" : [
                                        "lmt" : Date(timeInterval: 1, since: mockDate!).toString(),
                                        "ect" : mockDate?.toString()
                                    ]
                                ]
                            ],
                            "deleted" : []
                        ]
                    )
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                    XCTAssertEqual(mockCount, 1)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(query, options: Options(readPolicy: .forceNetwork)) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success(let results):
                    XCTAssertEqual(results.count, 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Hugo")
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
    }
    
    func testFindOneRecordDeltaSetTimeoutError2ndRequest() {
        let store = DataStore<Person>.collection(.sync, deltaSet: true)
        
        do {
            let person = Person()
            person.name = "Victor"
            
            weak var expectationSave = expectation(description: "Save")
            
            store.save(person) { (person, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationSave = nil
            }
        }
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(readPolicy: .forceNetwork) { (persons, error) in
            XCTAssertNil(persons)
            XCTAssertNotNil(error)
            
            XCTAssertTimeoutError(error)
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationFind = nil
        }
    }
    
    func testFind201RecordsDeltaSet() {
        signUp()
        
        let store = DataStore<Person>.collection(.sync, deltaSet: true)
        
        let person = Person()
        person.name = "Victor"
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person) { (person, error) in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationSave = nil
        }
        
        do {
            if useMockData{
                mockResponse(statusCode: 201, json: [
                    "_id" : UUID().uuidString,
                    "name" : "Victor",
                    "age" : 0,
                    "_acl" : [
                        "creator" : client.activeUser?.userId
                    ],
                    "_kmd" : [
                        "lmt" : Date().toString(),
                        "ect" : Date().toString()
                    ]
                    ])
                defer {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPush = expectation(description: "Push")
            
            store.push() { (count, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                expectationPush?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationPush = nil
            }
        }
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", client.activeUser!.userId)
        
        var jsonArray = [JsonDictionary]()
        for _ in 1...201 {
            jsonArray.append([
                "_id" : UUID().uuidString,
                "name" : UUID().uuidString,
                "age" : 0,
                "_acl" : [
                    "creator" : self.client.activeUser!.userId
                ],
                "_kmd" : [
                    "lmt" : Date().toString(),
                    "ect" : Date().toString()
                ]
                ])
        }
        
        
        do {
            for _ in 1...200 {
                weak var expectationSave = expectation(description: "Save")
                let person = Person()
                person.name = UUID().uuidString
                store.save(person) { (person, error) in
                    XCTAssertTrue(Thread.isMainThread)
                    XCTAssertNotNil(person)
                    XCTAssertNil(error)
                    
                    expectationSave?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { (error) in
                    expectationSave = nil
                }
            }
            weak var expectationPush = expectation(description: "Push")
            
            store.push() { (count, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                expectationPush?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationPush = nil
            }
            
        }
        
        
        do {
            if useMockData{
                mockResponse(headerFields: ["X-Kinvey-Request-Start" : Date().toString()], json: jsonArray)
                defer {
                    setURLProtocol(nil)
                }
                
                
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(readPolicy: .forceNetwork) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                XCTAssertEqual(results?.count, 201)
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
        
        do {
            if useMockData{
                mockResponse { response in
                    let urlComponents = URLComponents(url: response.url!, resolvingAgainstBaseURL: false)!
                    XCTAssertEqual(urlComponents.path.components(separatedBy: "/").last, "_deltaset")
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toString()],
                        json: [
                            "changed" : [],
                            "deleted" : []
                        ]
                    )
                }
                defer {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(readPolicy: .forceNetwork) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                XCTAssertEqual(results?.count, 201)
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
    }
    
    func testFind201RecordsDeltaSetTimeoutOn2ndRequest() {
        signUp()
        
        let store = DataStore<Person>.collection(.sync, deltaSet: true)
        
        let person = Person()
        person.name = "Victor"
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person) { (person, error) in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationSave = nil
        }
        
        do {
            mockResponse(statusCode: 201, json: [
                "_id" : UUID().uuidString,
                "name" : "Victor",
                "age" : 0,
                "_acl" : [
                    "creator" : client.activeUser?.userId
                ],
                "_kmd" : [
                    "lmt" : Date().toString(),
                    "ect" : Date().toString()
                ]
                ])
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationPush = expectation(description: "Push")
            
            store.push() { (count, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                expectationPush?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationPush = nil
            }
        }
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", client.activeUser!.userId)
        
        var jsonArray = [JsonDictionary]()
        for _ in 1...201 {
            jsonArray.append([
                "_id" : UUID().uuidString,
                "name" : UUID().uuidString,
                "age" : 0,
                "_acl" : [
                    "creator" : self.client.activeUser!.userId
                ],
                "_kmd" : [
                    "lmt" : Date().toString(),
                    "ect" : Date().toString()
                ]
                ])
        }
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(readPolicy: .forceNetwork) { results, error in
            XCTAssertNil(results)
            XCTAssertNotNil(error)
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationFind = nil
        }
    }
    
    func testDeltaSet3rdPull() {
        signUp()
        
        let store = DataStore<Person>.collection(.sync, options: Options(deltaSet: true))
        
        var date1: String?
        var date2: String?
        var date3: String?
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person":
                        date1 = Date().toString()
                        return HttpResponse(
                            headerFields: ["X-Kinvey-Request-Start" : date1!],
                            json: [
                                [
                                    "_id" : "58450d87f29e22207c83a237",
                                    "name" : "Victor Barros",
                                    "age" : 0,
                                    "_acl" : [
                                        "creator" : self.client.activeUser!.userId
                                    ],
                                    "_kmd" : [
                                        "lmt" : Date().toString(),
                                        "ect" : Date().toString()
                                    ]
                                ]
                            ]
                        )
                    default:
                        XCTFail(request.url!.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            }else {
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
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        Thread.sleep(until: Date(timeIntervalSinceNow: 1))
        
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        date2 = Date().toString()
                        let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
                        let since = urlComponents?.queryItems?.filter { $0.name == "since" }.first?.value
                        XCTAssertNotNil(since)
                        if let since = since {
                            XCTAssertEqual(since, date1!)
                        }
                        return HttpResponse(
                            headerFields: ["X-Kinvey-Request-Start" : date2!],
                            json: [
                                "changed" : [
                                    [
                                        "_id" : "58450d87f29e22207c83a238",
                                        "name" : "Victor Hugo",
                                        "age" : 0,
                                        "_acl" : [
                                            "creator" : self.client.activeUser!.userId
                                        ],
                                        "_kmd" : [
                                            "lmt" : Date().toString(),
                                            "ect" : Date().toString()
                                        ]
                                    ]
                                ],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(request.url!.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            }else {
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
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        Thread.sleep(until: Date(timeIntervalSinceNow: 1))
        
        do {
            if useMockData {
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        date3 = Date().toString()
                        let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
                        let since = urlComponents?.queryItems?.filter { $0.name == "since" }.first?.value
                        XCTAssertNotNil(since)
                        if let since = since {
                            XCTAssertNotEqual(since, date1!)
                            XCTAssertEqual(since, date2!)
                        }
                        return HttpResponse(
                            headerFields: ["X-Kinvey-Request-Start" : date3!],
                            json: [
                                "changed" : [
                                    [
                                        "_id" : "58450d87f29e22207c83a239",
                                        "name" : "Victor Emmanuel",
                                        "age" : 0,
                                        "_acl" : [
                                            "creator" : self.client.activeUser!.userId
                                        ],
                                        "_kmd" : [
                                            "lmt" : Date().toString(),
                                            "ect" : Date().toString()
                                        ]
                                    ]
                                ],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(request.url!.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Emmanuel"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 3)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    
                    if let lastPerson = results.last {
                        XCTAssertEqual(lastPerson.name, "Victor Emmanuel")
                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
    }
    
    func testDeltaSetChangeFromSyncToCache() {
        signUp()
        
        var store = DataStore<Person>.collection(.sync, options: Options(deltaSet: true))
        
        var date1: String?
        var date2: String?
        var date3: String?
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person":
                        date1 = Date().toString()
                        return HttpResponse(
                            headerFields: ["X-Kinvey-Request-Start" : date1!],
                            json: [
                                [
                                    "_id" : "58450d87f29e22207c83a237",
                                    "name" : "Victor Barros",
                                    "age" : 0,
                                    "_acl" : [
                                        "creator" : self.client.activeUser!.userId
                                    ],
                                    "_kmd" : [
                                        "lmt" : Date().toString(),
                                        "ect" : Date().toString()
                                    ]
                                ]
                            ]
                        )
                    default:
                        XCTFail(request.url!.path)
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
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        date2 = Date().toString()
                        let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
                        let since = urlComponents?.queryItems?.filter { $0.name == "since" }.first?.value
                        XCTAssertNotNil(since)
                        if let since = since {
                            XCTAssertEqual(since, date1!)
                        }
                        return HttpResponse(
                            headerFields: ["X-Kinvey-Request-Start" : date2!],
                            json: [
                                "changed" : [
                                    [
                                        "_id" : "58450d87f29e22207c83a238",
                                        "name" : "Victor Hugo",
                                        "age" : 0,
                                        "_acl" : [
                                            "creator" : self.client.activeUser!.userId
                                        ],
                                        "_kmd" : [
                                            "lmt" : Date().toString(),
                                            "ect" : Date().toString()
                                        ]
                                    ]
                                ],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(request.url!.path)
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
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 2)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Victor Hugo")
                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        store = DataStore<Person>.collection(.cache, options: Options(deltaSet: true))
        
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        date3 = Date().toString()
                        let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
                        let since = urlComponents?.queryItems?.filter { $0.name == "since" }.first?.value
                        XCTAssertNotNil(since)
                        if let since = since {
                            XCTAssertNotEqual(since, date1!)
                            XCTAssertEqual(since, date2!)
                        }
                        return HttpResponse(
                            headerFields: ["X-Kinvey-Request-Start" : date3!],
                            json: [
                                "changed" : [
                                    [
                                        "_id" : "58450d87f29e22207c83a239",
                                        "name" : "Victor Emmanuel",
                                        "age" : 0,
                                        "_acl" : [
                                            "creator" : self.client.activeUser!.userId
                                        ],
                                        "_kmd" : [
                                            "lmt" : Date().toString(),
                                            "ect" : Date().toString()
                                        ]
                                    ]
                                ],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(request.url!.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            }else {
                var person = Person()
                person.name = "Victor Emmanuel"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 3)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Victor Emmanuel")
                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
    }
    
    func testDeltaSetChangeFromCacheToSync() {
        signUp()
        
        var store = DataStore<Person>.collection(.cache, options: Options(deltaSet: true))
        
        var date1: String?
        var date2: String?
        var date3: String?
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person":
                        date1 = Date().toString()
                        return HttpResponse(
                            headerFields: ["X-Kinvey-Request-Start" : date1!],
                            json: [
                                [
                                    "_id" : "58450d87f29e22207c83a237",
                                    "name" : "Victor Barros",
                                    "age" : 0,
                                    "_acl" : [
                                        "creator" : self.client.activeUser!.userId
                                    ],
                                    "_kmd" : [
                                        "lmt" : Date().toString(),
                                        "ect" : Date().toString()
                                    ]
                                ]
                            ]
                        )
                    default:
                        XCTFail(request.url!.path)
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
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        date2 = Date().toString()
                        let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
                        let since = urlComponents?.queryItems?.filter { $0.name == "since" }.first?.value
                        XCTAssertNotNil(since)
                        if let since = since {
                            XCTAssertEqual(since, date1!)
                        }
                        return HttpResponse(
                            headerFields: ["X-Kinvey-Request-Start" : date2!],
                            json: [
                                "changed" : [
                                    [
                                        "_id" : "58450d87f29e22207c83a238",
                                        "name" : "Victor Hugo",
                                        "age" : 0,
                                        "_acl" : [
                                            "creator" : self.client.activeUser!.userId
                                        ],
                                        "_kmd" : [
                                            "lmt" : Date().toString(),
                                            "ect" : Date().toString()
                                        ]
                                    ]
                                ],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(request.url!.path)
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
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 2)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Victor Hugo")
                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        store = DataStore<Person>.collection(.sync, options: Options(deltaSet: true))
        
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        date3 = Date().toString()
                        let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
                        let since = urlComponents?.queryItems?.filter { $0.name == "since" }.first?.value
                        XCTAssertNotNil(since)
                        if let since = since {
                            XCTAssertNotEqual(since, date1!)
                            XCTAssertEqual(since, date2!)
                        }
                        return HttpResponse(
                            headerFields: ["X-Kinvey-Request-Start" : date3!],
                            json: [
                                "changed" : [
                                    [
                                        "_id" : "58450d87f29e22207c83a239",
                                        "name" : "Victor Emmanuel",
                                        "age" : 0,
                                        "_acl" : [
                                            "creator" : self.client.activeUser!.userId
                                        ],
                                        "_kmd" : [
                                            "lmt" : Date().toString(),
                                            "ect" : Date().toString()
                                        ]
                                    ]
                                ],
                                "deleted" : []
                            ]
                        )
                    default:
                        XCTFail(request.url!.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            }else {
                var person = Person()
                person.name = "Victor Emmanuel"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 3)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Victor Emmanuel")
                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
    }
    
    func testDeltaSetChangeFromNetworkToCache() {
        signUp()
        
        var store = DataStore<Person>.collection(.network, options: nil)
        
        var date1: String?
        var date2: String?
        var date3: String?
        var idToDelete = ""
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person":
                        date1 = Date().toString()
                        return HttpResponse(
                            headerFields: ["X-Kinvey-Request-Start" : date1!],
                            json: [
                                [
                                    "_id" : "58450d87f29e22207c83a237",
                                    "name" : "Victor Barros",
                                    "age" : 0,
                                    "_acl" : [
                                        "creator" : self.client.activeUser!.userId
                                    ],
                                    "_kmd" : [
                                        "lmt" : Date().toString(),
                                        "ect" : Date().toString()
                                    ]
                                ]
                            ]
                        )
                    default:
                        XCTFail(request.url!.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
                idToDelete = person.personId!
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            var options = Options()
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
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        store = DataStore<Person>.collection(.cache, options: Options(deltaSet: true))
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person":
                        date2 = Date().toString()
                        return HttpResponse(
                            headerFields: ["X-Kinvey-Request-Start" : date2!],
                            json: [
                                    [
                                        "_id" : "58450d87f29e22207c83a237",
                                        "name" : "Victor Barros",
                                        "age" : 0,
                                        "_acl" : [
                                            "creator" : self.client.activeUser!.userId
                                        ],
                                        "_kmd" : [
                                            "lmt" : Date().toString(),
                                            "ect" : Date().toString()
                                        ]
                                    ],
                                    [
                                        "_id" : "58450d87f29e22207c83a238",
                                        "name" : "Victor Hugo",
                                        "age" : 0,
                                        "_acl" : [
                                            "creator" : self.client.activeUser!.userId
                                        ],
                                        "_kmd" : [
                                            "lmt" : Date().toString(),
                                            "ect" : Date().toString()
                                        ]
                                    ]

                            ]
                        )
                    default:
                        XCTFail(request.url!.path)
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
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 2)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Victor Hugo")
                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        date3 = Date().toString()
                        let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
                        let since = urlComponents?.queryItems?.filter { $0.name == "since" }.first?.value
                        XCTAssertNotNil(since)
                        if let since = since {
                            XCTAssertNotEqual(since, date1!)
                            XCTAssertEqual(since, date2!)
                        }
                        return HttpResponse(
                            headerFields: ["X-Kinvey-Request-Start" : date3!],
                            json: [
                                "changed" : [
                                    [
                                        "_id" : "58450d87f29e22207c83a239",
                                        "name" : "Victor Emmanuel",
                                        "age" : 0,
                                        "_acl" : [
                                            "creator" : self.client.activeUser!.userId
                                        ],
                                        "_kmd" : [
                                            "lmt" : Date().toString(),
                                            "ect" : Date().toString()
                                        ]
                                    ]
                                ],
                                "deleted" : [["_id":"58450d87f29e22207c83a237"]]
                            ]
                        )
                    default:
                        XCTFail(request.url!.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            }else {
                var person = Person()
                person.name = "Victor Emmanuel"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
                try! DataStore<Person>.collection(.network).remove(byId: idToDelete).waitForResult(timeout: defaultTimeout)
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 2)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Hugo")
                    }
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Victor Emmanuel")
                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
    }
    
    func testDeltaSetChangeFromNetworkToSync() {
        signUp()
        
        var store = DataStore<Person>.collection(.network, options: nil)
        
        var date1: String?
        var date2: String?
        var date3: String?
        var idToDelete = ""
        
        var initialCount = Int64(0)
        do {
            if !useMockData {
                initialCount = Int64(try! DataStore<Person>.collection(.network).count(options: nil).waitForResult(timeout: defaultTimeout).value())
            }
        }
        
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person":
                        date1 = Date().toString()
                        return HttpResponse(
                            headerFields: ["X-Kinvey-Request-Start" : date1!],
                            json: [
                                [
                                    "_id" : "58450d87f29e22207c83a237",
                                    "name" : "Victor Barros",
                                    "age" : 0,
                                    "_acl" : [
                                        "creator" : self.client.activeUser!.userId
                                    ],
                                    "_kmd" : [
                                        "lmt" : Date().toString(),
                                        "ect" : Date().toString()
                                    ]
                                ]
                            ]
                        )
                    default:
                        XCTFail(request.url!.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            } else {
                var person = Person()
                person.name = "Victor Barros"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
                idToDelete = person.personId!
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            var options = Options()
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
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        store = DataStore<Person>.collection(.sync, options: Options(deltaSet: true))
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person":
                        date2 = Date().toString()
                        return HttpResponse(
                            headerFields: ["X-Kinvey-Request-Start" : date2!],
                            json: [
                                [
                                    "_id" : "58450d87f29e22207c83a237",
                                    "name" : "Victor Barros",
                                    "age" : 0,
                                    "_acl" : [
                                        "creator" : self.client.activeUser!.userId
                                    ],
                                    "_kmd" : [
                                        "lmt" : Date().toString(),
                                        "ect" : Date().toString()
                                    ]
                                ],
                                [
                                    "_id" : "58450d87f29e22207c83a238",
                                    "name" : "Victor Hugo",
                                    "age" : 0,
                                    "_acl" : [
                                        "creator" : self.client.activeUser!.userId
                                    ],
                                    "_kmd" : [
                                        "lmt" : Date().toString(),
                                        "ect" : Date().toString()
                                    ]
                                ]
                                
                            ]
                        )
                    default:
                        XCTFail(request.url!.path)
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
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 2)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Victor Hugo")
                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        date3 = Date().toString()
                        let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
                        let since = urlComponents?.queryItems?.filter { $0.name == "since" }.first?.value
                        XCTAssertNotNil(since)
                        if let since = since {
                            XCTAssertNotEqual(since, date1!)
                            XCTAssertEqual(since, date2!)
                        }
                        return HttpResponse(
                            headerFields: ["X-Kinvey-Request-Start" : date3!],
                            json: [
                                "changed" : [
                                    [
                                        "_id" : "58450d87f29e22207c83a239",
                                        "name" : "Victor Emmanuel",
                                        "age" : 0,
                                        "_acl" : [
                                            "creator" : self.client.activeUser!.userId
                                        ],
                                        "_kmd" : [
                                            "lmt" : Date().toString(),
                                            "ect" : Date().toString()
                                        ]
                                    ]
                                ],
                                "deleted" : [["_id":"58450d87f29e22207c83a237"]]
                            ]
                        )
                    default:
                        XCTFail(request.url!.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            }else {
                var person = Person()
                person.name = "Victor Emmanuel"
                person = try! DataStore<Person>.collection(.network).save(person, options: nil).waitForResult(timeout: defaultTimeout).value()
                try! DataStore<Person>.collection(.network).remove(byId: idToDelete).waitForResult(timeout: defaultTimeout)
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(Int64(results.count), initialCount + 2)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Victor Hugo")
                    }
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Victor Emmanuel")
                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
    }
    
    func testDeltaSetLowercaseHeader() {
        signUp()
        
        let store = DataStore<Person>.collection(.sync, options: Options(deltaSet: true))
        
        var date1: String?
        var date2: String?
        var date3: String?
        
        do {
            mockResponse { request in
                switch request.url!.path {
                case "/appdata/_kid_/Person":
                    date1 = Date().toString()
                    return HttpResponse(
                        headerFields: ["x-kinvey-request-start" : date1!],
                        json: [
                            [
                                "_id" : UUID().uuidString,
                                "name" : UUID().uuidString,
                                "age" : 0,
                                "_acl" : [
                                    "creator" : self.client.activeUser!.userId
                                ],
                                "_kmd" : [
                                    "lmt" : Date().toString(),
                                    "ect" : Date().toString()
                                ]
                            ]
                        ]
                    )
                default:
                    XCTFail(request.url!.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            let results = try! store.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(results.count, 1)
        }
        
        Thread.sleep(until: Date(timeIntervalSinceNow: 1))
        
        do {
            mockResponse { request in
                switch request.url!.path {
                case "/appdata/_kid_/Person/_deltaset":
                    date2 = Date().toString()
                    let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
                    let since = urlComponents?.queryItems?.filter { $0.name == "since" }.first?.value
                    XCTAssertNotNil(since)
                    if let since = since {
                        XCTAssertEqual(since, date1!)
                    }
                    return HttpResponse(
                        headerFields: ["x-kinvey-request-start" : date2!],
                        json: [
                            "changed" : [
                                [
                                    "_id" : UUID().uuidString,
                                    "name" : UUID().uuidString,
                                    "age" : 0,
                                    "_acl" : [
                                        "creator" : self.client.activeUser!.userId
                                    ],
                                    "_kmd" : [
                                        "lmt" : Date().toString(),
                                        "ect" : Date().toString()
                                    ]
                                ]
                            ],
                            "deleted" : []
                        ]
                    )
                default:
                    XCTFail(request.url!.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            let results = try! store.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(results.count, 2)
        }
    }

}
