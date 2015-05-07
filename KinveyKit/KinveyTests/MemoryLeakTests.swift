//
//  MemoryLeakTests.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-05-04.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import UIKit
import XCTest

class MemoryLeakTests: XCTestCase {
    
    let languages = ["Swift", "C", "C++", "C#", "Objective-C", "Java", "JavaScript", "Scala", "Erlang", "Go"]
    
    var collection: KCSCollection!
    var store: KCSStore!
    
    let timeout = NSTimeInterval(60)
    
    func login() {
        let expectationLogin = expectationWithDescription("login")
        
        KCSUser.createAutogeneratedUser(
            nil,
            completion: { (user: KCSUser!, error: NSError!, actionResult: KCSUserActionResult) -> Void in
                expectationLogin.fulfill()
            }
        )
        
        waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
    func logout() {
        KCSUser.activeUser().logout()
    }
    
    func randomLanguage() -> String {
        return languages[Int(arc4random()) % languages.count]
    }
    
    //Create
    func save() {
        let expectationSave = expectationWithDescription("save")
        
        store.saveObject(
            [
                "name" : randomLanguage()
            ],
            withCompletionBlock: { (results: [AnyObject]!, error: NSError!) -> Void in
                expectationSave.fulfill()
            },
            withProgressBlock: nil
        )
        
        waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
    //Read
    func query() {
        let expectationQuery = expectationWithDescription("query")
        
        let query = KCSQuery(onField: "name", withExactMatchForValue: randomLanguage())
        store.queryWithQuery(
            query,
            withCompletionBlock: { (results: [AnyObject]!, error: NSError!) -> Void in
                expectationQuery.fulfill()
            },
            withProgressBlock: nil
        )
        
        waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
    //Update
    func update() {
        let expectationQuery = expectationWithDescription("query")
        let expectationSave = self.expectationWithDescription("save")
        
        let query = KCSQuery(onField: "name", withExactMatchForValue: randomLanguage())
        store.queryWithQuery(
            query,
            withCompletionBlock: { (results: [AnyObject]!, error: NSError!) -> Void in
                let parentResults = results
                var count = 0
                for language in results as! [NSMutableDictionary] {
                    language["name"] = self.randomLanguage()
                    
                    self.store.saveObject(
                        language,
                        withCompletionBlock: { (results: [AnyObject]!, error: NSError!) -> Void in
                            if ++count == parentResults.count {
                                expectationSave.fulfill()
                            }
                        },
                        withProgressBlock: nil
                    )
                }
                
                expectationQuery.fulfill()
            },
            withProgressBlock: nil
        )
        
        waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
    //Delete
    func delete() {
        let expectationDelete = expectationWithDescription("delete")
        
        let query = KCSQuery(onField: "name", withExactMatchForValue: randomLanguage())
        store.removeObject(
            query,
            withCompletionBlock: { (count: UInt, error: NSError!) -> Void in
                expectationDelete.fulfill()
            },
            withProgressBlock: nil
        )
        
        waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
    func doNothing() {
        //do nothing
    }

    func test() {
        let memory1 = Double(usedMemory())
        
        setupKCS(false)
        
        collection = KCSCollection(fromString: "language", ofClass: NSMutableDictionary.self)
        store = KCSLinkedAppdataStore(collection: collection, options: nil)
        
        login()
        
        let operations = ["C", "R", "U", "D"]
        for index in 0...100 {
            switch Int(arc4random()) % operations.count {
            case 0:
                save()
            case 1:
                query()
            case 2:
                update()
            case 3:
                delete()
            default:
                doNothing()
            }
        }
    
        let memory2 = Double(usedMemory())
        XCTAssertEqualWithAccuracy(memory1, memory2, Double(22 * 1024 * 1024)) //22 MB
    }

}
