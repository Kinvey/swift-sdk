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
        
        init(name: String?) {
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
            "objectId" : "delete",
            PersistableMetadataKey : [
                Metadata.LmtKey : date
            ]
        ])
        let operation = Operation(persistableType: Person.self, cache: cache, client: client)
        let query = Query()
        let refObjs = [
            "create" : NSDate(timeInterval: 1, sinceDate: date),
            "update" : NSDate(timeInterval: 1, sinceDate: date)
        ]
        let delta = operation.computeDelta(query, refObjs: refObjs)
        
        XCTAssertEqual(delta.created.count, 1)
        XCTAssertEqual(delta.created.first, "create")
        
        XCTAssertEqual(delta.updated.count, 1)
        XCTAssertEqual(delta.updated.first, "update")
        
        XCTAssertEqual(delta.deleted.count, 1)
        XCTAssertEqual(delta.deleted.first, "delete")
    }
    
    func testUpdate() {
        signUp()
        
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
            weak var expectationUpdate = expectationWithDescription("Update")
            
            let updateOperation = SaveOperation(persistable: Person(name: "Victor Barros"), writePolicy: .ForceNetwork, sync: EmptySync(), cache: EmptyCache(), client: client)
            updateOperation.execute { (results, error) -> Void in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                expectationUpdate?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationUpdate = nil
            }
        }
        
        do {
            weak var expectationRead = expectationWithDescription("Read")
            
            store.findById(objectId, readPolicy: .ForceLocal) { person, error in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let person = person {
                    XCTAssertEqual(person.name, "Victor")
                }
                
                expectationRead?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationRead = nil
            }
        }
        
        XCTAssertNotNil(client.activeUser)
        if let activeUser = client.activeUser {
            weak var expectationFind = expectationWithDescription("Find")
            
            let query = Query(format: "_acl.creator == %@", activeUser.userId)
            store.find(query) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                expectationFind?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationFind = nil
            }
        }
        
        do {
            weak var expectationRead = expectationWithDescription("Read")
            
            store.findById(objectId, readPolicy: .ForceLocal) { person, error in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let person = person {
                    XCTAssertEqual(person.name, "Victor Barros")
                }
                
                expectationRead?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) -> Void in
                expectationRead = nil
            }
        }
    }
    
}
