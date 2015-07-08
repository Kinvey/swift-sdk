//
//  ClientAppVersionTests.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-03-19.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import Foundation

class RequestConfigurationTests: XCTestCase {
    
    var collection: KCSCollection!
    var store: KCSStore!
    var offlineUpdateDelegate: KCSOfflineUpdateDelegate!
    let timeout = NSTimeInterval(30)
    
    override func setUp() {
        super.setUp()
        
        let requestConfiguration = KCSRequestConfiguration(clientAppVersion: "2.0",
            andCustomRequestProperties: [
                "lang" : "fr",
                "globalProperty" : "abc"
            ]
        )
        setupKCS(true, options: nil, requestConfiguration: requestConfiguration)
        
        class MockOfflineUpdateDelegate:NSObject, KCSOfflineUpdateDelegate {
            
            private func shouldEnqueueObject(objectId: String!, inCollection collectionName: String!, onError error: NSError!) -> Bool {
                return true
            }
            
            private func didEnqueueObject(objectId: String!, inCollection collectionName: String!) {             
            }
            
            private func shouldSaveObject(objectId: String!, inCollection collectionName: String!, lastAttemptedSaveTime saveTime: NSDate!) -> Bool {
                return true
            }
            
            private func willSaveObject(objectId: String!, inCollection collectionName: String!) {
            }
            
            private func didSaveObject(objectId: String!, inCollection collectionName: String!) {
            }
            
            private func shouldDeleteObject(objectId: String!, inCollection collectionName: String!, lastAttemptedDeleteTime time: NSDate!) -> Bool {
                return true
            }
            
            private func willDeleteObject(objectId: String!, inCollection collectionName: String!) {
            }
            
            private func didDeleteObject(objectId: String!, inCollection collectionName: String!) {
            }
            
        }
        offlineUpdateDelegate = MockOfflineUpdateDelegate()
        KCSClient.sharedClient().setOfflineDelegate(offlineUpdateDelegate)
        
        collection = KCSCollection(fromString: "city", ofClass: NSMutableDictionary.self)
        store = KCSCachedStore(collection: collection, options: [
            KCSStoreKeyCachePolicy : KCSCachePolicy.LocalFirst.rawValue,
            KCSStoreKeyOfflineUpdateEnabled : true
        ])
    }
    
}

class RequestConfigurationTestsGlobalHttpRequestHeaders: RequestConfigurationTests {
    
    private class MockURLProtocol: NSURLProtocol {
        
        override class func canInitWithRequest(request: NSURLRequest) -> Bool {
            let headers = request.allHTTPHeaderFields!
            
            XCTAssertEqual(headers["X-Kinvey-Client-App-Version"] as! NSString!, "2.0")
            
            var error: NSError?
            let expectedResult = [
                "lang" : "fr",
                "globalProperty" : "abc"
                ] as Dictionary<String, String>
            let data = NSJSONSerialization.dataWithJSONObject(KCSMutableOrderedDictionary(dictionary: expectedResult),
                options: nil,
                error: &error)
            XCTAssertNil(error)
            let json = NSString(data: data!, encoding: NSUTF8StringEncoding)!
            XCTAssertEqual(headers["X-Kinvey-Custom-Request-Properties"] as! NSString!, json)
            
            return false
        }
        
    }

    func testGlobalHttpRequestHeaders() {
        var obj = [
            "_id" : "Boston",
            "name" : "Boston",
            "state" : "MA"
        ]
        weak var expectationSave = self.expectationWithDescription("save")
        
        XCTAssertTrue(KCSURLProtocol.registerClass(MockURLProtocol))
        
        self.store.saveObject(obj,
            withCompletionBlock: { (results: [AnyObject]!, error: NSError!) -> Void in
                XCTAssertNil(error)
                XCTAssertNotNil(results)
                XCTAssertTrue(results?.count == 1)
                
                if (results?.count > 0) {
                    XCTAssertEqual(results[0] as! Dictionary, obj)
                }
                
                XCTAssertTrue(NSThread.isMainThread())
                
                expectationSave?.fulfill()
            },
            withProgressBlock: { (results: [AnyObject]!, percentage: Double) -> Void in
                XCTAssertTrue(NSThread.isMainThread())
            }
        )
        
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
    override func tearDown() {
        KCSURLProtocol.unregisterClass(MockURLProtocol)
        
        super.tearDown()
    }
    
}

class RequestConfigurationTestsHttpRequestHeaders: RequestConfigurationTests {
    
    private class MockURLProtocol: NSURLProtocol {
        
        override class func canInitWithRequest(request: NSURLRequest) -> Bool {
            let headers = request.allHTTPHeaderFields!
            
            XCTAssertEqual(headers["X-Kinvey-Client-App-Version"] as! NSString!, "1.0")
            
            var error: NSError?
            let expectedResult = [
                "lang" : "pt",
                "globalProperty" : "abc",
                "requestProperty" : "123"
                ] as Dictionary<String, String>
            let data = NSJSONSerialization.dataWithJSONObject(KCSMutableOrderedDictionary(dictionary: expectedResult),
                options: nil,
                error: &error)
            XCTAssertNil(error)
            let json = NSString(data: data!, encoding: NSUTF8StringEncoding)!
            XCTAssertEqual(headers["X-Kinvey-Custom-Request-Properties"] as! NSString!, json)
            
            return false
        }
        
    }

    func testHttpRequestHeaders() {
        var obj = [
            "_id" : "Boston",
            "name" : "Boston",
            "state" : "MA"
        ]
        weak var expectationSave = self.expectationWithDescription("save")
        
        XCTAssertTrue(KCSURLProtocol.registerClass(MockURLProtocol))
        
        let requestConfig = KCSRequestConfiguration(clientAppVersion: "1.0",
            andCustomRequestProperties: [
                "lang" : "pt",
                "requestProperty" : "123"
            ]
        )
        self.store.saveObject(obj,
            requestConfiguration: requestConfig,
            withCompletionBlock: { (results: [AnyObject]!, error: NSError!) -> Void in
                XCTAssertNil(error)
                XCTAssertNotNil(results)
                XCTAssertTrue(results?.count == 1)
                if (results?.count > 0) {
                    XCTAssertEqual(results[0] as! Dictionary, obj)
                }
                
                XCTAssertTrue(NSThread.isMainThread())
                
                expectationSave?.fulfill()
            },
            withProgressBlock: { (results: [AnyObject]!, percentage: Double) -> Void in
                XCTAssertTrue(NSThread.isMainThread())
            }
        )
        
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
    override func tearDown() {
        KCSURLProtocol.unregisterClass(MockURLProtocol)
        
        super.tearDown()
    }
    
}

class RequestConfigurationTestsComplexHttpRequestHeaders: RequestConfigurationTests {
    
    private class MockURLProtocol: NSURLProtocol {
        
        override class func canInitWithRequest(request: NSURLRequest) -> Bool {
            let headers = request.allHTTPHeaderFields!
            
            XCTAssertEqual(headers["X-Kinvey-Client-App-Version"] as! NSString!, "1.0")
            
            var error: NSError?
            let expectedResult = [
                "lang" : "pt",
                "globalProperty" : "abc",
                "requestProperty" : "123",
                "location" : [
                    "city" : "Vancouver",
                    "province" : "BC",
                    "country" : "Canada"
                ]
                ] as Dictionary<String, AnyObject>
            let data = NSJSONSerialization.dataWithJSONObject(KCSMutableOrderedDictionary(dictionary: expectedResult),
                options: nil,
                error: &error)
            XCTAssertNil(error)
            let json = NSString(data: data!, encoding: NSUTF8StringEncoding)!
            XCTAssertEqual(headers["X-Kinvey-Custom-Request-Properties"] as! NSString!, json)
            
            return false
        }
        
    }

    func testComplexHttpRequestHeaders() {
        var obj = [
            "_id" : "Boston",
            "name" : "Boston",
            "state" : "MA"
        ]
        weak var expectationSave = self.expectationWithDescription("save")
        
        XCTAssertTrue(KCSURLProtocol.registerClass(MockURLProtocol))
        
        let requestConfig = KCSRequestConfiguration(clientAppVersion: "1.0",
            andCustomRequestProperties: [
                "lang" : "pt",
                "requestProperty" : "123",
                "location" : [
                    "city" : "Vancouver",
                    "province" : "BC",
                    "country" : "Canada"
                ]
            ]
        )
        self.store.saveObject(obj,
            requestConfiguration: requestConfig,
            withCompletionBlock: { (results: [AnyObject]!, error: NSError!) -> Void in
                XCTAssertNil(error)
                XCTAssertNotNil(results)
                XCTAssertTrue(results?.count == 1)
                if (results?.count > 0) {
                    XCTAssertEqual(results[0] as! Dictionary, obj)
                }
                
                XCTAssertTrue(NSThread.isMainThread())
                
                expectationSave?.fulfill()
            },
            withProgressBlock: { (results: [AnyObject]!, percentage: Double) -> Void in
                XCTAssertTrue(NSThread.isMainThread())
            }
        )
        
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
    override func tearDown() {
        KCSURLProtocol.unregisterClass(MockURLProtocol)
        
        super.tearDown()
    }
    
}
