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
    
    class Person: NSObject, Persistable {
        
        dynamic var objectId: String?
        dynamic var name: String?
        
        override init() {
        }
        
        init(objectId: String? = nil, name: String?) {
            self.objectId = objectId
            self.name = name
        }
        
        static func kinveyCollectionName() -> String {
            return "Person"
        }
        
        static func kinveyPropertyMapping() -> [String : String] {
            return [
                "objectId" : PersistableIdKey,
                "name" : "name"
            ]
        }
        
    }
    
    override func tearDown() {
        if let activeUser = client.activeUser {
            let store = DataStore<Person>.getInstance(.Network)
            let query = Query(format: "_acl.creator == %@", activeUser.userId)
            
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
        let cache = MemoryCache(type: Person.self)
        cache.saveEntity([
            "objectId" : "update",
            PersistableMetadataKey : [
                Metadata.LmtKey : date
            ]
        ])
        cache.saveEntity([
            "objectId" : "noChange",
            PersistableMetadataKey : [
                Metadata.LmtKey : date
            ]
        ])
        cache.saveEntity([
            "objectId" : "delete",
            PersistableMetadataKey : [
                Metadata.LmtKey : date
            ]
        ])
        let operation = Operation(persistableType: Person.self, cache: cache, client: client)
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
        
        let store = DataStore<Person>.getInstance(.Network)
        
        let person = Person(name: "Victor")
        
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
        
        XCTAssertNotNil(person.objectId)
        
        do {
            let person = Person(name: "Victor Barros")
            
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
        
        let query = Query(format: "_acl.creator == %@", activeUser.userId)
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
            
            store.find(query) { persons, error in
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
        
        let store = DataStore<Person>.getInstance(.Network)
        
        let person = Person(name: "Victor")
        
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
        
        XCTAssertNotNil(person.objectId)
        guard let objectId = person.objectId else {
            return
        }
        
        do {
            let person = Person(objectId: objectId, name: "Victor Barros")
            
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
        
        let query = Query(format: "_acl.creator == %@", activeUser.userId)
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
            
            store.find(query) { persons, error in
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
        
        let store = DataStore<Person>.getInstance(.Network)
        
        let person = Person(name: "Victor")
        
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
        
        XCTAssertNotNil(person.objectId)
        guard let objectId = person.objectId else {
            return
        }
        
        do {
            weak var expectationDelete = expectationWithDescription("Delete")
            
            let query = Query(format: "objectId == %@", objectId)
            query.persistableType = Person.self
            let createRemove = RemoveOperation(query: query, writePolicy: .ForceNetwork, persistableType: Person.self, client: client)
            createRemove.execute { (count, error) -> Void in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                if let count = count as? UInt {
                    XCTAssertEqual(count, 1)
                }
                
                expectationDelete?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationDelete = nil
            }
        }
        
        let query = Query(format: "_acl.creator == %@", activeUser.userId)
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
            
            store.find(query) { persons, error in
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
            let person = Person(name: String(format: "Person %02d", i))
            
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
            let person = Person(name: String(format: "Person Cached %02d", i))
            let store = DataStore<Person>.getInstance(.Network)
            
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
        
        for i in 1...10 {
            save(i)
        }
        
        for i in 1...5 {
            saveAndCache(i)
        }
        
        let store = DataStore<Person>.getInstance(.Sync)
        
        let query = Query(format: "_acl.creator == %@", activeUser.userId)
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
                    for (i, person) in persons[0..<10].enumerate() {
                        XCTAssertEqual(person.name, String(format: "Person %02d", i + 1))
                    }
                    for (i, person) in persons[10..<persons.count].enumerate() {
                        XCTAssertEqual(person.name, String(format: "Person Cached %02d", i + 1))
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
                let person = Person(name: String(format: "Person %03d", i))
                
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
            let store = DataStore<Person>.getInstance(.Network)
            
            for i in 1...n {
                let person = Person(name: String(format: "Person Cached %03d", i))
                
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
        
        let store = DataStore<Person>.getInstance(.Sync)
        
        let query = Query(format: "_acl.creator == %@", activeUser.userId)
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
                    for (i, person) in persons[0..<countBackend].enumerate() {
                        XCTAssertEqual(person.name, String(format: "Person %03d", i + 1))
                    }
                    for (i, person) in persons[countBackend..<persons.count].enumerate() {
                        XCTAssertEqual(person.name, String(format: "Person Cached %03d", i + 1))
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
    
}
