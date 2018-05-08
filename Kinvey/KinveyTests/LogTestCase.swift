//
//  LogTestCase.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-05-18.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey
import XCGLogger

class LogTestCase: XCTestCase {
    
    var originalLogLevel: LogLevel!
    
    override func setUp() {
        originalLogLevel = logLevel
    }
    
    override func tearDown() {
        logLevel = originalLogLevel
    }
    
    func testLogLevelInitialState() {
        XCTAssertEqual(Kinvey.log.outputLevel, XCGLogger.Level.warning)
        XCTAssertEqual(Kinvey.LogLevel.warning, XCGLogger.Level.warning.logLevel)
    }
    
    func testLogLevelVerbose() {
        logLevel = .verbose
        XCTAssertEqual(Kinvey.log.outputLevel, XCGLogger.Level.verbose)
        XCTAssertEqual(logLevel, XCGLogger.Level.verbose.logLevel)
    }
    
    func testLogLevelDebug() {
        logLevel = .debug
        XCTAssertEqual(Kinvey.log.outputLevel, XCGLogger.Level.debug)
        XCTAssertEqual(logLevel, XCGLogger.Level.debug.logLevel)
    }
    
    func testLogLevelInfo() {
        logLevel = .info
        XCTAssertEqual(Kinvey.log.outputLevel, XCGLogger.Level.info)
        XCTAssertEqual(logLevel, XCGLogger.Level.info.logLevel)
    }
    
    func testLogLevelWarning() {
        logLevel = .warning
        XCTAssertEqual(Kinvey.log.outputLevel, XCGLogger.Level.warning)
        XCTAssertEqual(logLevel, XCGLogger.Level.warning.logLevel)
    }
    
    func testLogLevelError() {
        logLevel = .error
        XCTAssertEqual(Kinvey.log.outputLevel, XCGLogger.Level.error)
        XCTAssertEqual(logLevel, XCGLogger.Level.error.logLevel)
    }
    
    func testLogLevelSevere() {
        logLevel = .severe
        XCTAssertEqual(Kinvey.log.outputLevel, XCGLogger.Level.severe)
        XCTAssertEqual(logLevel, XCGLogger.Level.severe.logLevel)
    }
    
    func testLogLevelNone() {
        logLevel = .none
        XCTAssertEqual(Kinvey.log.outputLevel, XCGLogger.Level.none)
        XCTAssertEqual(logLevel, XCGLogger.Level.none.logLevel)
    }
    
}
