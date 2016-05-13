//
//  FileTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-05-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class FileTestCase: StoreTestCase {
    
    var file: File?
    
    var fileStore: FileStore {
        return FileStore.getInstance()
    }
    
    override func tearDown() {
        if let file = file, let _ = file.fileId {
            weak var expectationRemove = expectationWithDescription("Remove")
            
            fileStore.remove(file) { (count, error) in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                if let count = count {
                    XCTAssertEqual(count, 1)
                }
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationRemove = nil
            }
        }
        
        super.tearDown()
    }
    
    func testUpload() {
        signUp()
        
        let file = File()
        self.file = file
        file.publicAccessible = true
        let path = NSBundle(forClass: self.dynamicType).pathForResource("Caminandes 3 - TRAILER", ofType: "mp4")!
        
        weak var expectationUpload = expectationWithDescription("Upload")
        
        fileStore.upload(file, path: path) { (file, error) in
            XCTAssertNotNil(file)
            XCTAssertNil(error)
            
            expectationUpload?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationUpload = nil
        }
        
        XCTAssertNotNil(file.fileId)
    }
    
    func testUploadAndResume() {
        signUp()
        
        let file = File()
        self.file = file
        file.publicAccessible = true
        let path = NSBundle(forClass: self.dynamicType).pathForResource("Caminandes 3 - TRAILER", ofType: "mp4")!
        
        do {
            weak var expectationUpload = expectationWithDescription("Upload")
            
            let request = fileStore.upload(file, path: path) { (file, error) in
                XCTFail()
            }
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                request.cancel()
                expectationUpload?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        XCTAssertNotNil(file.fileId)
        
        do {
            weak var expectationUpload = expectationWithDescription("Upload")
            
            fileStore.upload(file, path: path) { (file, error) in
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        do {
            weak var expectationDownload = expectationWithDescription("Download")
            
            fileStore.download(file) { (file, data, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                
                if let data = data {
                    XCTAssertEqual(data.length, 10899706)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationDownload = nil
            }
        }
    }
    
    func testDownloadAndResume() {
        signUp()
        
        let file = File()
        self.file = file
        file.publicAccessible = true
        let path = NSBundle(forClass: self.dynamicType).pathForResource("Caminandes 3 - TRAILER", ofType: "mp4")!
        
        weak var expectationUpload = expectationWithDescription("Upload")
        
        fileStore.upload(file, path: path) { (file, error) in
            XCTAssertNotNil(file)
            XCTAssertNil(error)
            
            expectationUpload?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationUpload = nil
        }
        
        XCTAssertNotNil(file.fileId)
        
        do {
            weak var expectationDownload = expectationWithDescription("Download")
            
            let request = fileStore.download(file) { (file, data, error) in
                XCTFail()
            }
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                request.cancel()
                expectationDownload?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationDownload = nil
            }
        }
        
        XCTAssertNotNil(file.resumeDownloadData)
        if let resumeData = file.resumeDownloadData {
            XCTAssertGreaterThan(resumeData.length, 0)
        }
        
        do {
            weak var expectationDownload = expectationWithDescription("Download")
            
            fileStore.download(file) { (file, data, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                
                if let data = data {
                    XCTAssertEqual(data.length, 10899706)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationDownload = nil
            }
        }
    }
    
}
