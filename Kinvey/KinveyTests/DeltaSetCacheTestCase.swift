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
        let refObjs = [
            "create" : NSDate(timeInterval: 1, sinceDate: date),
            "update" : NSDate(timeInterval: 1, sinceDate: date),
            "noChange" : date
        ]
        let deltaSet = operation.computeDeltaSet(query, refObjs: refObjs)
        
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
            
            let createOperation = SaveOperation(persistable: person, writePolicy: .ForceNetwork, sync: EmptySync(), cache: EmptyCache(), client: client)
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
            
            let updateOperation = SaveOperation(persistable: person, writePolicy: .ForceNetwork, sync: EmptySync(), cache: EmptyCache(), client: client)
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
            let createRemove = RemoveOperation(query: query, writePolicy: .ForceNetwork, sync: EmptySync(), persistableType: Person.self, cache: EmptyCache(), client: client)
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
    
}
