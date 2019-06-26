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
        
        store = try! DataStore<Person>.collection(.network)
        
        let person = save(newPerson)
        
        signUp()
        
        store = try! DataStore<Person>.collection(.network)
        
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
        
        do {
            try store.remove(person) {
                self.assertThread()
                switch $0 {
                case .success(let count):
                    XCTFail("A failure result is expected")
                case .failure(let error):
                    XCTAssertTrue(error is Kinvey.Error)
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
                        case .insufficientCredentials:
                            break
                        default:
                            XCTFail(error.localizedDescription)
                        }
                    }
                }
                
                expectationRemove?.fulfill()
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testNoPermissionToDeletePush() {
        signUp()
        
        store = try! DataStore<Person>.collection(.network)
        
        let person = save(newPerson)
        
        signUp()
        
        store = try! DataStore<Person>.collection(.sync)
        
        do {
            if useMockData {
                XCTAssertNotNil(person.entityId)
                mockResponse(json: [
                    "_id" : person.entityId ?? "",
                    "name" : "Victor",
                    "age" : 29,
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
            
            XCTAssertNotNil(person.personId)
            guard let personId = person.personId else {
                return
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(personId, options: try Options(readPolicy: .forceNetwork)) {
                self.assertThread()
                switch $0 {
                case .success(let person):
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        XCTAssertEqual(store.syncCount(), 0)
        
        do {
            weak var expectationRemove = expectation(description: "Remove")
            
            try store.remove(person) {
                self.assertThread()
                switch $0 {
                case .success(let count):
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRemove = nil
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        XCTAssertEqual(store.syncCount(), 1)
        
        do {
            if useMockData {
                mockResponse(
                    statusCode: 401,
                    json: [
                        "error" : "InsufficientCredentials",
                        "description" : "The credentials used to authenticate this request are not authorized to run this operation. Please retry your request with appropriate credentials",
                        "debug" : ""
                    ]
                )
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
                        case .unauthorized(_, _, let error, _, _):
                            XCTAssertEqual(error, Kinvey.Error.Keys.insufficientCredentials.rawValue)
                        default:
                            XCTFail(error.localizedDescription)
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
        
        store = try! DataStore<Person>.collection(.network)
        
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
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(personId) {
                switch $0 {
                case .success(let person):
                    XCTAssertNotNil(person.acl)
                    if let acl = person.acl {
                        XCTAssertNotNil(acl.globalRead)
                        if let globalRead = acl.globalRead.value {
                            XCTAssertTrue(globalRead)
                        }
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
    
    func testGlobalWrite() {
        signUp()
        
        store = try! DataStore<Person>.collection(.network)
        
        let newPerson = self.newPerson
        XCTAssertNotNil(sharedClient.activeUser?.userId)
        guard let userId = sharedClient.activeUser?.userId else {
            return
        }
        newPerson.acl = Acl(creator: userId, globalWrite: true)
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
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(personId) {
                switch $0 {
                case .success(let person):
                    XCTAssertNotNil(person.acl)
                    if let acl = person.acl {
                        XCTAssertNotNil(acl.globalWrite)
                        if let globalWrite = acl.globalWrite.value {
                            XCTAssertTrue(globalWrite)
                        }
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
    
    func testReaders() {
        signUp()
        
        XCTAssertNotNil(sharedClient.activeUser)
        guard let user = sharedClient.activeUser else {
            return
        }
        
        signUp()
        
        store = try! DataStore<Person>.collection(.network)
        
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
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(personId) {
                switch $0 {
                case .success(let person):
                    XCTAssertNotNil(person.acl)
                    if let acl = person.acl {
                        XCTAssertNotNil(acl.readers)
                        if let readers = acl.readers {
                            XCTAssertEqual(readers.count, 1)
                            XCTAssertEqual(readers.first, user.userId)
                        }
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
    
    func testWriters() {
        signUp()
        
        XCTAssertNotNil(sharedClient.activeUser)
        guard let user = sharedClient.activeUser else {
            return
        }
        
        signUp()
        
        store = try! DataStore<Person>.collection(.network)
        
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
                        "lmt" : Date().toISO8601(),
                        "ect" : Date().toISO8601()
                    ]
                ])
            }
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(personId) {
                switch $0 {
                case .success(let person):
                    XCTAssertNotNil(person.acl)
                    if let acl = person.acl {
                        XCTAssertNotNil(acl.writers)
                        if let writers = acl.writers {
                            XCTAssertEqual(writers.count, 1)
                        }
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
    
    func testValidation() {
        XCTAssertNil(Acl(JSON: [:]))
        
        let creator = UUID().uuidString
        let acl = Acl(JSON: [
            Acl.CodingKeys.creator.rawValue : creator,
            Acl.CodingKeys.readers.rawValue : []
        ])
        XCTAssertNotNil(acl)
        XCTAssertEqual(acl?.creator, creator)
        XCTAssertNotNil(acl?.readers)
        XCTAssertEqual(acl?.readers?.count, 0)
        XCTAssertNotNil(acl?.toJSON()[Acl.CodingKeys.readers.rawValue])
        
        acl?["readersValue"] = ""
        XCTAssertNil(acl?.readers)
        acl?.readers = nil
        XCTAssertNil(acl?.toJSON()[Acl.CodingKeys.readers.rawValue])
    }
    
}
