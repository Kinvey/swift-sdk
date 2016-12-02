//
//  CachedStoreTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-15.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class CacheStoreTests: StoreTestCase {
    
    override func setUp() {
        super.setUp()
        
        signUp()
        
        store = DataStore<Person>.collection(.cache)
    }
    
    func testSaveAddress() {
        let person = Person()
        person.name = "Victor Barros"
        
        weak var expectationSaveLocal = expectation(description: "Save Local")
        weak var expectationSaveNetwork = expectation(description: "Save Network")
        
        var runCount = 0
        
        if useMockData {
            setResponseBody {
                let json = try! JSONSerialization.jsonObject(with: $0) as? JsonDictionary
                return HttpResponse(statusCode: 201, json: [
                    "_id" : json?["_id"] as? String ?? UUID().uuidString,
                    "name" : "Victor Barros",
                    "age" : 0,
                    "_acl" : [
                        "creator" : UUID().uuidString
                    ],
                    "_kmd" : [
                        "lmt" : Date().toString(),
                        "ect" : Date().toString()
                    ]
                ])
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        store.save(person) { person, error in
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            switch runCount {
            case 0:
                if let person = person {
                    XCTAssertNotNil(person.personId)
                    if let personId = person.personId {
                        XCTAssertTrue(personId.hasPrefix(ObjectIdTmpPrefix))
                    }
                }
                
                expectationSaveLocal?.fulfill()
            case 1:
                if let person = person {
                    XCTAssertNotNil(person.personId)
                    if let personId = person.personId {
                        XCTAssertFalse(personId.hasPrefix(ObjectIdTmpPrefix))
                    }
                }
                
                expectationSaveNetwork?.fulfill()
            default:
                break
            }
            
            runCount += 1
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSaveLocal = nil
            expectationSaveNetwork = nil
        }
    }
    
}
