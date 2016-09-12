//
//  ErrorTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-05-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class ErrorTestCase: XCTestCase {
    
    func testObjectIDMissing() {
        XCTAssertEqual(Error.ObjectIdMissing.localizedDescription, "Object ID is required and is missing")
    }
    
    func testInvalidResponse() {
        XCTAssertEqual(Error.InvalidResponse.localizedDescription, "Invalid response from the server")
    }
    
    func testUnauthorized() {
        XCTAssertEqual(Error.Unauthorized(error: "Error", description: "Description").localizedDescription, "Description")
    }
    
    func testNoActiveUser() {
        XCTAssertEqual(Error.NoActiveUser.localizedDescription, "An active user is required and none was found")
    }
    
    func testRequestCancelled() {
        XCTAssertEqual(Error.RequestCancelled.localizedDescription, "Request was cancelled")
    }
    
    func testInvalidDataStoreType() {
        XCTAssertEqual(Error.InvalidDataStoreType.localizedDescription, "DataStore type does not support this operation")
    }
    
    func testUserWithoutEmailOrUsername() {
        XCTAssertEqual(Error.UserWithoutEmailOrUsername.localizedDescription, "User has no email or username")
    }
    
}
