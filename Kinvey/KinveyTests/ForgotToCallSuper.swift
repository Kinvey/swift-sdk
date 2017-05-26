//
//  ForgotToCallSuper.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-05-19.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey
import Nimble

class ForgotToCallSuperEntity: Entity {
    
    dynamic var myProperty: String?
    
    override class func collectionName() -> String {
        return "ForgotToCallSuper"
    }
    
    override func propertyMapping(_ map: Map) {
        myProperty <- ("myProperty", map["myProperty"])
    }
    
}

class ForgotToCallSuperEntity2: Entity {
    
    dynamic var myId: String?
    dynamic var myProperty: String?
    
    override class func collectionName() -> String {
        return "ForgotToCallSuper"
    }
    
    override func propertyMapping(_ map: Map) {
        myId <- ("myId", map[Key.entityId])
        myProperty <- ("myProperty", map["myProperty"])
    }
    
}

class ForgotToCallSuperPersistable: Persistable {
    
    dynamic var myProperty: String?
    
    class func collectionName() -> String {
        return "ForgotToCallSuper"
    }
    
    required init() {
    }
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        myProperty <- ("myProperty", map["myProperty"])
    }
    
}

class ForgotToCallSuper: XCTestCase {
    
    func testForgotToCallSuper() {
        expect { () -> Void in
            let _  = ForgotToCallSuperEntity.propertyMappingReverse()
        }.to(throwAssertion())
    }
    
    func testForgotToCallSuper2() {
        expect { () -> Void in
            let _  = ForgotToCallSuperEntity2.propertyMappingReverse()
        }.to(throwAssertion())
    }
    
    func testForgotToCallSuperPersistable() {
        expect { () -> Void in
            let _  = ForgotToCallSuperPersistable.propertyMappingReverse()
        }.to(throwAssertion())
    }
    
}
