//
//  KCSQueryTests.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-04-06.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import UIKit
import XCTest

class KCSQueryTests: XCTestCase {

    override func setUp() {
        super.setUp()
        
        setupKCS(true)
    }

    func testRemoveByQuery() {
        let collection = KCSCollection(fromString: "city", ofClass: NSMutableDictionary.self)
        let store = KCSCachedStore(collection: collection, options: [
            KCSStoreKeyCachePolicy : KCSCachePolicy.LocalFirst.rawValue,
            KCSStoreKeyOfflineUpdateEnabled : true
        ])
        
        let expectationSave = expectationWithDescription("save")
        let expectationRemove = expectationWithDescription("Remove")
        
        store.saveObject(
            [ "name" : "Vancouver" ],
            withCompletionBlock: { (results: [AnyObject]!, error: NSError!) -> Void in
                XCTAssertNil(error)
                XCTAssertNotNil(results)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let query = KCSQuery(onField: "name", withExactMatchForValue: "Vancouver")
                    store.removeObject(
                        query,
                        withCompletionBlock: { (count: UInt, error: NSError!) -> Void in
                            XCTAssertNil(error)
                            XCTAssertGreaterThan(count, 0 as UInt)
                            
                            expectationRemove.fulfill()
                        },
                        withProgressBlock: nil
                    )
                })
                
                expectationSave.fulfill()
            },
            withProgressBlock: nil
        )
        
        waitForExpectationsWithTimeout(30, handler: nil)
    }

}
