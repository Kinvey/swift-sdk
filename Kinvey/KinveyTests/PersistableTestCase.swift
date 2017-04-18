//
//  PersistableTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-13.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class PersistableTestCase: StoreTestCase {
    
    func testAclNull() {
        store = DataStore<Person>.collection()
        
        class NullAclURLProtocol : URLProtocol {
            
            fileprivate override class func canInit(with request: URLRequest) -> Bool {
                return true
            }
            
            fileprivate override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                return request
            }
            
            fileprivate override func startLoading() {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json"])!
                let json = [
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Victor",
                        "age" : 29,
                        "_kmd" : [
                            "lmt" : "2016-04-13T22:29:38.868Z",
                            "ect" : "2016-04-13T22:29:38.868Z"
                        ]
                    ]
                ]
                let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                
                client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client!.urlProtocol(self, didLoad: data)
                client!.urlProtocolDidFinishLoading(self)
            }
            
            fileprivate override func stopLoading() {
            }
            
        }
        
        setURLProtocol(NullAclURLProtocol.self)
        defer { setURLProtocol(nil) }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(readPolicy: .forceNetwork) { (results, error) in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testAclEmpty() {
        store = DataStore<Person>.collection()
        
        class NullAclURLProtocol : URLProtocol {
            
            fileprivate override class func canInit(with request: URLRequest) -> Bool {
                return true
            }
            
            fileprivate override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                return request
            }
            
            fileprivate override func startLoading() {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json"])!
                let json = [
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Victor",
                        "age" : 29,
                        "_acl" : JsonDictionary(),
                        "_kmd" : [
                            "lmt" : "2016-04-13T22:29:38.868Z",
                            "ect" : "2016-04-13T22:29:38.868Z"
                        ]
                    ]
                ]
                let data = try! JSONSerialization.data(withJSONObject: json)
                
                client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client!.urlProtocol(self, didLoad: data)
                client!.urlProtocolDidFinishLoading(self)
            }
            
            fileprivate override func stopLoading() {
            }
            
        }
        
        setURLProtocol(NullAclURLProtocol.self)
        defer { setURLProtocol(nil) }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(readPolicy: .forceNetwork) { (results, error) in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testKmdNull() {
        store = DataStore<Person>.collection()
        
        class NullAclURLProtocol : URLProtocol {
            
            fileprivate override class func canInit(with request: URLRequest) -> Bool {
                return true
            }
            
            fileprivate override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                return request
            }
            
            fileprivate override func startLoading() {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json"])!
                let json = [
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Victor",
                        "age" : 29,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ]
                    ]
                ]
                let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                
                client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client!.urlProtocol(self, didLoad: data)
                client!.urlProtocolDidFinishLoading(self)
            }
            
            fileprivate override func stopLoading() {
            }
            
        }
        
        setURLProtocol(NullAclURLProtocol.self)
        defer { setURLProtocol(nil) }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(readPolicy: .forceNetwork) { (results, error) in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testKmdEmpty() {
        store = DataStore<Person>.collection()
        
        class NullAclURLProtocol : URLProtocol {
            
            fileprivate override class func canInit(with request: URLRequest) -> Bool {
                return true
            }
            
            fileprivate override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                return request
            }
            
            fileprivate override func startLoading() {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json"])!
                let json = [
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Victor",
                        "age" : 29,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : JsonDictionary()
                    ]
                ]
                let data = try! JSONSerialization.data(withJSONObject: json)
                
                client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client!.urlProtocol(self, didLoad: data)
                client!.urlProtocolDidFinishLoading(self)
            }
            
            fileprivate override func stopLoading() {
            }
            
        }
        
        setURLProtocol(NullAclURLProtocol.self)
        defer { setURLProtocol(nil) }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(readPolicy: .forceNetwork) { (results, error) in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testUnmappedProperties() {
        let json: JsonDictionary = [
            "name" : "Test",
            "age" : 18,
            "server-side-property" : 10
        ]
        let person = Person(JSON: json)!
        person.name = "Test 2"
        let jsonResponse = person.toJSON()
        XCTAssertEqual(jsonResponse.count, 3)
        XCTAssertEqual(jsonResponse["name"] as? String, "Test 2")
        XCTAssertEqual(jsonResponse["age"] as? Int, 18)
        XCTAssertEqual(jsonResponse["server-side-property"] as? Int, 10)
    }
    
    func testSendUnmappedProperties() {
        signUp()
        
        store = DataStore<Person>.collection(.network)
        
        var personTest: Person? = nil
        let personTestId = "58f69ff5c873232414c5fc1d"
        
        do {
            if useMockData {
                mockResponse(json: [
                    "_id" : personTestId,
                    "age" : 18,
                    "name" : "Test",
                    "unmapped_property" : 10,
                    "_acl": [
                        "creator" : "kid_WyWKm0pPM-",
                        "gr" : true,
                        "gw" : true
                    ],
                    "_kmd" : [
                        "lmt" : "2017-04-18T23:31:56.288Z",
                        "ect" : "2017-04-18T23:23:33.606Z"
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(personTestId) { (person, error) in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                personTest = person
                if let person = person {
                    XCTAssertEqual(person.name, "Test")
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        XCTAssertNotNil(personTest)
        var mockJson: JsonDictionary! = nil
        
        if let person = personTest {
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    mockJson = (try! JSONSerialization.jsonObject(with: request)) as! JsonDictionary
                    XCTAssertEqual(mockJson["_id"] as? String, personTestId)
                    XCTAssertEqual(mockJson["name"] as? String, "Test 2")
                    XCTAssertEqual(mockJson["age"] as? Int, 18)
                    XCTAssertEqual(mockJson["unmapped_property"] as? Int, 10)
                    return HttpResponse(json: mockJson)
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSave = expectation(description: "Save")
            
            person.name = "Test 2"
            
            store.save(person) { (person, error) in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                personTest = person
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSave = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse(json: mockJson)
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(personTestId) { (person, error) in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                personTest = person
                if let person = person {
                    XCTAssertEqual(person.name, "Test 2")
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
    }
    
}
