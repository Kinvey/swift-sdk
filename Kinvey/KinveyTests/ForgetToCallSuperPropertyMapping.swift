//
//  ForgetToCallSuperPropertyMapping.swift
//  Kinvey
//
//  Created by Victor Hugo on 2016-12-12.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey
import ObjectMapper
import CwlPreconditionTesting

class PersonForgetToCallSuperPropertyMapping: Entity {
    
    dynamic var personId: String?
    dynamic var _acl: Acl?
    dynamic var name: String?
    
    override class func collectionName() -> String {
        return "PersonForgetToCallSuperPropertyMapping"
    }
    
    override func propertyMapping(_ map: Map) {
        personId <- ("personId", map[PersistableIdKey])
        _acl <- ("_acl", map[PersistableAclKey])
        name <- map["name"]
    }
}

class ForgetToCallSuperPropertyMapping: XCTestCase {
#if arch(x86_64)
    func testKmdMissing() {
        var reachedPoint1 = false
        var reachedPoint2 = false
        let exception = catchBadInstruction {
            reachedPoint1 = true
            
            weak var expectationInitialize = expectation(description: "Initialize")
            
            Kinvey.sharedClient.initialize(appKey: "appKey", appSecret: "appSecret") { _ in
                expectationInitialize?.fulfill()
            }
            
            waitForExpectations(timeout: KinveyTestCase.defaultTimeout) { error in
                expectationInitialize = nil
            }
            
            _ = DataStore<PersonForgetToCallSuperPropertyMapping>.collection()
            
            reachedPoint2 = true
        }
        
        XCTAssertNotNil(exception)
        XCTAssertTrue(reachedPoint1)
        XCTAssertFalse(reachedPoint2)
    }
#endif
}
