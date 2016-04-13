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
        store = DataStore<Person>.getInstance(.Network)
        
        class NullAclURLProtocol : NSURLProtocol {
            
            private override class func canInitWithRequest(request: NSURLRequest) -> Bool {
                return true
            }
            
            private override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
                return request
            }
            
            private override func startLoading() {
                let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json"])!
                let json = [
                    [
                        "_id" : NSUUID().UUIDString,
                        "name" : "Victor",
                        "age" : 29,
                        "_kmd" : [
                            "lmt" : "2016-04-13T22:29:38.868Z",
                            "ect" : "2016-04-13T22:29:38.868Z"
                        ]
                    ]
                ]
                let data = try! NSJSONSerialization.dataWithJSONObject(json, options: [])
                
                client!.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
                client!.URLProtocol(self, didLoadData: data)
                client!.URLProtocolDidFinishLoading(self)
            }
            
            private override func stopLoading() {
            }
            
        }
        
        setURLProtocol(NullAclURLProtocol.self)
        defer { setURLProtocol(nil) }
        
        weak var expectationFind = expectationWithDescription("Find")
        
        store.find { (results, error) in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testAclEmpty() {
        store = DataStore<Person>.getInstance(.Network)
        
        class NullAclURLProtocol : NSURLProtocol {
            
            private override class func canInitWithRequest(request: NSURLRequest) -> Bool {
                return true
            }
            
            private override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
                return request
            }
            
            private override func startLoading() {
                let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json"])!
                let json = [
                    [
                        "_id" : NSUUID().UUIDString,
                        "name" : "Victor",
                        "age" : 29,
                        "_acl" : JsonDictionary(),
                        "_kmd" : [
                            "lmt" : "2016-04-13T22:29:38.868Z",
                            "ect" : "2016-04-13T22:29:38.868Z"
                        ]
                    ]
                ]
                let data = try! NSJSONSerialization.dataWithJSONObject(json, options: [])
                
                client!.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
                client!.URLProtocol(self, didLoadData: data)
                client!.URLProtocolDidFinishLoading(self)
            }
            
            private override func stopLoading() {
            }
            
        }
        
        setURLProtocol(NullAclURLProtocol.self)
        defer { setURLProtocol(nil) }
        
        weak var expectationFind = expectationWithDescription("Find")
        
        store.find { (results, error) in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testKmdNull() {
        store = DataStore<Person>.getInstance(.Network)
        
        class NullAclURLProtocol : NSURLProtocol {
            
            private override class func canInitWithRequest(request: NSURLRequest) -> Bool {
                return true
            }
            
            private override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
                return request
            }
            
            private override func startLoading() {
                let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json"])!
                let json = [
                    [
                        "_id" : NSUUID().UUIDString,
                        "name" : "Victor",
                        "age" : 29,
                        "_acl" : [
                            "creator" : NSUUID().UUIDString
                        ]
                    ]
                ]
                let data = try! NSJSONSerialization.dataWithJSONObject(json, options: [])
                
                client!.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
                client!.URLProtocol(self, didLoadData: data)
                client!.URLProtocolDidFinishLoading(self)
            }
            
            private override func stopLoading() {
            }
            
        }
        
        setURLProtocol(NullAclURLProtocol.self)
        defer { setURLProtocol(nil) }
        
        weak var expectationFind = expectationWithDescription("Find")
        
        store.find { (results, error) in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testKmdEmpty() {
        store = DataStore<Person>.getInstance(.Network)
        
        class NullAclURLProtocol : NSURLProtocol {
            
            private override class func canInitWithRequest(request: NSURLRequest) -> Bool {
                return true
            }
            
            private override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
                return request
            }
            
            private override func startLoading() {
                let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json"])!
                let json = [
                    [
                        "_id" : NSUUID().UUIDString,
                        "name" : "Victor",
                        "age" : 29,
                        "_acl" : [
                            "creator" : NSUUID().UUIDString
                        ],
                        "_kmd" : JsonDictionary()
                    ]
                ]
                let data = try! NSJSONSerialization.dataWithJSONObject(json, options: [])
                
                client!.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
                client!.URLProtocol(self, didLoadData: data)
                client!.URLProtocolDidFinishLoading(self)
            }
            
            private override func stopLoading() {
            }
            
        }
        
        setURLProtocol(NullAclURLProtocol.self)
        defer { setURLProtocol(nil) }
        
        weak var expectationFind = expectationWithDescription("Find")
        
        store.find { (results, error) in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
}
