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
import Nimble

class DeltaSetCacheTestCase: KinveyTestCase {
    
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
    
    func testComputeDelta() {
        let date = Date()
        let cache = MemoryCache<Person>()
        do {
            let person = Person()
            person.personId = "update"
            person.metadata = Metadata(JSON: [Metadata.CodingKeys.lastModifiedTime.rawValue : date.toISO8601()])
            cache.save(entity: person)
        }
        do {
            let person = Person()
            person.personId = "noChange"
            person.metadata = Metadata(JSON: [Metadata.CodingKeys.lastModifiedTime.rawValue : date.toISO8601()])
            cache.save(entity: person)
        }
        do {
            let person = Person()
            person.personId = "delete"
            person.metadata = Metadata(JSON: [Metadata.CodingKeys.lastModifiedTime.rawValue : date.toISO8601()])
            cache.save(entity: person)
        }
        let operation = Operation(
            cache: AnyCache(cache),
            options: try! Options(
                client: client
            )
        )
        let query = Query()
        let refObjs: [JsonDictionary] = [
            [
                Entity.EntityCodingKeys.entityId.rawValue : "create",
                Entity.EntityCodingKeys.metadata.rawValue : [
                    Metadata.CodingKeys.lastModifiedTime.rawValue : date.toISO8601(),
                ]
            ],
            [
                Entity.EntityCodingKeys.entityId.rawValue : "update",
                Entity.EntityCodingKeys.metadata.rawValue : [
                    Metadata.CodingKeys.lastModifiedTime.rawValue : Date(timeInterval: 1, since: date).toISO8601()
                ]
            ],
            [
                Entity.EntityCodingKeys.entityId.rawValue : "noChange",
                Entity.EntityCodingKeys.metadata.rawValue : [
                    Metadata.CodingKeys.lastModifiedTime.rawValue : date.toISO8601()
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
        
        let store = try! DataStore<Person>.collection()
        
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
            
            weak var expectationSaveLocal = expectation(description: "Save Local")
            weak var expectationSaveRemote = expectation(description: "Save Remote")
            
            store.save(person) {
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
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
            
            weak var expectationCreate = expectation(description: "Create")
            
            let createOperation = SaveOperation<Person>(
                persistable: person,
                writePolicy: .forceNetwork,
                options: try! Options(
                    client: client
                )
            )
            createOperation.execute { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationCreate?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationCreate = nil
            }
        }
        
        let query = Query(format: "\(try! Person.aclProperty() ?? Person.EntityCodingKeys.acl.rawValue).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = expectation(description: "Read")
            
            store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 1)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor")
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
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
                            "lmt" : Date().toISO8601(),
                            "ect" : Date().toISO8601()
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
                            "lmt" : Date().toISO8601(),
                            "ect" : Date().toISO8601()
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
            
            store.find(query, options: try! Options(readPolicy: .forceNetwork)) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 2)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor")
                    }
                    if let person = persons.last {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
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
        
        let store = try! DataStore<Person>.collection()
        
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
                        "lmt": Date().toISO8601(),
                        "ect": Date().toISO8601()
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
            
            store.save(person) {
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
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
                        "lmt": Date().toISO8601(),
                        "ect": Date().toISO8601()
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
                options: try! Options(
                    client: client
                )
            )
            updateOperation.execute { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationUpdate?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationUpdate = nil
            }
        }
        
        let query = Query(format: "\(try! Person.aclProperty() ?? Person.EntityCodingKeys.acl.rawValue).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = expectation(description: "Read")
            
            store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 1)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor")
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
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
                            "lmt": Date().toISO8601(),
                            "ect": Date().toISO8601()
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
            
            store.find(query, options: try! Options(readPolicy: .forceNetwork)) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 1)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
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
        
        let store = try! DataStore<Person>.collection()
        
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
            
            weak var expectationSaveLocal = expectation(description: "Save Local")
            weak var expectationSaveRemote = expectation(description: "Save Remote")
            
            store.save(person) {
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
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
                options: try! Options(
                    client: client
                )
            )
            createRemove.execute { result in
                switch result {
                case .success(let count):
                    XCTAssertEqual(count, 1)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationDelete?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationDelete = nil
            }
        }
        
        let query = Query(format: "\(try! Person.aclProperty() ?? Person.EntityCodingKeys.acl.rawValue).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = expectation(description: "Read")
            
            store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 1)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor")
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
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
            
            store.find(query, options: try! Options(readPolicy: .forceNetwork)) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 0)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
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
                        "lmt" : Date().toISO8601(),
                        "ect" : Date().toISO8601()
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
                options: try! Options(
                    client: self.client
                )
            )
            createOperation.execute { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
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
            let store = try! DataStore<Person>.collection()
            
            if self.useMockData {
                self.mockResponse(statusCode: 201, json: [
                    "_id" : UUID().uuidString,
                    "name" : person.name!,
                    "age" : 0,
                    "_acl" : [
                        "creator" : self.client.activeUser?.userId
                    ],
                    "_kmd" : [
                        "lmt" : Date().toISO8601(),
                        "ect" : Date().toISO8601()
                    ]
                ])
            }
            defer {
                if self.useMockData {
                    self.setURLProtocol(nil)
                }
            }
            
            weak var expectationSave = self.expectation(description: "Save")
            
            store.save(person, options: try! Options(writePolicy: .forceNetwork)) {
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
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
        
        let store = try! DataStore<Person>.collection(.sync)
        
        let query = Query(format: "\(try! Person.aclProperty() ?? Person.EntityCodingKeys.acl.rawValue).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = expectation(description: "Read")
            
            store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 5)
                    
                    for (i, person) in persons.enumerated() {
                        XCTAssertEqual(person.name, String(format: "Person Cached %02d", i + 1))
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
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
                    options: try! Options(
                        client: self.client
                    )
                )
                createOperation.execute { result in
                    switch result {
                    case .success:
                        break
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationCreate?.fulfill()
                }
                
                self.waitForExpectations(timeout: self.defaultTimeout) { (error) -> Void in
                    expectationCreate = nil
                }
            }
        }
        
        let saveAndCache: (Int) -> Void = { n in
            let store = try! DataStore<Person>.collection()
            
            for i in 1...n {
                let person = Person()
                person.name = String(format: "Person Cached %03d", i)
                
                weak var expectationSave = self.expectation(description: "Save")
                
                store.save(person) {
                    switch $0 {
                    case .success:
                        break
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationSave?.fulfill()
                }
                
                self.waitForExpectations(timeout: self.defaultTimeout) { (error) -> Void in
                    expectationSave = nil
                }
            }
        }
        
        saveAndCache(countLocal)
        save(countBackend)
        
        let store = try! DataStore<Person>.collection(.sync)
        
        let query = Query(format: "\(try! Person.aclProperty() ?? Person.EntityCodingKeys.acl.rawValue).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = self.expectation(description: "Read")
            
            store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, countLocal)
                    
                    for (i, person) in persons.enumerated() {
                        XCTAssertEqual(person.name, String(format: "Person Cached %03d", i + 1))
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
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
            
            store.find(query, options: try! Options(readPolicy: .forceNetwork)) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, countBackend + countLocal)
                    if persons.count > 0 {
                        for (i, person) in persons[AnyIndex(0) ..< AnyIndex(countBackend)].enumerated() {
                            XCTAssertEqual(person.name, String(format: "Person %03d", i + 1))
                        }
                        for (i, person) in persons[AnyIndex(countBackend) ..< AnyIndex(persons.count)].enumerated() {
                            XCTAssertEqual(person.name, String(format: "Person Cached %03d", i + 1))
                        }
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
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
        
        let store = try! DataStore<Person>.collection()
        let query = Query(format: "\(try! Person.aclProperty() ?? Person.EntityCodingKeys.acl.rawValue).creator == %@", client.activeUser!.userId)
        
        if useMockData {
            mockResponse(json: [])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(query, options: try! Options(readPolicy: .forceNetwork)) {
            switch $0 {
            case .success(let results):
                XCTAssertEqual(results.count, 0)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationFind = nil
        }
    }
    
    func testPullAllRecords() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.sync)
        
        let person = Person()
        person.name = "Victor"
        
        do {
            weak var expectationSave = expectation(description: "Save")
            
            store.save(person) {
                switch $0 {
                case .success(let person):
                    XCTAssertEqual(person.name, "Victor")
                case .failure(let error):
                    XCTFail(error.localizedDescription)
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
                            "lmt": Date().toISO8601()
                        ]
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            let query = Query(format: "\(try! Person.aclProperty() ?? Person.EntityCodingKeys.acl.rawValue).creator == %@", client.activeUser!.userId)
            
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
        
        let store = try! DataStore<Person>.collection()
        let query = Query(format: "\(try! Person.aclProperty() ?? Person.EntityCodingKeys.acl.rawValue).creator == %@", client.activeUser!.userId)
        
        // swiftlint:disable nesting
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
        // swiftlint:enable nesting
        
        OnePersonURLProtocol.userId = client.activeUser!.userId
        
        setURLProtocol(OnePersonURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(query, options: try! Options(readPolicy: .forceNetwork)) {
            switch $0 {
            case .success(let results):
                XCTAssertEqual(results.count, 1)
                
                if let person = results.first {
                    XCTAssertEqual(person.name, "Person 1")
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
    
    func testFindOneRecordDeltaSetNoChange() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        let person = Person()
        person.name = "Victor"
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person) {
            XCTAssertTrue(Thread.isMainThread)
            switch $0 {
            case .success:
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
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
                        "lmt" : mockDate?.toISO8601(),
                        "ect" : mockDate?.toISO8601()
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
        
        let query = Query(format: "\(try! Person.aclProperty() ?? Person.EntityCodingKeys.acl.rawValue).creator == %@", client.activeUser!.userId)
        
        do {
            var mockCount = 0
            if useMockData {
                mockResponse { request in
                    mockCount += 1
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                        json: [
                            [
                                "_id" : mockObjectId!,
                                "name" : "Victor",
                                "age" : 0,
                                "_acl" : [
                                    "creator" : self.client.activeUser?.userId
                                ],
                                "_kmd" : [
                                    "lmt" : mockDate?.toISO8601(),
                                    "ect" : mockDate?.toISO8601()
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
            
            store.find(query, options: try! Options(readPolicy: .forceNetwork)) {
                switch $0 {
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
        
        do {
            var mockCount = 0
            if useMockData {
                mockResponse { request in
                    mockCount += 1
                    XCTAssertEqual(request.url!.path, "/appdata/_kid_/Person/_deltaset")
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
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
            
            store.find(query, options: try! Options(readPolicy: .forceNetwork)) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
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
        
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        let person = Person()
        person.name = "Victor"
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person) {
            XCTAssertTrue(Thread.isMainThread)
            switch $0 {
            case .success:
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
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
                        "lmt" : mockDate?.toISO8601(),
                        "ect" : mockDate?.toISO8601()
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
        
        let query = Query(format: "\(try! Person.aclProperty() ?? Person.EntityCodingKeys.acl.rawValue).creator == %@", client.activeUser!.userId)
        
        do {
            var mockCount = 0
            if useMockData {
                mockResponse { request in
                    mockCount += 1
                    XCTAssertEqual(request.url!.path, "/appdata/_kid_/Person")
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                        json: [
                            [
                                "_id" : mockObjectId!,
                                "name" : "Victor",
                                "age" : 0,
                                "_acl" : [
                                    "creator" : self.client.activeUser?.userId
                                ],
                                "_kmd" : [
                                    "lmt" : Date(timeInterval: 1, since: mockDate!).toISO8601(),
                                    "ect" : mockDate?.toISO8601()
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
            
            store.find(query, options: try! Options(readPolicy: .forceNetwork)) {
                switch $0 {
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
        
        do {
            var mockCount = 0
            if useMockData {
                mockResponse { request in
                    mockCount += 1
                    XCTAssertEqual(request.url!.path, "/appdata/_kid_/Person/_deltaset")
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
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
                                        "lmt" : Date(timeInterval: 1, since: mockDate!).toISO8601(),
                                        "ect" : mockDate?.toISO8601()
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

            store.find(query, options: try! Options(readPolicy: .forceNetwork)) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
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
        
        let queryFields = Query(query) {
            $0.fields = ["age", "_kmd"]
        }
        
        do {
            var mockCount = 0
            if useMockData {
                mockResponse { request in
                    mockCount += 1
                    let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                    let fieldsString = urlComponents.queryItems?.filter({ $0.name == "fields" }).first?.value
                    let fields = fieldsString!.split(separator: ",").sorted()
                    XCTAssertEqual(fields.count, 2)
                    XCTAssertEqual(fields.first, "_kmd")
                    XCTAssertEqual(fields.last, "age")
                    XCTAssertEqual(urlComponents.path, "/appdata/_kid_/Person/")
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                        json: [
                            [
                                "_id" : mockObjectId!,
                                "age" : 1,
                                "_acl" : [
                                    "creator" : self.client.activeUser?.userId
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
            
            store.find(queryFields, options: try! Options(readPolicy: .forceNetwork)) {
                switch $0 {
                case .success(let results):
                    XCTAssertEqual(results.count, 1)
                    
                    if let person = results.first {
                        XCTAssertNil(person.name)
                        XCTAssertEqual(person.age, 1)
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
        
        do {
            var mockCount = 0
            if useMockData {
                mockResponse { request in
                    mockCount += 1
                    let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                    let fieldsString = urlComponents.queryItems?.filter({ $0.name == "fields" }).first?.value
                    let fields = fieldsString!.split(separator: ",").sorted()
                    XCTAssertEqual(fields.count, 2)
                    XCTAssertEqual(fields.first, "_kmd")
                    XCTAssertEqual(fields.last, "age")
                    XCTAssertEqual(urlComponents.path, "/appdata/_kid_/Person/_deltaset")
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                        json: [
                            "changed" : [
                                [
                                    "_id" : mockObjectId!,
                                    "age" : 2,
                                    "_acl" : [
                                        "creator" : self.client.activeUser?.userId
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

            store.find(queryFields, options: try! Options(readPolicy: .forceNetwork)) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success(let results):
                    XCTAssertEqual(results.count, 1)
                    
                    if let person = results.first {
                        XCTAssertNil(person.name)
                        XCTAssertEqual(person.age, 2)
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
        
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        let person = Person()
        person.name = "Victor"
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person) {
            XCTAssertTrue(Thread.isMainThread)
            switch $0 {
            case .success:
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
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
        
        let query = Query(format: "\(try! Person.aclProperty() ?? Person.EntityCodingKeys.acl.rawValue).creator == %@", client.activeUser!.userId)
        
        do {
            if useMockData {
                mockResponse(
                    headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
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
            
            store.find(query, options: try! Options(readPolicy: .forceNetwork)) {
                switch $0 {
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
        
        do {
            var mockCount = 0
            if useMockData {
                mockResponse { request in
                    mockCount += 1
                    XCTAssertEqual(request.url!.path, "/appdata/_kid_/Person/_deltaset")
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
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
                                        "lmt" : Date(timeInterval: 1, since: mockDate!).toISO8601(),
                                        "ect" : mockDate?.toISO8601()
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
            
            store.find(query, options: try! Options(readPolicy: .forceNetwork)) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
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
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        do {
            let person = Person()
            person.name = "Victor"
            
            weak var expectationSave = expectation(description: "Save")
            
            store.save(person) {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
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
        
        store.find(options: try! Options(readPolicy: .forceNetwork)) {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTimeoutError(error)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationFind = nil
        }
    }
    
    func testFind201RecordsDeltaSet() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        let person = Person()
        person.name = "Victor"
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person) {
            XCTAssertTrue(Thread.isMainThread)
            switch $0 {
            case .success:
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
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
                    "lmt" : Date().toISO8601(),
                    "ect" : Date().toISO8601()
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
        
        let query = Query(format: "\(try! Person.aclProperty() ?? Person.EntityCodingKeys.acl.rawValue).creator == %@", client.activeUser!.userId)
        
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
                    "lmt" : Date().toISO8601(),
                    "ect" : Date().toISO8601()
                ]
            ])
        }
        
        do {
            mockResponse(headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()], json: jsonArray)
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(options: try! Options(readPolicy: .forceNetwork)) {
                switch $0 {
                case .success(let results):
                    XCTAssertEqual(results.count, 201)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
        
        do {
            mockResponse { response in
                let urlComponents = URLComponents(url: response.url!, resolvingAgainstBaseURL: false)!
                XCTAssertEqual(urlComponents.path.components(separatedBy: "/").last, "_deltaset")
                return HttpResponse(
                    headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                    json: [
                        "changed" : [],
                        "deleted" : []
                    ]
                )
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(options: try! Options(readPolicy: .forceNetwork)) {
                switch $0 {
                case .success(let results):
                    XCTAssertEqual(results.count, 201)
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
    
    func testFind201RecordsDeltaSetTimeoutOn2ndRequest() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        let person = Person()
        person.name = "Victor"
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person) {
            XCTAssertTrue(Thread.isMainThread)
            switch $0 {
            case .success:
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
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
                    "lmt" : Date().toISO8601(),
                    "ect" : Date().toISO8601()
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
        
        let query = Query(format: "\(try! Person.aclProperty() ?? Person.EntityCodingKeys.acl.rawValue).creator == %@", client.activeUser!.userId)
        
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
                    "lmt" : Date().toISO8601(),
                    "ect" : Date().toISO8601()
                ]
            ])
        }
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(options: try! Options(readPolicy: .forceNetwork)) {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                break
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationFind = nil
        }
    }
    
    func testDeltaSetQuerySkipLimit() {
        mockResponse { request in
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            let skip = urlComponents?.queryItems?.filter({ $0.name == "skip" }).first?.value
            let limit = urlComponents?.queryItems?.filter({ $0.name == "limit" }).first?.value
            XCTAssertEqual(skip, "100")
            XCTAssertNil(limit)
            switch request.url!.path {
            case "/appdata/_kid_/Person":
                return HttpResponse(json: [
                    [
                        "_id" : UUID().uuidString,
                        "name" : UUID().uuidString,
                        "age" : 0,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : [
                            "lmt" : Date().toISO8601(),
                            "ect" : Date().toISO8601()
                        ]
                    ]
                ])
            default:
                XCTFail(request.url!.path)
                Swift.fatalError(request.url!.path)
            }
        }
        
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        weak var expectationPull = expectation(description: "Pull")
        
        let query = Query()
        query.skip = 100
        store.pull(query) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
            switch result {
            case .success(let results):
                XCTAssertEqual(results.count, 1)
                XCTAssertNotNil(results.first)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectationPull?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationPull = nil
        }
    }
    
    func testDeltaSetAutoPaginationOnQuerySkipLimit() {
        mockResponse { request in
            switch request.url!.path {
            case "/appdata/_kid_/Person/_count":
                return HttpResponse(json: ["count" : 1])
            case "/appdata/_kid_/Person":
                let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
                let skip = urlComponents?.queryItems?.filter({ $0.name == "skip" }).first?.value
                let limit = urlComponents?.queryItems?.filter({ $0.name == "limit" }).first?.value
                XCTAssertEqual(skip, "0")
                XCTAssertEqual(limit, "1")
                return HttpResponse(json: [
                    [
                        "_id" : UUID().uuidString,
                        "name" : UUID().uuidString,
                        "age" : 0,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : [
                            "lmt" : Date().toISO8601(),
                            "ect" : Date().toISO8601()
                        ]
                    ]
                ])
            default:
                XCTFail(request.url!.path)
                Swift.fatalError(request.url!.path)
            }
        }
        
        let store = try! DataStore<Person>.collection(.sync, autoPagination: true, options: try! Options(deltaSet: true))
        
        weak var expectationPull = expectation(description: "Pull")
        
        let query = Query()
        query.skip = 100
        query.limit = 500
        store.pull(query) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
            switch result {
            case .success(let results):
                XCTAssertEqual(results.count, 1)
                XCTAssertNotNil(results.first)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectationPull?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationPull = nil
        }
    }
    
    func testDeltaSetQuerySkipLimit2ndRequestWithoutSkipAndLimit() {
        mockResponse { request in
            switch request.url!.path {
            case "/appdata/_kid_/Person":
                return HttpResponse(
                    headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                    json: [
                        [
                            "_id" : UUID().uuidString,
                            "name" : UUID().uuidString,
                            "age" : 0,
                            "_acl" : [
                                "creator" : UUID().uuidString
                            ],
                            "_kmd" : [
                                "lmt" : Date().toISO8601(),
                                "ect" : Date().toISO8601()
                            ]
                        ]
                    ]
                )
            default:
                XCTFail(request.url!.path)
                Swift.fatalError(request.url!.path)
            }
        }
        
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        do {
            weak var expectationPull = expectation(description: "Pull")
            
            let query = Query()
            query.skip = 100
            store.pull(query) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success(let results):
                    XCTAssertEqual(results.count, 1)
                    XCTAssertNotNil(results.first)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationPull = nil
            }
        }
        
        XCTAssertNil(store.cache?.lastSync(query: Query()))
        
        do {
            weak var expectationPull = expectation(description: "Pull")
            
            let query = Query()
            store.pull(query) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success(let results):
                    XCTAssertEqual(results.count, 1)
                    XCTAssertNotNil(results.first)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationPull = nil
            }
        }
        
        XCTAssertNotNil(store.cache?.lastSync(query: Query()))
    }
    
    func testDeltaSet3rdPull() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        var date1: String?
        var date2: String?
        var date3: String?
        
        do {
            mockResponse { request in
                switch request.url!.path {
                case "/appdata/_kid_/Person":
                    date1 = Date().toISO8601()
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : date1!],
                        json: [
                            [
                                "_id" : UUID().uuidString,
                                "name" : UUID().uuidString,
                                "age" : 0,
                                "_acl" : [
                                    "creator" : self.client.activeUser!.userId
                                ],
                                "_kmd" : [
                                    "lmt" : Date().toISO8601(),
                                    "ect" : Date().toISO8601()
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
                    date2 = Date().toISO8601()
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
                                    "_id" : UUID().uuidString,
                                    "name" : UUID().uuidString,
                                    "age" : 0,
                                    "_acl" : [
                                        "creator" : self.client.activeUser!.userId
                                    ],
                                    "_kmd" : [
                                        "lmt" : Date().toISO8601(),
                                        "ect" : Date().toISO8601()
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
        
        Thread.sleep(until: Date(timeIntervalSinceNow: 1))
        
        do {
            mockResponse { request in
                switch request.url!.path {
                case "/appdata/_kid_/Person/_deltaset":
                    date3 = Date().toISO8601()
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
                                    "_id" : UUID().uuidString,
                                    "name" : UUID().uuidString,
                                    "age" : 0,
                                    "_acl" : [
                                        "creator" : self.client.activeUser!.userId
                                    ],
                                    "_kmd" : [
                                        "lmt" : Date().toISO8601(),
                                        "ect" : Date().toISO8601()
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
            XCTAssertEqual(results.count, 3)
        }
    }
    
    func testDeltaSet3rdPullDifferentClassName() {
        signUp()
        
        let store = try! DataStore<PersonWithDifferentClassName>.collection(.sync, options: try! Options(deltaSet: true))
        
        var date1: String?
        var date2: String?
        var date3: String?
        
        do {
            mockResponse { request in
                switch request.url!.path {
                case "/appdata/_kid_/Person":
                    date1 = Date().toISO8601()
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : date1!],
                        json: [
                            [
                                "_id" : UUID().uuidString,
                                "name" : UUID().uuidString,
                                "age" : 0,
                                "_acl" : [
                                    "creator" : self.client.activeUser!.userId
                                ],
                                "_kmd" : [
                                    "lmt" : Date().toISO8601(),
                                    "ect" : Date().toISO8601()
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
                    date2 = Date().toISO8601()
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
                                    "_id" : UUID().uuidString,
                                    "name" : UUID().uuidString,
                                    "age" : 0,
                                    "_acl" : [
                                        "creator" : self.client.activeUser!.userId
                                    ],
                                    "_kmd" : [
                                        "lmt" : Date().toISO8601(),
                                        "ect" : Date().toISO8601()
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
        
        Thread.sleep(until: Date(timeIntervalSinceNow: 1))
        
        do {
            mockResponse { request in
                switch request.url!.path {
                case "/appdata/_kid_/Person/_deltaset":
                    date3 = Date().toISO8601()
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
                                    "_id" : UUID().uuidString,
                                    "name" : UUID().uuidString,
                                    "age" : 0,
                                    "_acl" : [
                                        "creator" : self.client.activeUser!.userId
                                    ],
                                    "_kmd" : [
                                        "lmt" : Date().toISO8601(),
                                        "ect" : Date().toISO8601()
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
            XCTAssertEqual(results.count, 3)
        }
    }
    
    func testDeltaSetChangeFromSyncToCache() {
        signUp()
        
        var store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
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
                        date1 = Date().toISO8601()
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
                                        "lmt" : Date().toISO8601(),
                                        "ect" : Date().toISO8601()
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
                        date2 = Date().toISO8601()
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
                                            "lmt" : Date().toISO8601(),
                                            "ect" : Date().toISO8601()
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
        
        store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
        
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        date3 = Date().toISO8601()
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
                                            "lmt" : Date().toISO8601(),
                                            "ect" : Date().toISO8601()
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
        
        var store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
        
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
                        date1 = Date().toISO8601()
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
                                        "lmt" : Date().toISO8601(),
                                        "ect" : Date().toISO8601()
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
                        date2 = Date().toISO8601()
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
                                            "lmt" : Date().toISO8601(),
                                            "ect" : Date().toISO8601()
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
        
        store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person/_deltaset":
                        date3 = Date().toISO8601()
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
                                            "lmt" : Date().toISO8601(),
                                            "ect" : Date().toISO8601()
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
        
        var store = try! DataStore<Person>.collection(.network, options: nil)
        
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
                        date1 = Date().toISO8601()
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
                                        "lmt" : Date().toISO8601(),
                                        "ect" : Date().toISO8601()
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
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        store = try! DataStore<Person>.collection(.cache, options: try! Options(deltaSet: true))
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person":
                        date2 = Date().toISO8601()
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
                                        "lmt" : Date().toISO8601(),
                                        "ect" : Date().toISO8601()
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
                                        "lmt" : Date().toISO8601(),
                                        "ect" : Date().toISO8601()
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
                        date3 = Date().toISO8601()
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
                                            "lmt" : Date().toISO8601(),
                                            "ect" : Date().toISO8601()
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
            } else {
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
        
        var store = try! DataStore<Person>.collection(.network, options: nil)
        
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
                        date1 = Date().toISO8601()
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
                                        "lmt" : Date().toISO8601(),
                                        "ect" : Date().toISO8601()
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
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        do {
            if useMockData{
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/_kid_/Person":
                        date2 = Date().toISO8601()
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
                                        "lmt" : Date().toISO8601(),
                                        "ect" : Date().toISO8601()
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
                                        "lmt" : Date().toISO8601(),
                                        "ect" : Date().toISO8601()
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
                        date3 = Date().toISO8601()
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
                                            "lmt" : Date().toISO8601(),
                                            "ect" : Date().toISO8601()
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
            } else {
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
        
        let store = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        var date1: String?
        var date2: String?
        var date3: String?
        
        do {
            mockResponse { request in
                switch request.url!.path {
                case "/appdata/_kid_/Person":
                    date1 = Date().toISO8601()
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
                                    "lmt" : Date().toISO8601(),
                                    "ect" : Date().toISO8601()
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
                    date2 = Date().toISO8601()
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
                                        "lmt" : Date().toISO8601(),
                                        "ect" : Date().toISO8601()
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
    
    func testDeltaSetAndAutoPagination() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.sync, autoPagination: true, options: try! Options(deltaSet: true))
        
        let count = useMockData ? 3 : try! store.count(options: Options(readPolicy: .forceNetwork)).waitForResult(timeout: defaultTimeout).value()
        
        do {
            var requestStartDates = [Date]()
            if useMockData {
                var count = 0
                mockResponse { request in
                    defer {
                        count += 1
                    }
                    let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                    switch count {
                    case 0:
                        switch urlComponents.path {
                        case "/appdata/\(sharedClient.appKey!)/\(Person.collectionName())/_count":
                            let requestStartDate = Date()
                            requestStartDates.append(requestStartDate)
                            return HttpResponse(
                                headerFields: ["X-Kinvey-Request-Start" : requestStartDate.toISO8601()],
                                json: ["count" : 3]
                            )
                        default:
                            XCTFail(urlComponents.path)
                            return HttpResponse(statusCode: 404, data: Data())
                        }
                    case 1, 2, 3:
                        switch urlComponents.path {
                        case "/appdata/\(sharedClient.appKey!)/\(Person.collectionName())/":
                            let skip = urlComponents.queryItems?.filter({ $0.name == "skip" }).first?.value
                            let limit = urlComponents.queryItems?.filter({ $0.name == "limit" }).first?.value
                            XCTAssertNotNil(skip)
                            XCTAssertNotNil(limit)
                            XCTAssertEqual(limit, "1")
                            XCTAssertEqual(skip, "\(count - 1)")
                            Thread.sleep(forTimeInterval: 1.0)
                            let requestStartDate = Date()
                            requestStartDates.append(requestStartDate)
                            return HttpResponse(
                                headerFields: ["X-Kinvey-Request-Start" : requestStartDate.toISO8601()],
                                json: [
                                    [
                                        "_id" : UUID().uuidString,
                                        "name" : "Victor",
                                        "age" : 0,
                                        "_acl" : [
                                            "creator" : self.client.activeUser!.userId
                                        ],
                                        "_kmd" : [
                                            "lmt" : Date().toISO8601(),
                                            "ect" : Date().toISO8601()
                                        ]
                                    ]
                                ]
                            )
                        default:
                            XCTFail(urlComponents.path)
                            return HttpResponse(statusCode: 404, data: Data())
                        }
                    default:
                        XCTFail(urlComponents.path)
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                }
            }
            defer {
                setURLProtocol(nil)
            }
            
            let results = try store.pull(options: Options(maxSizePerResultSet: 1)).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(results.count, count)
            
            XCTAssertEqual(requestStartDates.count, 4)
            XCTAssertTrue(store.cache?.cache is RealmCache<Person>)
            XCTAssertNotNil(store.cache?.cache as? RealmCache<Person>)
            if let cache = store.cache?.cache as? RealmCache<Person> {
                let realm = cache.newRealm
                let results = realm.objects(_QueryCache.self).filter("collectionName == 'Person' AND query == nil")
                XCTAssertNotNil(results.first)
                XCTAssertNotNil(results.first?.lastSync)
                XCTAssertNotNil(requestStartDates.first)
                if let lastSync = results.first?.lastSync,
                    let firstRequestStartDate = requestStartDates.first
                {
                    XCTAssertEqual(lastSync.timeIntervalSinceReferenceDate, firstRequestStartDate.timeIntervalSinceReferenceDate, accuracy: 0.1)
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        do {
            if useMockData {
                mockResponse { request in
                    switch request.url!.path {
                    case "/appdata/\(sharedClient.appKey!)/\(Person.collectionName())/_deltaset":
                        return HttpResponse(
                            headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                            json: [
                                "changed" : [
                                    [
                                        "_id" : UUID().uuidString,
                                        "name" : "Victor",
                                        "age" : 0,
                                        "_acl" : [
                                            "creator" : self.client.activeUser!.userId
                                        ],
                                        "_kmd" : [
                                            "lmt" : Date().toISO8601(),
                                            "ect" : Date().toISO8601()
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
            }
            defer {
                setURLProtocol(nil)
            }
            
            let results = try store.pull(options: Options(maxSizePerResultSet: 1)).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(Int(results.count), count + 1)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testServerSideDeltaSetMissingConfiguration() {
        signUp()
        
        let dataStore = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        var count: Int? = nil
        
        var mockRequestPathSequence = [String]()
        if useMockData {
            mockResponse { request in
                mockRequestPathSequence.append(request.url!.path)
                switch request.url!.path {
                case "/appdata/_kid_/Person/_count":
                    return HttpResponse(json: [
                        "count" : 1
                    ])
                case "/appdata/_kid_/Person/_deltaset":
                    return HttpResponse(
                        statusCode: 403,
                        json: [
                            "error": "MissingConfiguration",
                            "description": "This feature is not properly configured for this app backend. Please configure it through the console first, or contact support for more information.",
                            "debug": "This collection has not been configured for Delta Set access."
                        ]
                    )
                case "/appdata/_kid_/Person":
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                        json: [
                            [
                                "_id" : UUID().uuidString,
                                "name" : "Victor",
                                "age" : 0,
                                "_acl" : [
                                    "creator" : self.client.activeUser!.userId
                                ],
                                "_kmd" : [
                                    "lmt" : Date().toISO8601(),
                                    "ect" : Date().toISO8601()
                                ]
                            ]
                        ]
                    )
                default:
                    XCTFail(request.url!.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
        }
        defer {
            if useMockData {
                XCTAssertEqual(mockRequestPathSequence.count, 4)
                if mockRequestPathSequence.count == 4 {
                    XCTAssertEqual(mockRequestPathSequence[0], "/appdata/_kid_/Person/_count")
                    XCTAssertEqual(mockRequestPathSequence[1], "/appdata/_kid_/Person")
                    XCTAssertEqual(mockRequestPathSequence[2], "/appdata/_kid_/Person/_deltaset")
                    XCTAssertEqual(mockRequestPathSequence[3], "/appdata/_kid_/Person")
                }
                setURLProtocol(nil)
            }
        }
        
        do {
            count = try dataStore.count(options: Options(readPolicy: .forceNetwork)).waitForResult().value()
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        XCTAssertNotNil(count)
        
        guard let count1 = count else {
            return
        }
        
        do {
            let results = try dataStore.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(results.count, count1)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        XCTAssertNotNil(count)
        
        guard let count2 = count else {
            return
        }
        
        do {
            let results = try dataStore.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(results.count, count2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testServerSideDeltaSetMissingConfigurationAutoPaginationOn() {
        signUp()
        
        let dataStore = try! DataStore<Person>.collection(.sync, autoPagination: true, options: try! Options(deltaSet: true))
        
        var count: Int? = nil
        
        var mockRequestPathSequence = [String]()
        if useMockData {
            var json = [JsonDictionary]()
            for i in 0 ..< 10 {
                json.append([
                    "_id" : UUID().uuidString,
                    "name" : UUID().uuidString,
                    "age" : 0,
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
                mockRequestPathSequence.append(urlComponents.path)
                switch urlComponents.path {
                case "/appdata/_kid_/Person/_count":
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                        json: ["count" : json.count]
                    )
                case "/appdata/_kid_/Person/_deltaset":
                    return HttpResponse(
                        statusCode: 403,
                        json: [
                            "error": "MissingConfiguration",
                            "description": "This feature is not properly configured for this app backend. Please configure it through the console first, or contact support for more information.",
                            "debug": "This collection has not been configured for Delta Set access."
                        ]
                    )
                case "/appdata/_kid_/Person/":
                    let skip = urlComponents.queryItems?.filter({ $0.name == "skip" && $0.value != nil && Int($0.value!) != nil }).map({ Int($0.value!)! }).first ?? json.startIndex
                    let limit = urlComponents.queryItems?.filter({ $0.name == "limit" && $0.value != nil && Int($0.value!) != nil }).map({ Int($0.value!)! }).first ?? json.endIndex
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                        json: Array(json[skip ..< skip + limit])
                    )
                default:
                    XCTFail(urlComponents.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
        }
        defer {
            if useMockData {
                XCTAssertEqual(mockRequestPathSequence.count, 9)
                if mockRequestPathSequence.count == 9 {
                    XCTAssertEqual(mockRequestPathSequence[0], "/appdata/_kid_/Person/_count")
                    XCTAssertEqual(mockRequestPathSequence[1], "/appdata/_kid_/Person/_count")
                    XCTAssertEqual(mockRequestPathSequence[2], "/appdata/_kid_/Person/")
                    XCTAssertEqual(mockRequestPathSequence[3], "/appdata/_kid_/Person/_deltaset")
                    XCTAssertEqual(mockRequestPathSequence[4], "/appdata/_kid_/Person/_count")
                    XCTAssertEqual(mockRequestPathSequence[5], "/appdata/_kid_/Person/")
                    XCTAssertEqual(mockRequestPathSequence[6], "/appdata/_kid_/Person/")
                    XCTAssertEqual(mockRequestPathSequence[7], "/appdata/_kid_/Person/")
                    XCTAssertEqual(mockRequestPathSequence[8], "/appdata/_kid_/Person/")
                }
                setURLProtocol(nil)
            }
        }
        
        do {
            count = try dataStore.count(options: Options(readPolicy: .forceNetwork)).waitForResult().value()
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        XCTAssertNotNil(count)
        
        guard let count1 = count else {
            return
        }
        
        do {
            let results = try dataStore.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(results.count, count1)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        XCTAssertNotNil(count)
        
        guard let count2 = count else {
            return
        }
        
        do {
            let options = try! Options(maxSizePerResultSet: 3)
            let results = try dataStore.pull(options: options).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(results.count, count2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testServerSideDeltaSetParameterValueOutOfRange() {
        signUp()
        
        let dataStore = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        var count: Int? = nil
        
        var mockRequestPathSequence = [String]()
        if useMockData {
            var json = [
                [
                    "_id" : UUID().uuidString,
                    "name" : UUID().uuidString,
                    "age" : 0,
                    "_acl" : [
                        "creator" : self.client.activeUser!.userId
                    ],
                    "_kmd" : [
                        "lmt" : Date().toISO8601(),
                        "ect" : Date().toISO8601()
                    ]
                ],
                [
                    "_id" : UUID().uuidString,
                    "name" : UUID().uuidString,
                    "age" : 0,
                    "_acl" : [
                        "creator" : self.client.activeUser!.userId
                    ],
                    "_kmd" : [
                        "lmt" : Date().toISO8601(),
                        "ect" : Date().toISO8601()
                    ]
                ]
            ]
            mockResponse { request in
                mockRequestPathSequence.append(request.url!.path)
                switch request.url!.path {
                case "/appdata/_kid_/Person/_count":
                    return HttpResponse(json: [
                        "count" : json.count
                    ])
                case "/appdata/_kid_/Person/_deltaset":
                    return HttpResponse(
                        statusCode: 400,
                        json: [
                            "error": "ParameterValueOutOfRange",
                            "description": "The value specified for one of the request parameters is out of range",
                            "debug": "The 'since' timestamp cannot be earlier than the date at which delta set was enabled for this collection."
                        ]
                    )
                case "/appdata/_kid_/Person":
                    defer {
                        if json.count > 0 {
                            json.removeLast()
                        }
                    }
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                        json: json
                    )
                default:
                    XCTFail(request.url!.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
        }
        defer {
            if useMockData {
                XCTAssertEqual(mockRequestPathSequence.count, 4)
                if mockRequestPathSequence.count == 4 {
                    XCTAssertEqual(mockRequestPathSequence[0], "/appdata/_kid_/Person/_count")
                    XCTAssertEqual(mockRequestPathSequence[1], "/appdata/_kid_/Person")
                    XCTAssertEqual(mockRequestPathSequence[2], "/appdata/_kid_/Person/_deltaset")
                    XCTAssertEqual(mockRequestPathSequence[3], "/appdata/_kid_/Person")
                }
                setURLProtocol(nil)
            }
        }
        
        do {
            count = try dataStore.count(options: Options(readPolicy: .forceNetwork)).waitForResult().value()
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        XCTAssertNotNil(count)
        
        guard let count1 = count else {
            return
        }
        
        do {
            let results = try dataStore.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(results.count, count1)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        XCTAssertNotNil(count)
        
        guard let count2 = count else {
            return
        }
        
        do {
            let results = try dataStore.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(results.count, count2 - 1)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        do {
            let count = try dataStore.count(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(count, count2 - 1)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testDeltaSetHandler() {
        signUp()
        
        let dataStore = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        do {
            mockResponse { request in
                switch request.url!.path {
                case "/appdata/_kid_/Person":
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                        json: [
                            [
                                "_id" : "58450d87f29e22207c83a237",
                                "name" : "Victor Hugo",
                                "age" : 0,
                                "_acl" : [
                                    "creator" : self.client.activeUser!.userId
                                ],
                                "_kmd" : [
                                    "lmt" : Date().toISO8601(),
                                    "ect" : Date().toISO8601()
                                ]
                            ],
                            [
                                "_id" : "58450d87f29e22207c83a238",
                                "name" : "Victor Carvalho",
                                "age" : 0,
                                "_acl" : [
                                    "creator" : self.client.activeUser!.userId
                                ],
                                "_kmd" : [
                                    "lmt" : Date().toISO8601(),
                                    "ect" : Date().toISO8601()
                                ]
                            ],
                            [
                                "_id" : "58450d87f29e22207c83a239",
                                "name" : "Victor Barros",
                                "age" : 0,
                                "_acl" : [
                                    "creator" : self.client.activeUser!.userId
                                ],
                                "_kmd" : [
                                    "lmt" : Date().toISO8601(),
                                    "ect" : Date().toISO8601()
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
            
            weak var expectationPull = expectation(description: "Pull")
            
            dataStore.pull() { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success(let results):
                    XCTAssertEqual(results.count, 3)
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
            mockResponse { request in
                switch request.url!.path {
                case "/appdata/_kid_/Person/_deltaset":
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                        json: [
                            "changed" : [
                                [
                                    "_id" : "58450d87f29e22207c83a239",
                                    "name" : "Victor",
                                    "age" : 0,
                                    "_acl" : [
                                        "creator" : self.client.activeUser!.userId
                                    ],
                                    "_kmd" : [
                                        "lmt" : Date().toISO8601(),
                                        "ect" : Date().toISO8601()
                                    ]
                                ]
                            ],
                            "deleted" : [
                                ["_id" : "58450d87f29e22207c83a237"],
                                ["_id" : "58450d87f29e22207c83a238"]
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

            weak var expectationPull = expectation(description: "Pull")

            var deltaSetCompletionHandlerCalled = false

            dataStore.pull(
                deltaSetCompletionHandler: { (changed, deleted) in
                    deltaSetCompletionHandlerCalled = true
                    
                    XCTAssertTrue(Thread.isMainThread)
                    
                    XCTAssertEqual(changed.count, 1)
                    XCTAssertEqual(deleted.count, 2)
                    
                    if let person = changed.first {
                        XCTAssertEqual(person.name, "Victor")
                    }
                }
            ) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
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
            
            XCTAssertTrue(deltaSetCompletionHandlerCalled)
        }
    }
    
    func testServerSideDeltaSetQueryWithFields() {
        signUp()
        
        let dataStore = try! DataStore<Person>.collection(.sync, options: try! Options(deltaSet: true))
        
        let json = [
            [
                "_id" : "58450d87f29e22207c83a237",
                "name" : "Victor Hugo",
                "age" : 1,
                "_acl" : [
                    "creator" : self.client.activeUser!.userId
                ],
                "_kmd" : [
                    "lmt" : Date().toISO8601(),
                    "ect" : Date().toISO8601()
                ]
            ],
            [
                "_id" : "58450d87f29e22207c83a239",
                "name" : "Victor Barros",
                "age" : 2,
                "_acl" : [
                    "creator" : self.client.activeUser!.userId
                ],
                "_kmd" : [
                    "lmt" : Date().toISO8601(),
                    "ect" : Date().toISO8601()
                ]
            ]
        ]
        var count = 0
        mockResponse { request in
            defer {
                count += 1
            }
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            switch urlComponents.path {
            case "/appdata/_kid_/Person/":
                switch count {
                case 0:
                    let fields = urlComponents.queryItems?.filter({ $0.name == "fields" }).first?.value?.split(separator: ",").sorted()
                    XCTAssertEqual(fields?.count, 2)
                    XCTAssertEqual(fields?.first, "address")
                    XCTAssertEqual(fields?.last, "name")
                default:
                    break
                }
                let fields = urlComponents.queryItems?.filter({ $0.name == "fields" }).first?.value
                var json = json
                if var fields = fields?.split(separator: ",").map({ String($0) }) {
                    fields.append(contentsOf: ["_id", "_acl"])
                    let fields = Set(fields)
                    json = json.map {
                        $0.filter { fields.contains($0.key) }
                    }
                }
                return HttpResponse(
                    headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                    json: json
                )
            default:
                XCTFail(request.url!.path)
                return HttpResponse(statusCode: 404, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let query1 = Query(fields: ["name", "address"])
    
        do {
            weak var expectationPull = expectation(description: "Pull")
        
            dataStore.pull(query1) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success(let results):
                    XCTAssertEqual(results.count, 2)
                    XCTAssertEqual(results.first?.age, 0)
                    XCTAssertEqual(results.last?.age, 0)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationPull?.fulfill()
            }
        
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        XCTAssertNotNil(dataStore.cache?.lastSync(query: query1))
        XCTAssertTrue(dataStore.cache?.cache is RealmCache<Person>)
        XCTAssertNotNil(dataStore.cache?.cache as? RealmCache<Person>)
        if let realmCache = dataStore.cache?.cache as? RealmCache<Person> {
            XCTAssertEqual(realmCache.lastSync(query: query1, realm: realmCache.newRealm)?.first?.fields, "address,name")
        }
        
        do {
            weak var expectationPull = expectation(description: "Pull")

            var deltaSetCompletionHandlerCalled = false

            dataStore.pull(
                deltaSetCompletionHandler: { (changed, deleted) in
                    deltaSetCompletionHandlerCalled = true
                    XCTFail("Delta Set Completion Handler was not expected to be called")
                }
            ) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success(let results):
                    XCTAssertEqual(results.count, 2)
                    XCTAssertEqual(results.first?.age, 1)
                    XCTAssertEqual(results.last?.age, 2)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationPull?.fulfill()
            }

            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
            
            XCTAssertFalse(deltaSetCompletionHandlerCalled)
            
            XCTAssertNil(dataStore.cache?.lastSync(query: query1))
            XCTAssertNotNil(dataStore.cache?.lastSync(query: Query()))
            
            XCTAssertTrue(dataStore.cache?.cache is RealmCache<Person>)
            XCTAssertNotNil(dataStore.cache?.cache as? RealmCache<Person>)
            if let realmCache = dataStore.cache?.cache as? RealmCache<Person> {
                do {
                    let queryCache = realmCache.lastSync(query: Query(), realm: realmCache.newRealm)?.first
                    XCTAssertNotNil(queryCache)
                    XCTAssertNil(queryCache?.fields)
                    XCTAssertEqual(queryCache?.key, "Person|nil")
                }
            }
        }
    }
    
    func serverSideDeltaSetResultSetSizeExceeded(autoPagination: Bool) {
        signUp()
        
        let dataStore = try! DataStore<Person>.collection(
            .sync,
            autoPagination: autoPagination,
            options: try! Options(deltaSet: true)
        )
        
        var count: Int? = nil
        
        var mockRequestPathSequence = [String]()
        if useMockData {
            var json = [
                [
                    "_id" : UUID().uuidString,
                    "name" : UUID().uuidString,
                    "age" : 0,
                    "_acl" : [
                        "creator" : self.client.activeUser!.userId
                    ],
                    "_kmd" : [
                        "lmt" : Date().toISO8601(),
                        "ect" : Date().toISO8601()
                    ]
                ],
                [
                    "_id" : UUID().uuidString,
                    "name" : UUID().uuidString,
                    "age" : 0,
                    "_acl" : [
                        "creator" : self.client.activeUser!.userId
                    ],
                    "_kmd" : [
                        "lmt" : Date().toISO8601(),
                        "ect" : Date().toISO8601()
                    ]
                ]
            ]
            mockResponse { request in
                mockRequestPathSequence.append(request.url!.path)
                switch request.url!.path {
                case "/appdata/_kid_/Person/_count":
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                        json: ["count" : json.count]
                    )
                case "/appdata/_kid_/Person/_deltaset":
                    return HttpResponse(
                        statusCode: 400,
                        json: [
                            "error": "ResultSetSizeExceeded",
                            "description" : "Your query produced more than 10,000 results. Please rewrite your query to be more selective.",
                            "debug" : "Your query returned 10,001 results"
                        ]
                    )
                case "/appdata/_kid_/Person":
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                        json: json
                    )
                default:
                    XCTFail(request.url!.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
        }
        defer {
            if useMockData {
                if autoPagination {
                    XCTAssertEqual(mockRequestPathSequence.count, 6)
                    if mockRequestPathSequence.count == 6 {
                        XCTAssertEqual(mockRequestPathSequence[0], "/appdata/_kid_/Person/_count")
                        XCTAssertEqual(mockRequestPathSequence[1], "/appdata/_kid_/Person/_count")
                        XCTAssertEqual(mockRequestPathSequence[2], "/appdata/_kid_/Person")
                        XCTAssertEqual(mockRequestPathSequence[3], "/appdata/_kid_/Person/_deltaset")
                        XCTAssertEqual(mockRequestPathSequence[4], "/appdata/_kid_/Person/_count")
                        XCTAssertEqual(mockRequestPathSequence[5], "/appdata/_kid_/Person")
                    }
                } else {
                    XCTAssertEqual(mockRequestPathSequence.count, 3)
                    if mockRequestPathSequence.count == 3 {
                        XCTAssertEqual(mockRequestPathSequence[0], "/appdata/_kid_/Person/_count")
                        XCTAssertEqual(mockRequestPathSequence[1], "/appdata/_kid_/Person")
                        XCTAssertEqual(mockRequestPathSequence[2], "/appdata/_kid_/Person/_deltaset")
                    }
                }
                setURLProtocol(nil)
            }
        }
        
        do {
            count = try dataStore.count(options: Options(readPolicy: .forceNetwork)).waitForResult().value()
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        XCTAssertNotNil(count)
        
        guard let count1 = count else {
            return
        }
        
        do {
            let results = try dataStore.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(results.count, count1)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        XCTAssertNotNil(count)
        
        guard let count2 = count else {
            return
        }
        
        do {
            let results = try dataStore.pull(options: nil).waitForResult(timeout: defaultTimeout).value()
            XCTAssertTrue(autoPagination)
            if autoPagination {
                XCTAssertEqual(results.count, count2)
            }
        } catch {
            if autoPagination {
                XCTFail(error.localizedDescription)
            } else {
                XCTAssertTrue(error is Kinvey.Error)
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .resultSetSizeExceeded:
                        break
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    func testServerSideDeltaSetResultSetSizeExceededAutoPaginationDisabled() {
        serverSideDeltaSetResultSetSizeExceeded(autoPagination: false)
    }
    
    func testServerSideDeltaSetResultSetSizeExceededAutoPaginationEnabled() {
        serverSideDeltaSetResultSetSizeExceeded(autoPagination: true)
    }
    
    func testServerSideDeltaSetAutoPagination2ndRequestFailing() {
        signUp()
        
        let dataStore = try! DataStore<Person>.collection(
            .sync,
            autoPagination: true,
            options: try! Options(deltaSet: true)
        )
        
        var count: Int? = nil
        
        var mockRequestPathSequence = [String]()
        if useMockData {
            var json = [
                [
                    "_id" : UUID().uuidString,
                    "name" : UUID().uuidString,
                    "age" : 0,
                    "_acl" : [
                        "creator" : self.client.activeUser!.userId
                    ],
                    "_kmd" : [
                        "lmt" : Date().toISO8601(),
                        "ect" : Date().toISO8601()
                    ]
                ],
                [
                    "_id" : UUID().uuidString,
                    "name" : UUID().uuidString,
                    "age" : 0,
                    "_acl" : [
                        "creator" : self.client.activeUser!.userId
                    ],
                    "_kmd" : [
                        "lmt" : Date().toISO8601(),
                        "ect" : Date().toISO8601()
                    ]
                ]
            ]
            var count = 0
            mockResponse { request in
                let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                mockRequestPathSequence.append(urlComponents.path)
                switch urlComponents.path {
                case "/appdata/_kid_/Person/_count":
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                        json: ["count" : json.count]
                    )
                case "/appdata/_kid_/Person/_deltaset":
                    return HttpResponse(
                        statusCode: 400,
                        json: [
                            "changed" : [],
                            "deleted" : []
                        ]
                    )
                case "/appdata/_kid_/Person/":
                    defer {
                        count += 1
                    }
                    if count == 1 {
                        return HttpResponse(error: timeoutError)
                    }
                    let skip = urlComponents.queryItems?.filter({ $0.name == "skip" && $0.value != nil && Int($0.value!) != nil }).map({ Int($0.value!)! }).first ?? 0
                    let limit = urlComponents.queryItems?.filter({ $0.name == "limit" && $0.value != nil && Int($0.value!) != nil }).map({ Int($0.value!)! }).first ?? json.endIndex - skip
                    return HttpResponse(
                        headerFields: ["X-Kinvey-Request-Start" : Date().toISO8601()],
                        json: Array(json[skip ..< skip + limit])
                    )
                default:
                    XCTFail(urlComponents.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
        }
        defer {
            if useMockData {
                XCTAssertEqual(mockRequestPathSequence.count, 7)
                if mockRequestPathSequence.count == 7 {
                    XCTAssertEqual(mockRequestPathSequence[0], "/appdata/_kid_/Person/_count")
                    XCTAssertEqual(mockRequestPathSequence[1], "/appdata/_kid_/Person/_count")
                    XCTAssertEqual(mockRequestPathSequence[2], "/appdata/_kid_/Person/")
                    XCTAssertEqual(mockRequestPathSequence[3], "/appdata/_kid_/Person/")
                    XCTAssertEqual(mockRequestPathSequence[4], "/appdata/_kid_/Person/_count")
                    XCTAssertEqual(mockRequestPathSequence[5], "/appdata/_kid_/Person/")
                    XCTAssertEqual(mockRequestPathSequence[6], "/appdata/_kid_/Person/")
                }
                setURLProtocol(nil)
            }
        }
        
        do {
            count = try dataStore.count(options: Options(readPolicy: .forceNetwork)).waitForResult().value()
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        XCTAssertNotNil(count)
        
        guard let count1 = count else {
            return
        }
        
        let options = try! Options(maxSizePerResultSet: 1)
        
        do {
            let results = try dataStore.pull(options: options).waitForResult(timeout: defaultTimeout).value()
            XCTFail("Error is expected")
        } catch {
            XCTAssertTimeoutError(error)
        }
        
        XCTAssertNotNil(count)
        
        guard let count2 = count else {
            return
        }
        
        do {
            let results = try dataStore.pull(options: options).waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(results.count, count2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testMaxSizePerResultSetGreaterThanZero() {
        expect {
            try Options(maxSizePerResultSet: 0)
        }.to(throwError())
        expect {
            try Options(Options(maxSizePerResultSet: 1), maxSizePerResultSet: 0)
        }.to(throwError())
    }
    
}
