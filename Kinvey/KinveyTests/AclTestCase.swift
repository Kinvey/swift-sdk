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
        
        store = DataStore<Person>.collection(.network)
        
        let person = save(newPerson)
        
        signUp()
        
        store = DataStore<Person>.collection(.network)
        
        if useMockData {
            mockResponse(statusCode: 401, json: [
                "error" : "InsufficientCredentials",
                "description" : "The credentials used to authenticate this request are not authorized to run this operation. Please retry your request with appropriate credentials",
                "debug" : ""
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationRemove = expectation(description: "Remove")
        
        try! store.remove(person) { (count, error) -> Void in
            self.assertThread()
            XCTAssertNil(count)
            XCTAssertNotNil(error)
            XCTAssertNotNil(error as? Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                let result = error.responseBodyJsonDictionary
                XCTAssertNotNil(result)
                if let result = result {
                    let expected = [
                        "description" : "The credentials used to authenticate this request are not authorized to run this operation. Please retry your request with appropriate credentials",
                        "debug" : "",
                        "error" : "InsufficientCredentials"
                    ]
                    XCTAssertEqual(result.count, expected.count)
                    XCTAssertEqual(result["description"] as? String, expected["description"])
                    XCTAssertEqual(result["debug"] as? String, expected["debug"])
                    XCTAssertEqual(result["error"] as? String, expected["error"])
                }
                switch error {
                case .unauthorized(_, _, let error, _):
                    XCTAssertEqual(error, Kinvey.Error.InsufficientCredentials)
                default:
                    XCTFail()
                }
            }
            
            expectationRemove?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testNoPermissionToDeletePush() {
        signUp()
        
        store = DataStore<Person>.collection(.network)
        
        let person = save(newPerson)
        
        signUp()
        
        store = DataStore<Person>.collection(.sync)
        
        do {
            if useMockData {
                mockResponse(json: [
                    "_id" : person.entityId!,
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
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(person.personId!, readPolicy: .forceNetwork) { person, error in
                self.assertThread()
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
        
        XCTAssertEqual(store.syncCount(), 0)
        
        do {
            weak var expectationRemove = expectation(description: "Remove")
            
            try! store.remove(person) { (count, error) -> Void in
                self.assertThread()
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRemove = nil
            }
        }
        
        XCTAssertEqual(store.syncCount(), 1)
        
        do {
            if useMockData {
                mockResponse(statusCode: 401, json: [
                    "error" : "InsufficientCredentials",
                    "description" : "The credentials used to authenticate this request are not authorized to run this operation. Please retry your request with appropriate credentials",
                    "debug" : ""
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationPush = expectation(description: "Push")
            
            store.push() { count, errors in
                self.assertThread()
                XCTAssertNil(count)
                XCTAssertNotNil(errors)
                
                if let errors = errors {
                    XCTAssertNotNil(errors.first as? Kinvey.Error)
                    if let error = errors.first as? Kinvey.Error {
                        switch error {
                        case .unauthorized(_, _, let error, _):
                            XCTAssertEqual(error, Kinvey.Error.InsufficientCredentials)
                        default:
                            XCTFail()
                        }
                    }
                }
                
                expectationPush?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationPush = nil
            }
        }
    }
    
    func testGlobalRead() {
        signUp()
        
        store = DataStore<Person>.collection(.network)
        
        guard let userId = Kinvey.sharedClient.activeUser?.userId else {
            return
        }
        
        let newPerson = self.newPerson
        newPerson.acl = Acl(creator: userId, globalRead: true)
        let person = save(newPerson)
        
        XCTAssertNotNil(person.personId)
        if let personId = person.personId {
            if useMockData {
                mockResponse(json: [
                    "_id" : UUID().uuidString,
                    "name" : "Victor",
                    "age" : 29,
                    "_acl" : [
                        "gr" : true,
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
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(personId) { person, error in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let person = person {
                    XCTAssertNotNil(person.acl)
                    if let acl = person.acl {
                        XCTAssertNotNil(acl.globalRead)
                        if let globalRead = acl.globalRead.value {
                            XCTAssertTrue(globalRead)
                        }
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
    }
    
    func testGlobalWrite() {
        signUp()
        
        store = DataStore<Person>.collection(.network)
        
        let newPerson = self.newPerson
        newPerson.acl = Acl(creator: sharedClient.activeUser!.userId, globalWrite: true)
        let person = save(newPerson)
        
        XCTAssertNotNil(person.personId)
        if let personId = person.personId {
            if useMockData {
                mockResponse(json: [
                    "_id" : UUID().uuidString,
                    "name" : "Victor",
                    "age" : 29,
                    "_acl" : [
                        "gw" : true,
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
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(personId) { person, error in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let person = person {
                    XCTAssertNotNil(person.acl)
                    if let acl = person.acl {
                        XCTAssertNotNil(acl.globalWrite)
                        if let globalWrite = acl.globalWrite.value {
                            XCTAssertTrue(globalWrite)
                        }
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
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
        
        store = DataStore<Person>.collection(.network)
        
        let newPerson = self.newPerson
        newPerson.acl = Acl(creator: sharedClient.activeUser!.userId, readers: [user.userId])
        
        let person = save(newPerson)
        
        XCTAssertNotNil(person.personId)
        if let personId = person.personId {
            if useMockData {
                mockResponse(json: [
                    "_id" : personId,
                    "name" : "Victor",
                    "age" : 29,
                    "_acl" : [
                        "r" : ["\(user.userId)"],
                        "creator" : sharedClient.activeUser!.userId
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
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(personId) { person, error in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let person = person {
                    XCTAssertNotNil(person.acl)
                    if let acl = person.acl {
                        XCTAssertNotNil(acl.readers)
                        if let readers = acl.readers {
                            XCTAssertEqual(readers.count, 1)
                            XCTAssertEqual(readers.first, user.userId)
                        }
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
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
        
        store = DataStore<Person>.collection(.network)
        
        let newPerson = self.newPerson
        newPerson.acl = Acl(creator: sharedClient.activeUser!.userId, writers: [user.userId])
        let person = save(newPerson)
        
        XCTAssertNotNil(person.personId)
        if let personId = person.personId {
            if useMockData {
                mockResponse(json: [
                    "_id" : UUID().uuidString,
                    "name" : "Victor",
                    "age" : 29,
                    "_acl" : [
                        "w" : ["\(user.userId)"],
                        "creator" : UUID().uuidString
                    ],
                    "_kmd" : [
                        "lmt" : Date().toString(),
                        "ect" : Date().toString()
                    ]
                ])
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationFind = expectation(description: "Find")
            
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
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
    }
    
}
