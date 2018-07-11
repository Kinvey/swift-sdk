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
        
        let storeProject = DataStore<RefProject>.collection(.network, options: Options(client: client))
        
        var project = RefProject()
        project.name = "Mall"
        
        do {
            if useMockData {
                mockResponse(statusCode: 201, json: [
                    "name": "Mall",
                    "_acl": [
                        "creator": "58450b92c077970e38a36e04"
                    ],
                    "_kmd": [
                        "lmt": "2016-12-05T06:39:14.797Z",
                        "ect": "2016-12-05T06:39:14.797Z"
                    ],
                    "_id": "58450b9231bd8a5e0f145e97"
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationCreateMall = expectation(description: "CreateMall")
            
            storeProject.save(project) {
                self.assertThread()
                switch $0 {
                case .success(let _project):
                    project = _project
                    XCTAssertNotNil(project.uniqueId)
                    XCTAssertNotEqual(project.uniqueId, "")
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationCreateMall?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCreateMall = nil
            }
        }
        
        XCTAssertNotNil(project.uniqueId)
        XCTAssertNotEqual(project.uniqueId, "")
        
        let storeDirectory = DataStore<DirectoryEntry>.collection(.network, options: Options(client: client))
        
        let directory = DirectoryEntry()
        directory.nameFirst = "Victor"
        directory.nameLast = "Barros"
        directory.email = "victor@kinvey.com"
        directory.refProject = project
        
        do {
            if useMockData {
                mockResponse(statusCode: 201, json: [
                    "email": "victor@kinvey.com",
                    "nameFirst": "Victor",
                    "nameLast": "Barros",
                    "_acl": [
                        "creator": "58450b92c077970e38a36e04"
                    ],
                    "_kmd": [
                        "lmt": "2016-12-05T06:39:14.937Z",
                        "ect": "2016-12-05T06:39:14.937Z"
                    ],
                    "_id": "58450b92d5ee86507a8b415d"
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationCreateDirectory = expectation(description: "CreateDirectory")
            
            storeDirectory.save(directory) {
                self.assertThread()
                switch $0 {
                case .success(let directory):
                    XCTAssertNotNil(directory.uniqueId)
                    XCTAssertNotEqual(directory.uniqueId, "")
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationCreateDirectory?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCreateDirectory = nil
            }
        }
    }
    
}
