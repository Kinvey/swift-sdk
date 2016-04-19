//
//  JsonTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-19.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class JsonTestCase: StoreTestCase {
    
    func testFromToJson() {
        signUp()
        
        let storeProject = DataStore<RefProject>.getInstance(.Network, client: client)
        
        let project = RefProject()
        project.name = "Mall"
        
        weak var expectationCreateMall = expectationWithDescription("CreateMall")
        
        storeProject.save(project) { (project, error) -> Void in
            self.assertThread()
            XCTAssertNotNil(project)
            XCTAssertNil(error)
            
            if let project = project {
                XCTAssertNotNil(project.uniqueId)
                XCTAssertNotEqual(project.uniqueId, "")
            }
            
            expectationCreateMall?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationCreateMall = nil
        }
        
        XCTAssertNotNil(project.uniqueId)
        XCTAssertNotEqual(project.uniqueId, "")
        
        let storeDirectory = DataStore<DirectoryEntry>.getInstance(.Network, client: client)
        
        let directory = DirectoryEntry()
        directory.nameFirst = "Victor"
        directory.nameLast = "Barros"
        directory.email = "victor@kinvey.com"
        directory.refProject = project
        
        weak var expectationCreateDirectory = expectationWithDescription("CreateDirectory")
        
        storeDirectory.save(directory) { (directory, error) -> Void in
            self.assertThread()
            XCTAssertNotNil(directory)
            XCTAssertNil(error)
            
            if let directory = directory {
                XCTAssertNotNil(directory.uniqueId)
                XCTAssertNotEqual(directory.uniqueId, "")
            }
            
            expectationCreateDirectory?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationCreateDirectory = nil
        }
    }
    
}
