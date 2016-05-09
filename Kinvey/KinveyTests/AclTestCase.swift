//
//  AclTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-25.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class AclTestCase: StoreTestCase {
    
    func testNoPermissionToDelete() {
        signUp()
        
        store = DataStore<Person>.getInstance(.Network)
        
        let person = save(newPerson)
        
        signUp()
        
        store = DataStore<Person>.getInstance(.Network)
        
        weak var expectationRemove = expectationWithDescription("Remove")
        
        try! store.remove(person) { (count, error) -> Void in
            self.assertThread()
            XCTAssertNil(count)
            XCTAssertNotNil(error)
            XCTAssertNotNil(error as? Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .Unauthorized(let error, _):
                    XCTAssertEqual(error, Kinvey.Error.InsufficientCredentials)
                default:
                    XCTFail()
                }
            }
            
            expectationRemove?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testNoPermissionToDeletePush() {
        signUp()
        
        store = DataStore<Person>.getInstance(.Network)
        
        let person = save(newPerson)
        
        signUp()
        
        store = DataStore<Person>.getInstance(.Sync)
        
        weak var expectationFind = expectationWithDescription("Find")
        
        store.find(person.personId!, readPolicy: .ForceNetwork) { person, error in
            self.assertThread()
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            expectationFind?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { (error) in
            expectationFind = nil
        }
        
        weak var expectationRemove = expectationWithDescription("Remove")
        
        try! store.remove(person) { (count, error) -> Void in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            
            expectationRemove?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationRemove = nil
        }
        
        weak var expectationPush = expectationWithDescription("Push")
        
        store.push() { count, errors in
            self.assertThread()
            XCTAssertEqual(count, 0)
            XCTAssertNotNil(errors)
            
            if let errors = errors {
                XCTAssertNotNil(errors.first as? Kinvey.Error)
                if let error = errors.first as? Kinvey.Error {
                    switch error {
                    case .Unauthorized(let error, _):
                        XCTAssertEqual(error, Kinvey.Error.InsufficientCredentials)
                    default:
                        XCTFail()
                    }
                }
            }
            
            expectationPush?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { (error) in
            expectationPush = nil
        }
    }
    
    func testGlobalRead() {
        signUp()
        
        store = DataStore<Person>.getInstance(.Network)
        
        let newPerson = self.newPerson
        newPerson.acl = Acl(creator: sharedClient.activeUser!.userId, globalRead: true)
        let person = save(newPerson)
        
        XCTAssertNotNil(person.personId)
        if let personId = person.personId {
            weak var expectationFind = expectationWithDescription("Find")
            
            store.find(personId) { person, error in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let person = person {
                    XCTAssertNotNil(person.acl)
                    if let acl = person.acl {
                        XCTAssertNotNil(acl.globalRead)
                        if let globalRead = acl.globalRead {
                            XCTAssertTrue(globalRead)
                        }
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
    }
    
    func testGlobalWrite() {
        signUp()
        
        store = DataStore<Person>.getInstance(.Network)
        
        let newPerson = self.newPerson
        newPerson.acl = Acl(creator: sharedClient.activeUser!.userId, globalWrite: true)
        let person = save(newPerson)
        
        XCTAssertNotNil(person.personId)
        if let personId = person.personId {
            weak var expectationFind = expectationWithDescription("Find")
            
            store.find(personId) { person, error in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let person = person {
                    XCTAssertNotNil(person.acl)
                    if let acl = person.acl {
                        XCTAssertNotNil(acl.globalWrite)
                        if let globalWrite = acl.globalWrite {
                            XCTAssertTrue(globalWrite)
                        }
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
    }
    
    func testReaders() {
        signUp()
        
        XCTAssertNotNil(sharedClient.activeUser)
        guard let user = sharedClient.activeUser else {
            return
        }
        
        signUp()
        
        store = DataStore<Person>.getInstance(.Network)
        
        let newPerson = self.newPerson
        newPerson.acl = Acl(creator: sharedClient.activeUser!.userId, readers: [user.userId])
        let person = save(newPerson)
        
        XCTAssertNotNil(person.personId)
        if let personId = person.personId {
            weak var expectationFind = expectationWithDescription("Find")
            
            store.find(personId) { person, error in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let person = person {
                    XCTAssertNotNil(person.acl)
                    if let acl = person.acl {
                        XCTAssertNotNil(acl.readers)
                        if let readers = acl.readers {
                            XCTAssertEqual(readers.count, 1)
                        }
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
    }
    
    func testWriters() {
        signUp()
        
        XCTAssertNotNil(sharedClient.activeUser)
        guard let user = sharedClient.activeUser else {
            return
        }
        
        signUp()
        
        store = DataStore<Person>.getInstance(.Network)
        
        let newPerson = self.newPerson
        newPerson.acl = Acl(creator: sharedClient.activeUser!.userId, writers: [user.userId])
        let person = save(newPerson)
        
        XCTAssertNotNil(person.personId)
        if let personId = person.personId {
            weak var expectationFind = expectationWithDescription("Find")
            
            store.find(personId) { person, error in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let person = person {
                    XCTAssertNotNil(person.acl)
                    if let acl = person.acl {
                        XCTAssertNotNil(acl.writers)
                        if let writers = acl.writers {
                            XCTAssertEqual(writers.count, 1)
                        }
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
    }
    
}
