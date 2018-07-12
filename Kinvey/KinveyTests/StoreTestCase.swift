//
//  StoreTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-14.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class StoreTestCase: KinveyTestCase {
    
    var store: DataStore<Person>!
    var newPerson: Person {
        let person = Person()
        person.name = "Victor"
        person.age = 29
        return person
    }
    lazy var person: Person = self.newPerson
    
    func assertThread() {
        XCTAssertTrue(Thread.isMainThread)
    }
    
    @discardableResult
    func save<T>(_ persistable: T, store: DataStore<T>, mockResponseHandler: ((JsonDictionary) -> JsonDictionary)? = nil) -> (originalPersistable: T, savedPersistable: T?) {
        if useMockData {
            mockResponse {
                var json = try! JSONSerialization.jsonObject(with: $0) as! JsonDictionary
                if let mockResponseHandler = mockResponseHandler {
                    json = mockResponseHandler(json)
                }
                json["_id"] = json["_id"] ?? UUID().uuidString
                json["date"] = Date().toString()
                json["_acl"] = [
                    "creator" : UUID().uuidString
                ]
                json["_kmd"] = [
                    "lmt" : Date().toString(),
                    "ect" : Date().toString()
                ]
                return HttpResponse(json: json)
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationCreate = expectation(description: "Create")
        
        var savedPersistable: T? = nil
        
        store.save(persistable) {
            self.assertThread()
            switch $0 {
            case .success(let persistable):
                XCTAssertNotNil(persistable.entityId)
                
                savedPersistable = persistable
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationCreate?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCreate = nil
        }
        
        return (originalPersistable: persistable, savedPersistable: savedPersistable)
    }
    
    @discardableResult
    func save(_ person: Person) -> Person {
        let age = person.age
        var person = person
        
        if useMockData {
            mockResponse(json: [
                "_id" : UUID().uuidString,
                "name" : "Victor",
                "age" : 29,
                "_acl" : [
                    "creator" : UUID().uuidString
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
        
        store.save(person) {
            self.assertThread()
            switch $0 {
            case .success(let _person):
                person = _person
                XCTAssertNotNil(person.personId)
                XCTAssertNotEqual(person.personId, "")
                
                XCTAssertNotNil(person.age)
                XCTAssertEqual(person.age, age)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationCreate?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCreate = nil
        }
        
        return person
    }
    
    @discardableResult
    func save() -> Person {
        let person = self.newPerson
        
        weak var expectationCreate = expectation(description: "Create")
        
        store.save(person) {
            self.assertThread()
            switch $0 {
            case .success(let person):
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationCreate?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCreate = nil
        }
        
        return person
    }

    
}
