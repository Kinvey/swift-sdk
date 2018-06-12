//
//  DeviceInfoTests.swift
//  KinveyTests
//
//  Created by Victor Hugo Carvalho Barros on 2018-06-12.
//  Copyright © 2018 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class DeviceInfoTests: XCTestCase {
    
    func testDeviceInfoIsSimulator() {
        #if os(iOS)
            XCTAssertTrue(DeviceInfo.isSimulator)
        #else
            XCTAssertFalse(DeviceInfo.isSimulator)
        #endif
    }
    
}
