//
//  RemoveAllMemoryLeakTests.swift
//  KinveyTests
//
//  Created by Victor Hugo Carvalho Barros on 2018-07-11.
//  Copyright © 2018 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class RemoveAllMemoryLeakTests: StoreTestCase {
    
    var mockCount = 0
    
    override func setUp() {
        super.setUp()
        
        signUp()
        
        store = try! DataStore<Person>.collection(.sync)
    }
    
    override func tearDown() {
        if let activeUser = client.activeUser {
            let store = try! DataStore<Person>.collection(.network)
            let query = Query(format: "\(try! Person.aclProperty() ?? Person.EntityCodingKeys.acl.rawValue).creator == %@", activeUser.userId)
            
            if useMockData {
                mockResponse(json: ["count" : mockCount])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
                mockCount = 0
            }
            
            weak var expectationRemoveAll = expectation(description: "Remove All")
            
            store.remove(query) {
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationRemoveAll?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationRemoveAll = nil
            }
        }
        
        super.tearDown()
    }
    
    func testRemoveAllMemoryLeak() {
        let timer = startLogPolling()
        let reportMemory1 = reportMemory()!
        
        let count = 10_000
        let range = 1 ... count
        let json = range.map { i in
            Person {
                $0.personId = UUID().uuidString
                $0.age = i
            }.toJSON()
        }
        mockResponse(json: json)
        defer {
            timer.cancel()
            setURLProtocol(nil)
        }
        
        let reportMemory2 = reportMemory()!
        XCTAssertLessThan(reportMemory2 - reportMemory1, 1024 * 1024 * 50) // 50 Mb
        
        autoreleasepool {
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull() {
                self.assertThread()
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, count)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        let reportMemory3 = reportMemory()!
        XCTAssertLessThan(reportMemory3 - reportMemory2, 1024 * 1024 * 50) // 50 Mb
        
        autoreleasepool {
            weak var expectationRemove = expectation(description: "Remove")
            
            store.removeAll() {
                self.assertThread()
                switch $0 {
                case .success(let count):
                    XCTAssertEqual(count, count)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRemove = nil
            }
        }
        
        let reportMemory4 = reportMemory()!
        XCTAssertLessThan(reportMemory4 - reportMemory3, 1024 * 1024 * 50) // 50 Mb
    }
    
}
