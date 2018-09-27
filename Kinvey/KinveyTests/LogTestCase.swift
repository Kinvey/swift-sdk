//
//  LogTestCase.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-05-18.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey
import SwiftyBeaver

class LogTestCase: XCTestCase {
    
    var originalLogLevel: LogLevel!
    
    override func setUp() {
        originalLogLevel = logLevel
    }
    
    override func tearDown() {
        logLevel = originalLogLevel
    }
    
    func testLogLevelInitialState() {
        XCTAssertEqual(Kinvey.log.destinations.first?.minLevel, SwiftyBeaver.Level.warning)
        XCTAssertEqual(Kinvey.LogLevel.warning, SwiftyBeaver.Level.warning.logLevel)
    }
    
    func testLogLevelVerbose() {
        logLevel = .verbose
        XCTAssertEqual(Kinvey.log.destinations.first?.minLevel, SwiftyBeaver.Level.verbose)
        XCTAssertEqual(logLevel, SwiftyBeaver.Level.verbose.logLevel)
    }
    
    func testLogLevelDebug() {
        logLevel = .debug
        XCTAssertEqual(Kinvey.log.destinations.first?.minLevel, SwiftyBeaver.Level.debug)
        XCTAssertEqual(logLevel, SwiftyBeaver.Level.debug.logLevel)
    }
    
    func testLogLevelInfo() {
        logLevel = .info
        XCTAssertEqual(Kinvey.log.destinations.first?.minLevel, SwiftyBeaver.Level.info)
        XCTAssertEqual(logLevel, SwiftyBeaver.Level.info.logLevel)
    }
    
    func testLogLevelWarning() {
        logLevel = .warning
        XCTAssertEqual(Kinvey.log.destinations.first?.minLevel, SwiftyBeaver.Level.warning)
        XCTAssertEqual(logLevel, SwiftyBeaver.Level.warning.logLevel)
    }
    
    func testLogLevelError() {
        logLevel = .error
        XCTAssertEqual(Kinvey.log.destinations.first?.minLevel, SwiftyBeaver.Level.error)
        XCTAssertEqual(logLevel, SwiftyBeaver.Level.error.logLevel)
    }
    
}
