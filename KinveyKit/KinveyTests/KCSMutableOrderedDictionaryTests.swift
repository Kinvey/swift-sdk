//
//  KCSMutableOrderedDictionaryTests.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-03-25.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import UIKit
import XCTest

class KCSMutableOrderedDictionaryTests: KCSTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEnumerator() {
        let dict = [
            "c" : 3,
            "b" : "2",
            "a" : [
                "banana" : 3,
                "apple" : 2
            ]
        ] as Dictionary<String, AnyObject>!
        let orderedDict = KCSMutableOrderedDictionary(dictionary: dict)!
        var error: NSError? = nil
        let data = NSJSONSerialization.dataWithJSONObject(orderedDict, options: NSJSONWritingOptions.allZeros, error: &error)
        
        XCTAssertNil(error)
        
        let json = NSString(data: data!, encoding: NSUTF8StringEncoding)!
        
        XCTAssertNotNil(json)
        XCTAssertEqual("{\"a\":{\"apple\":2,\"banana\":3},\"b\":\"2\",\"c\":3}", json)
    }

    func testPerformanceCreate() {
        self.measureBlock() {
            let dict = [
                "c" : 3,
                "b" : "2",
                "a" : [
                    "banana" : 3,
                    "apple" : 2
                ]
            ] as Dictionary<String, AnyObject>!
            for i in 0...100 {
                let orderedDict = KCSMutableOrderedDictionary(dictionary: dict)!
            }
        }
    }
    
    func testPerformanceJsonSerialization() {
        self.measureBlock() {
            let dict = [
                "c" : 3,
                "b" : "2",
                "a" : [
                    "banana" : 3,
                    "apple" : 2
                ]
                ] as Dictionary<String, AnyObject>!
            let orderedDict = KCSMutableOrderedDictionary(dictionary: dict)!
            for i in 0...100 {
                var error: NSError? = nil
                let data = NSJSONSerialization.dataWithJSONObject(orderedDict, options: NSJSONWritingOptions.allZeros, error: &error)
            }
        }
    }

}
