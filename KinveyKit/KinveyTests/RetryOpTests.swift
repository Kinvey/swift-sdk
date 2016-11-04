//
//  KCSRetryOpTests.swift
//  KinveyKit
//
//  Created by Victor Hugo on 2016-11-02.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest

class RetryOpTests: KinveyTestCase {
    
    override func setUp() {
        super.setUp()
        
        setupClient()
        createUser()
        
        XCTAssertNotNil(KCSUser.activeUser())
    }
    
    override func tearDown() {
        XCTAssertNotNil(KCSUser.activeUser())
        
        KCSUser.activeUser()?.logout()
        
        XCTAssertNil(KCSUser.activeUser())
        
        super.tearDown()
    }
    
    func testRetryOp() {
        class MockURLProtocol: NSURLProtocol {
            
            static var count = 0
            
            override class func canInitWithRequest(request: NSURLRequest) -> Bool {
                return true
            }
            
            override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
                return request
            }
            
            private override func startLoading() {
                if MockURLProtocol.count < 2 {
                    responseError()
                } else {
                    responseOK()
                }
            
                MockURLProtocol.count += 1
            }
            
            private func responseError() {
                let response = NSHTTPURLResponse(
                    URL: request.URL!,
                    statusCode: 500,
                    HTTPVersion: "1.1",
                    headerFields: [
                        "Content-Type" : "application/json"
                    ]
                )!
                client!.URLProtocol(
                    self,
                    didReceiveResponse: response,
                    cacheStoragePolicy: NSURLCacheStoragePolicy.NotAllowed
                )
                let responseBody = [
                    "error" : "KinveyInternalErrorRetry"
                ]
                let data = try! NSJSONSerialization.dataWithJSONObject(responseBody, options: [])
                client!.URLProtocol(self, didLoadData: data)
                client!.URLProtocolDidFinishLoading(self)
            }
            
            private func responseOK() {
                let response = NSHTTPURLResponse(
                    URL: request.URL!,
                    statusCode: 200,
                    HTTPVersion: "1.1",
                    headerFields: [
                        "Content-Type" : "application/json",
                        "X-Kinvey-API-Version" : "3"
                    ]
                )!
                client!.URLProtocol(
                    self,
                    didReceiveResponse: response,
                    cacheStoragePolicy: NSURLCacheStoragePolicy.NotAllowed
                )
                let responseBody = [
                    [
                        "_id" : "578fbd91beafbb2530fc7d77",
                        "age" : 0,
                        "address" : [
                            "city" : "Boston",
                            "state" : "MA"
                        ],
                        "name" : "Tejas",
                        "likesSwift" : NSNull(),
                        "_acl" : [
                            "creator" : "578fbd91ea3df6b0360cb362"
                        ],
                        "_kmd" : [
                            "lmt" : "2016-07-20T18:06:09.493Z",
                            "ect" : "2016-07-20T18:06:09.493Z"
                        ]
                    ],
                    [
                        "_id" : "578fbd91beafbb2530fc7d77",
                        "age" : 0,
                        "address" : [
                            "city" : "Vancouver",
                            "state" : "BC"
                        ],
                        "name" : "Victor",
                        "likesSwift" : true,
                        "_acl" : [
                            "creator" : "578fbd91ea3df6b0360cb362"
                        ],
                        "_kmd" : [
                            "lmt" : "2016-07-20T18:06:09.493Z",
                            "ect" : "2016-07-20T18:06:09.493Z"
                        ]
                    ],
                    [
                        "_id" : "578fbd91beafbb2530fc7d77",
                        "age" : 0,
                        "address" : [
                            "city" : "Jacksonville",
                            "state" : "FL"
                        ],
                        "name" : "Thomas",
                        "likesSwift" : false,
                        "_acl" : [
                            "creator" : "578fbd91ea3df6b0360cb362"
                        ],
                        "_kmd" : [
                            "lmt" : "2016-07-20T18:06:09.493Z",
                            "ect" : "2016-07-20T18:06:09.493Z"
                        ]
                    ]
                ]
                let data = try! NSJSONSerialization.dataWithJSONObject(responseBody, options: [])
                client!.URLProtocol(self, didLoadData: data)
                client!.URLProtocolDidFinishLoading(self)
            }
            
            private override func stopLoading() {
            }
            
        }
        
        class Person: NSObject {
            
            dynamic var name: String?
            dynamic var likesSwift: NSNumber?
            
            private override func hostToKinveyPropertyMapping() -> [NSObject : AnyObject]! {
                return [
                    "name" : "name",
                    "likesSwift" : "likesSwift"
                ]
            }
            
        }
        
        KCSURLProtocol.registerClass(MockURLProtocol.self)
        defer {
            KCSURLProtocol.unregisterClass(MockURLProtocol.self)
        }
        
        let logbookStore = KCSLinkedAppdataStore.storeWithOptions([
            KCSStoreKeyCollectionName : "MyCollection",
            KCSStoreKeyCollectionTemplateClass : Person.self,
            KCSStoreKeyCachePolicy : KCSCachePolicy.None.rawValue,
            KCSStoreKeyOfflineUpdateEnabled : true
        ])
        
        weak var expectationQuery = expectationWithDescription("Query")
        
        logbookStore.queryWithQuery(KCSQuery(), withCompletionBlock: { (results, error) in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let persons = results as? [Person] {
                for person in persons {
                    XCTAssertNotNil(person.name)
                    if let name = person.name {
                        switch name {
                            case "Tejas": XCTAssertNil(person.likesSwift)
                            case "Victor": XCTAssertEqual(person.likesSwift, true)
                            case "Thomas": XCTAssertEqual(person.likesSwift, false)
                            default: XCTFail()
                        }
                    }
                    print("Name: \(person.name)\nLikes Swift: \(person.likesSwift)")
                }
            }
            
            expectationQuery?.fulfill()
        }, withProgressBlock: nil)
        
        waitForExpectationsWithTimeout(30) { error in
            expectationQuery = nil
        }
    }
    
    func testRetryTimeout() {
        class MockURLProtocol: NSURLProtocol {
            
            static var count = 0
            
            override class func canInitWithRequest(request: NSURLRequest) -> Bool {
                return true
            }
            
            override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
                return request
            }
            
            private override func startLoading() {
                if MockURLProtocol.count < 2 {
                    responseError()
                } else {
                    responseTimeoutError()
                }
                
                MockURLProtocol.count += 1
            }
            
            private func responseError() {
                let response = NSHTTPURLResponse(
                    URL: request.URL!,
                    statusCode: 500,
                    HTTPVersion: "1.1",
                    headerFields: [
                        "Content-Type" : "application/json"
                    ]
                    )!
                client!.URLProtocol(
                    self,
                    didReceiveResponse: response,
                    cacheStoragePolicy: NSURLCacheStoragePolicy.NotAllowed
                )
                let responseBody = [
                    "error" : "KinveyInternalErrorRetry"
                ]
                let data = try! NSJSONSerialization.dataWithJSONObject(responseBody, options: [])
                client!.URLProtocol(self, didLoadData: data)
                client!.URLProtocolDidFinishLoading(self)
            }
            
            private func responseTimeoutError() {
                client!.URLProtocol(self, didFailWithError: NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil))
            }
            
            private override func stopLoading() {
            }
            
        }
        
        KCSURLProtocol.registerClass(MockURLProtocol.self)
        defer {
            KCSURLProtocol.unregisterClass(MockURLProtocol.self)
        }
        
        let logbookStore = KCSLinkedAppdataStore.storeWithOptions([
            KCSStoreKeyCollectionName : "MyCollection",
            KCSStoreKeyCollectionTemplateClass : NSMutableDictionary.self,
            KCSStoreKeyCachePolicy : KCSCachePolicy.None.rawValue,
            KCSStoreKeyOfflineUpdateEnabled : true
            ])
        
        weak var expectationQuery = expectationWithDescription("Query")
        
        logbookStore.queryWithQuery(KCSQuery(), withCompletionBlock: { (results, error) in
            XCTAssertNil(results)
            XCTAssertNotNil(error)
            
            if let error = error {
                XCTAssertEqual(error.domain, NSURLErrorDomain)
                XCTAssertEqual(error.code, NSURLErrorTimedOut)
            }
            
            expectationQuery?.fulfill()
        }, withProgressBlock: nil)
        
        waitForExpectationsWithTimeout(30) { error in
            expectationQuery = nil
        }
    }
    
}
