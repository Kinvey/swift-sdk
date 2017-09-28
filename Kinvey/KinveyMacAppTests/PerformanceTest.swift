//
//  PerformanceTest.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-07-13.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
import Kinvey
#if os(iOS)
    import KinveyApp
#endif

class PerformanceTest: XCTestCase {
    
    let defaultTimeout: TimeInterval = 30

    func testPerformance() {
        do {
            weak var expectationInit = expectation(description: "Init")
            
            Kinvey.sharedClient.initialize(
                appKey: "",
                appSecret: ""
            ) { (result: Result<User?, Swift.Error>) in
                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationInit?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationInit = nil
            }
        }
        
        if Kinvey.sharedClient.activeUser == nil {
            weak var expectationLogin = expectation(description: "Login")
            
            User.login(
                username: "",
                password: "",
                options: nil
            ) { (result: Result<User, Swift.Error>) in
                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationLogin?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationLogin = nil
            }
        }
        
        guard Kinvey.sharedClient.activeUser != nil else {
            return
        }
        
        let sapCustomerNumbers = [
            "SBOOK" : 210893,
            "MA00056" : 2261,
            "MA00452" : 43825,
            "MA20313" : 340,
            "MA00040" : 45131,
            "MA00405" : 49128,
            "MA09200" : 41448,
            "MA09208" : 41688,
            "MA20128" : 46068,
            "MA20404" : 201670,
            "MA20280" : 202011
        ]
        let sapCustomerNumbersTotal = sapCustomerNumbers.reduce(0, { $0 + $1.value })
        XCTAssertEqual(884463, sapCustomerNumbersTotal)
        
        let dataStore = DataStore<HierarchyCache>.collection()
        dataStore.clearCache()
        
        Kinvey.logLevel = .warning
        
        for (sapCustomerNumber, expectedCount) in sapCustomerNumbers {
            weak var expectationFindLocal = expectation(description: "Find Local")
            weak var expectationFindNetwork = expectation(description: "Find Network")
            
            let query = Query(format: "sapCustomerNumber == %@", sapCustomerNumber)
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            dataStore.count(query, options: nil) { (result: Result<Int, Swift.Error>) in
                if expectationFindLocal != nil {
                    switch result {
                    case .success(let count):
                        XCTAssertEqual(count, 0)
                    case .failure(let error):
                        print(error)
                        XCTFail()
                    }
                    expectationFindLocal?.fulfill()
                    expectationFindLocal = nil
                } else {
                    switch result {
                    case .success(let count):
                        XCTAssertEqual(count, expectedCount)
                    case .failure(let error):
                        print(error)
                        XCTFail()
                    }
                    expectationFindNetwork?.fulfill()
                }
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFindLocal = nil
                expectationFindNetwork = nil
            }
            
            print("Time elapsed to count \(sapCustomerNumber): \(CFAbsoluteTimeGetCurrent() - startTime) s.")
        }
        
        Kinvey.sharedClient.timeoutInterval = 600
        let limit = 10000
        
        measure {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            dataStore.clearCache()
            
            for (sapCustomerNumber, expectedCount) in sapCustomerNumbers {
                var count = Int64(0)
                for offset in stride(from: 0, to: expectedCount, by: limit) {
                    var expectationFindLocal: XCTestExpectation? = self.expectation(description: "Find Local \(sapCustomerNumber) \(offset)/\(expectedCount)")
                    let expectationFindNetwork = self.expectation(description: "Find Network \(sapCustomerNumber) \(offset)/\(expectedCount)")
                    
                    let query = Query(format: "sapCustomerNumber == %@", sapCustomerNumber)
                    query.limit = limit
                    query.skip = offset
                    
                    dataStore.find(query, options: nil) { (result: Result<AnyRandomAccessCollection<HierarchyCache>, Swift.Error>) in
                        if expectationFindLocal != nil {
                            expectationFindLocal?.fulfill()
                            expectationFindLocal = nil
                        } else {
                            switch result {
                            case .success(let results):
                                count += results.count
                            case .failure(let error):
                                XCTFail(error.localizedDescription)
                            }
                            
                            expectationFindNetwork.fulfill()
                        }
                    }
                }
                XCTAssertEqual(count, Int64(expectedCount))
            }
            
            self.waitForExpectations(timeout: TimeInterval(UInt16.max))
            
            print("Time elapsed: \(CFAbsoluteTimeGetCurrent() - startTime) s.")
        }
    }
    
    func testPerformanceAutoPaginationEnabled() {
        do {
            weak var expectationInit = expectation(description: "Init")
            
            Kinvey.sharedClient.initialize(
                appKey: "",
                appSecret: ""
            ) { (result: Result<User?, Swift.Error>) in
                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationInit?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationInit = nil
            }
        }
        
        if Kinvey.sharedClient.activeUser == nil {
            weak var expectationLogin = expectation(description: "Login")
            
            User.login(
                username: "",
                password: "",
                options: nil
            ) { (result: Result<User, Swift.Error>) in
                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationLogin?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationLogin = nil
            }
        }
        
        guard Kinvey.sharedClient.activeUser != nil else {
            return
        }
        
        let sapCustomerNumbers = [
            "SBOOK" : 210893,
            "MA00056" : 2261,
            "MA00452" : 43825,
            "MA20313" : 340,
            "MA00040" : 45131,
            "MA00405" : 49128,
            "MA09200" : 41448,
            "MA09208" : 41688,
            "MA20128" : 46068,
            "MA20404" : 201670,
            "MA20280" : 202011
        ]
        let sapCustomerNumbersTotal = sapCustomerNumbers.reduce(0, { $0 + $1.value })
        XCTAssertEqual(884463, sapCustomerNumbersTotal)
        
        let dataStore = DataStore<HierarchyCache>.collection(autoPagination: true)
        dataStore.clearCache()
        
        Kinvey.logLevel = .warning
        
        for (sapCustomerNumber, expectedCount) in sapCustomerNumbers {
            weak var expectationFindLocal = expectation(description: "Find Local")
            weak var expectationFindNetwork = expectation(description: "Find Network")
            
            let query = Query(format: "sapCustomerNumber == %@", sapCustomerNumber)
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            dataStore.count(query, options: nil) { (result: Result<Int, Swift.Error>) in
                if expectationFindLocal != nil {
                    switch result {
                    case .success(let count):
                        XCTAssertEqual(count, 0)
                    case .failure(let error):
                        print(error)
                        XCTFail()
                    }
                    expectationFindLocal?.fulfill()
                    expectationFindLocal = nil
                } else {
                    switch result {
                    case .success(let count):
                        XCTAssertEqual(count, expectedCount)
                    case .failure(let error):
                        print(error)
                        XCTFail()
                    }
                    expectationFindNetwork?.fulfill()
                }
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFindLocal = nil
                expectationFindNetwork = nil
            }
            
            print("Time elapsed to count \(sapCustomerNumber): \(CFAbsoluteTimeGetCurrent() - startTime) s.")
        }
        
        Kinvey.sharedClient.timeoutInterval = 600
        
        measure {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            dataStore.clearCache()
            
            for (sapCustomerNumber, expectedCount) in sapCustomerNumbers {
                var expectationFindLocal: XCTestExpectation? = self.expectation(description: "Find Local \(sapCustomerNumber) Auto Pagination Enabled")
                let expectationFindNetwork = self.expectation(description: "Find Network \(sapCustomerNumber) Auto Pagination Enabled")
                
                let query = Query(format: "sapCustomerNumber == %@", sapCustomerNumber)
                
                dataStore.find(query, options: nil) { (result: Result<AnyRandomAccessCollection<HierarchyCache>, Swift.Error>) in
                    if expectationFindLocal != nil {
                        expectationFindLocal?.fulfill()
                        expectationFindLocal = nil
                    } else {
                        switch result {
                        case .success(let results):
                            XCTAssertEqual(results.count, Int64(expectedCount))
                        case .failure(let error):
                            XCTFail(error.localizedDescription)
                        }
                        
                        expectationFindNetwork.fulfill()
                    }
                }
            }
            
            self.waitForExpectations(timeout: TimeInterval(UInt16.max))
            
            print("Time elapsed: \(CFAbsoluteTimeGetCurrent() - startTime) s.")
        }
    }

}
