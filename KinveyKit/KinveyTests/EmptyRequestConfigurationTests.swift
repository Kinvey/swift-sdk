//
//  EmptyRequestConfigurationTests.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-04-30.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import UIKit
import XCTest

class EmptyRequestConfigurationTests: XCTestCase {

    var collection: KCSCollection!
    var store: KCSStore!
    var offlineUpdateDelegate: KCSOfflineUpdateDelegate!
    let timeout = NSTimeInterval(30)
    
    override func setUp() {
        super.setUp()
        
        setupKCS(true)
        
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
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test() {
        var obj = [
            "_id" : "Boston",
            "name" : "Boston",
            "state" : "MA"
        ]
        let expectationSave = self.expectationWithDescription("save")
        
        class MockURLProtocol: NSURLProtocol {
            
            override class func canInitWithRequest(request: NSURLRequest) -> Bool {
                let headers = request.allHTTPHeaderFields!
                
                XCTAssertNil(headers["X-Kinvey-Client-App-Version"])
                XCTAssertNil(headers["X-Kinvey-Custom-Request-Properties"])
                
                return false
            }
            
        }
        
        XCTAssertTrue(KCSURLProtocol.registerClass(MockURLProtocol))
        
        self.store.saveObject(obj,
            withCompletionBlock: { (results: [AnyObject]!, error: NSError!) -> Void in
                XCTAssertNil(error)
                XCTAssertNotNil(results)
                XCTAssertEqual(results.count, 1)
                
                if results.count > 0 {
                    XCTAssertEqual(results[0] as! Dictionary, obj)
                }
                
                XCTAssertTrue(NSThread.isMainThread())
                
                expectationSave.fulfill()
            },
            withProgressBlock: { (results: [AnyObject]!, percentage: Double) -> Void in
                XCTAssertTrue(NSThread.isMainThread())
            }
        )
        
        self.waitForExpectationsWithTimeout(timeout, handler: { (error: NSError!) -> Void in
            KCSURLProtocol.unregisterClass(MockURLProtocol)
            
            XCTAssertNil(error)
        })
    }

}
