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
    
    @objc
    dynamic var myProperty: String?
    
    override class func collectionName() -> String {
        return "ForgotToCallSuper"
    }
    
    @available(*, deprecated)
    override func propertyMapping(_ map: Map) {
        myProperty <- ("myProperty", map["myProperty"])
    }
    
}

class ForgotToCallSuperEntity2: Entity {
    
    @objc
    dynamic var myId: String?
    
    @objc
    dynamic var myProperty: String?
    
    override class func collectionName() -> String {
        return "ForgotToCallSuper"
    }
    
    @available(*, deprecated)
    override func propertyMapping(_ map: Map) {
        myId <- ("myId", map[EntityCodingKeys.entityId])
        myProperty <- ("myProperty", map["myProperty"])
    }
    
}

class ForgotToCallSuperPersistable: Persistable {
    
    
    @objc
    dynamic var myProperty: String?
    
    class func collectionName() -> String {
        return "ForgotToCallSuper"
    }
    
    class func translate(property: String) throws -> String? {
        return nil
    }
    
    required init() {
    }
    
    @available(*, deprecated)
    required init?(map: Map) {
    }
    
    @available(*, deprecated)
    func mapping(map: Map) {
        myProperty <- ("myProperty", map["myProperty"])
    }
    
    static func decode<T>(from data: Data) throws -> T {
        return ForgotToCallSuperPersistable() as! T
    }
    
    static func decodeArray<T>(from data: Data) throws -> [T] where T : JSONDecodable {
        return [ForgotToCallSuperPersistable]() as! [T]
    }
    
    static func decode<T>(from dictionary: [String : Any]) throws -> T where T : JSONDecodable {
        return ForgotToCallSuperPersistable() as! T
    }
    
    func refresh(from dictionary: [String : Any]) throws {
    }
    
    func encode() throws -> [String : Any] {
        return [:]
    }
    
}

class ForgotToCallSuper: XCTestCase {
    
    func testForgotToCallSuper() {
        expect {
            try ForgotToCallSuperEntity.propertyMappingReverse()
        }.to(throwError())
    }
    
    func testForgotToCallSuper2() {
        expect {
            try ForgotToCallSuperEntity2.propertyMappingReverse()
        }.to(throwError())
    }
    
    func testForgotToCallSuperPersistable() {
        expect {
            try ForgotToCallSuperPersistable.propertyMappingReverse()
        }.to(throwError())
    }
    
}
