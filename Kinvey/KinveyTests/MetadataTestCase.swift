//
//  MetadataTestCase.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-05-19.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey
import ObjectMapper

class MetadataTestCase: XCTestCase {
    
    func testMetadata() {
        let authToken = UUID().uuidString
        
        let lrt = Date()
        let lmt = Date(timeIntervalSinceNow: 1)
        let ect = Date(timeIntervalSinceNow: 2)
        
        let json = [
            Metadata.Key.lastModifiedTime: lmt.toString(),
            Metadata.Key.entityCreationTime: ect.toString(),
            Metadata.Key.authtoken: authToken
        ]
        let metadata = Metadata(JSON: json)
        XCTAssertNotNil(metadata)
        if let metadata = metadata {
            XCTAssertEqual(metadata.lastModifiedTime!.timeIntervalSinceReferenceDate, lmt.timeIntervalSinceReferenceDate, accuracy: 0.0009)
            XCTAssertEqual(metadata.entityCreationTime!.timeIntervalSinceReferenceDate, ect.timeIntervalSinceReferenceDate, accuracy: 0.0009)
            XCTAssertEqual(metadata.lastReadTime.timeIntervalSinceReferenceDate, lrt.timeIntervalSinceReferenceDate, accuracy: 0.9999)
            XCTAssertEqual(metadata.authtoken, authToken)
        }
    }
    
}
