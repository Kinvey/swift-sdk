//
//  PerformanceTest.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-07-13.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
import Kinvey

class HierarchyCache: Entity {
    
    dynamic var salesOrganization: String?
    dynamic var distributionChannel: String?
    dynamic var sapCustomerNumber: String?
    dynamic var materialNumber: String?
    dynamic var conditionType: String?
    dynamic var salesDivision: String?
    dynamic var validityStartDate: String?
    dynamic var validityEndDate: String?
    dynamic var price: String?
    dynamic var currency: String?
    dynamic var deliveryUnit: String?
    dynamic var unitQuantity: String?
    dynamic var unitOfMeasure: String?
    
    override class func collectionName() -> String {
        return "hierarchycache"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        salesOrganization <- ("salesOrganization", map["SalesOrganization"])
        distributionChannel <- ("distributionChannel", map["DistributionChannel"])
        sapCustomerNumber <- ("sapCustomerNumber", map["SAPCustomerNumber"])
        materialNumber <- ("materialNumber", map["MaterialNumber"])
        conditionType <- ("conditionType", map["ConditionType"])
        salesDivision <- ("salesDivision", map["SalesDivision"])
        validityStartDate <- ("validityStartDate", map["ValidityStartDate"])
        validityEndDate <- ("validityEndDate", map["ValidityEndDate"])
        price <- ("price", map["Price"])
        currency <- ("currency", map["Currency"])
        deliveryUnit <- ("deliveryUnit", map["DeliveryUnit"])
        unitQuantity <- ("unitQuantity", map["UnitQuantity"])
        unitOfMeasure <- ("unitOfMeasure", map["UnitOfMeasure"])
    }
    
}

class PerformanceTest: XCTestCase {

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
            
            waitForExpectations(timeout: KinveyTestCase.defaultTimeout) { (error) in
                expectationInit = nil
            }
        }
        
        if Kinvey.sharedClient.activeUser == nil {
            weak var expectationLogin = expectation(description: "Login")
            
            User.login(
                username: "ccalato",
                password: "ccalato",
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
            
            waitForExpectations(timeout: KinveyTestCase.defaultTimeout) { (error) in
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
//        Kinvey.sharedClient.logNetworkEnabled = true
        
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
            
            waitForExpectations(timeout: KinveyTestCase.defaultTimeout) { (error) in
                expectationFindLocal = nil
                expectationFindNetwork = nil
            }
            
            print("Time elapsed to count \(sapCustomerNumber): \(CFAbsoluteTimeGetCurrent() - startTime) s.")
        }
        
        Kinvey.sharedClient.timeoutInterval = 600
        let limit = 10000
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for (sapCustomerNumber, expectedCount) in sapCustomerNumbers {
            for offset in stride(from: 0, to: expectedCount, by: limit) {
                var expectationFindLocal: XCTestExpectation? = expectation(description: "Find Local \(sapCustomerNumber) \(offset)/\(expectedCount)")
                let expectationFindNetwork = expectation(description: "Find Network \(sapCustomerNumber) \(offset)/\(expectedCount)")
                
                let query = Query(format: "sapCustomerNumber == %@", sapCustomerNumber)
                query.limit = limit
                query.skip = offset
                
                dataStore.find(query, options: nil) { (result: Result<[HierarchyCache], Swift.Error>) in
                    if expectationFindLocal != nil {
                        expectationFindLocal?.fulfill()
                        expectationFindLocal = nil
                    } else {
                        switch result {
                        case .success(_):
                            break
                        case .failure(let error):
                            XCTFail(error.localizedDescription)
                        }
                        
                        expectationFindNetwork.fulfill()
                    }
                }
            }
        }
        
        waitForExpectations(timeout: TimeInterval(UInt16.max))
        
        print("Time elapsed: \(CFAbsoluteTimeGetCurrent() - startTime) s.")
    }

}
