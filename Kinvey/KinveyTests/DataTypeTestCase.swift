//
//  DataTypeTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-22.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class DataTypeTestCase: StoreTestCase {
    
    func testBoolSave() {
        signUp()
        
        let store = DataStore<DataType>.getInstance(.Network)
        let dataType = DataType()
        dataType.boolValue = true
        let tuple = save(dataType, store: store)
        
        XCTAssertNotNil(tuple.savedPersistable)
        if let savedPersistable = tuple.savedPersistable {
            XCTAssertTrue(savedPersistable.boolValue)
        }
        
        let query = Query(format: "_acl.creator == %@", client.activeUser!.userId)
        
        weak var expectationFind = expectationWithDescription("Find")
        
        store.find(query) { results, error in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
                
                if let dataType = results.first {
                    XCTAssertTrue(dataType.boolValue)
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { (error) in
            expectationFind = nil
        }
    }
    
}

class DataType: NSObject, Persistable, BooleanType {
    
    dynamic var objectId: String?
    dynamic var boolValue: Bool = false
    
    static func kinveyCollectionName() -> String {
        return "DataType"
    }
    
    static func kinveyPropertyMapping() -> [String : String] {
        return [
            "objectId" : PersistableIdKey,
            "boolValue" : "boolValue"
        ]
    }
    
}
