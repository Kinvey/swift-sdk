//
//  RealtimeAclTestCase.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-08-25.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
import Kinvey

class RealtimeAclTestCase: KinveyTestCase {
    
    func testLiveStreamAclConsturctorNoParams() {
        let acl = LiveStreamAcl()
        XCTAssertNotNil(acl)
    }
    
}
