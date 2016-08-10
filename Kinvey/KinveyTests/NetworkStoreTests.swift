//
//  NetworkStoreTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-15.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class NetworkStoreTests: StoreTestCase {
    
    override func setUp() {
        super.setUp()
        signUp()
        
        store = DataStore<Person>.collection()
    }
    
    override func assertThread() {
        XCTAssertTrue(NSThread.isMainThread())
    }
    
    func testSaveEvent() {
        let store = DataStore<Event>.collection(.Network)
        
        let event = Event()
        event.name = "Friday Party!"
        event.date = NSDate(timeIntervalSince1970: 1468001397) // Fri, 08 Jul 2016 18:09:57 GMT
        event.location = "The closest pub!"
        
        event.acl?.globalRead.value = true
        event.acl?.globalWrite.value = true
        
        weak var expectationCreate = expectationWithDescription("Create")
        
        store.save(event) { event, error in
            XCTAssertNotNil(event)
            XCTAssertNil(error)
            
            expectationCreate?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationCreate = nil
        }
    }
    
    func testSaveAddress() {
        let person = Person()
        person.name = "Victor Barros"
        
        let address = Address()
        address.city = "Vancouver"
        
        person.address = address
        
        weak var expectationSave = expectationWithDescription("Save")
        
        store.save(person, writePolicy: .ForceNetwork) { person, error in
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            if let person = person {
                XCTAssertNotNil(person.address)
                
                if let address = person.address {
                    XCTAssertNotNil(address.city)
                }
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationSave = nil
        }
    }
    
    class MethodNotAllowedError: NSURLProtocol {
        
        override class func canInitWithRequest(request: NSURLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
            return request
        }
        
        override func startLoading() {
            let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 405, HTTPVersion: "1.1", headerFields: [:])!
            client!.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
            
            let responseBody = [
                "error": "MethodNotAllowed",
                "debug": "insert' method is not allowed for this collection.",
                "description": "The method is not allowed for this resource."
            ]
            let responseBodyData = try! NSJSONSerialization.dataWithJSONObject(responseBody, options: [])
            client!.URLProtocol(self, didLoadData: responseBodyData)
            
            client!.URLProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {
        }
        
    }
    
    class DataLinkEntityNotFoundError: NSURLProtocol {
        
        override class func canInitWithRequest(request: NSURLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
            return request
        }
        
        override func startLoading() {
            let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 404, HTTPVersion: "1.1", headerFields: [:])!
            client!.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
            
            let responseBody = [
                "error": "DataLinkEntityNotFound",
                "debug": "Error: Not Found",
                "description": "The data link could not find this entity"
            ]
            let responseBodyData = try! NSJSONSerialization.dataWithJSONObject(responseBody, options: [])
            client!.URLProtocol(self, didLoadData: responseBodyData)
            
            client!.URLProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {
        }
        
    }
    
    func testGetDataLinkEntityNotFound() {
        setURLProtocol(DataLinkEntityNotFoundError.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectationWithDescription("Find")
        
        store.find("sample-id", readPolicy: .ForceNetwork) { person, error in
            XCTAssertNil(person)
            XCTAssertNotNil(error)
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .DataLinkEntityNotFound(let debug, let description):
                    XCTAssertEqual(debug, "Error: Not Found")
                    XCTAssertEqual(description, "The data link could not find this entity")
                default:
                    XCTFail()
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testSaveMethodNotAllowed() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        let person = Person()
        person.name = "Victor Barros"
        
        weak var expectationSave = expectationWithDescription("Save")
        
        store.save(person, writePolicy: .ForceNetwork) { person, error in
            XCTAssertNil(person)
            XCTAssertNotNil(error)
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .MethodNotAllowed(let debug, let description):
                    XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                    XCTAssertEqual(description, "The method is not allowed for this resource.")
                default:
                    XCTFail()
                }
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationSave = nil
        }
    }
    
    func testFindMethodNotAllowed() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectationWithDescription("Find")
        
        store.find(readPolicy: .ForceNetwork) { person, error in
            XCTAssertNil(person)
            XCTAssertNotNil(error)
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .MethodNotAllowed(let debug, let description):
                    XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                    XCTAssertEqual(description, "The method is not allowed for this resource.")
                default:
                    XCTFail()
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testGetMethodNotAllowed() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectationWithDescription("Find")
        
        store.find("sample-id", readPolicy: .ForceNetwork) { person, error in
            XCTAssertNil(person)
            XCTAssertNotNil(error)
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .MethodNotAllowed(let debug, let description):
                    XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                    XCTAssertEqual(description, "The method is not allowed for this resource.")
                default:
                    XCTFail()
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testRemoveByIdMethodNotAllowed() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectationWithDescription("Remove")
        
        store.removeById("sample-id", writePolicy: .ForceNetwork) { person, error in
            XCTAssertNil(person)
            XCTAssertNotNil(error)
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .MethodNotAllowed(let debug, let description):
                    XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                    XCTAssertEqual(description, "The method is not allowed for this resource.")
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
    
    func testRemoveMethodNotAllowed() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectationWithDescription("Remove")
        
        store.remove(writePolicy: .ForceNetwork) { count, error in
            XCTAssertNil(count)
            XCTAssertNotNil(error)
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .MethodNotAllowed(let debug, let description):
                    XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                    XCTAssertEqual(description, "The method is not allowed for this resource.")
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
    
}
