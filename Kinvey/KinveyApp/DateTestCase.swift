//
//  DateTestCase.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-04-24.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class DateTestCase: XCTestCase {
    
    func testDateFormatWithMillis() {
        XCTAssertEqual("2017-03-30T12:30:00.733Z".toDate(), Date(timeIntervalSince1970: 1490877000.733))
    }
    
    func testDateFormatWithoutMillis() {
        XCTAssertEqual("2017-03-30T12:30:00Z".toDate(), Date(timeIntervalSince1970: 1490877000))
    }
    
    func testDateFormatNotSupported() {
        XCTAssertNil("2017-03-30 12:30:00".toDate())
    }
    
    func testTTLSeconds() {
        let (time, unit) = 10.seconds
        XCTAssertEqual(unit.toTimeInterval(time), TimeInterval(10))
    }
    
    func testTTLMinutes() {
        let (time, unit) = 10.minutes
        XCTAssertEqual(unit.toTimeInterval(time), TimeInterval(10 * 60))
    }
    
    func testTTLHours() {
        let (time, unit) = 10.hours
        XCTAssertEqual(unit.toTimeInterval(time), TimeInterval(10 * 60 * 60))
    }
    
    func testTTLDays() {
        let (time, unit) = 10.days
        XCTAssertEqual(unit.toTimeInterval(time), TimeInterval(10 * 60 * 60 * 24))
    }
    
    func testTTLWeeks() {
        let (time, unit) = 10.weeks
        XCTAssertEqual(unit.toTimeInterval(time), TimeInterval(10 * 60 * 60 * 24 * 7))
    }
    
}
