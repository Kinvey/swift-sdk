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
    
    lazy var fileStore: FileStore = {
        return FileStore.getInstance()
    }()
    
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
    
    private func reportMemory() -> Int64? {
        var info = task_basic_info()
        var count = mach_msg_type_number_t(sizeofValue(info))/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(&info) {
            
            task_info(mach_task_self_,
                      task_flavor_t(TASK_BASIC_INFO),
                      task_info_t($0),
                      &count)
            
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        }
        
        return nil
    }
    
    func testUpload() {
        signUp()
        
        let file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let path = NSBundle(forClass: self.dynamicType).pathForResource("Caminandes 3 - TRAILER", ofType: "mp4")!
        
        weak var expectationUpload = expectationWithDescription("Upload")
        
        let memoryBefore = reportMemory()
        XCTAssertNotNil(memoryBefore)
        
        fileStore.upload(file, path: path) { (file, error) in
            XCTAssertTrue(NSThread.isMainThread())
            XCTAssertNotNil(file)
            XCTAssertNil(error)
            
            let memoryNow = self.reportMemory()
            XCTAssertNotNil(memoryNow)
            if let memoryBefore = memoryBefore, let memoryNow = memoryNow {
                let diff = memoryNow - memoryBefore
                XCTAssertLessThan(diff, 10899706)
            }
            
            expectationUpload?.fulfill()
        }
        
        let memoryNow = reportMemory()
        XCTAssertNotNil(memoryNow)
        if let memoryBefore = memoryBefore, let memoryNow = memoryNow {
            let diff = memoryNow - memoryBefore
            XCTAssertLessThan(diff, 10899706)
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationUpload = nil
        }
        
        XCTAssertNotNil(file.fileId)
        
        do {
            weak var expectationDownload = expectationWithDescription("Download")
            
            fileStore.download(file) { (file, data: NSData?, error) in
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
    
    func testUploadAndResume() {
        signUp()
        
        let file = File() {
            $0.publicAccessible = true
        }
        self.file = file
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
            weak var expectationWait = expectationWithDescription("Wait")
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                expectationWait?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationWait = nil
            }
        }
        
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
            
            fileStore.download(file) { (file, data: NSData?, error) in
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
        
        let file = File() {
            $0.publicAccessible = true
        }
        self.file = file
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
            
            let request = fileStore.download(file) { (file, data: NSData?, error) in
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
            
            fileStore.download(file) { (file, data: NSData?, error) in
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
    
    func testUploadDataDownloadPath() {
        signUp()
        
        let file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let data = "Hello".dataUsingEncoding(NSUTF8StringEncoding)!
        
        do {
            weak var expectationUpload = expectationWithDescription("Upload")
            
            fileStore.upload(file, data: data) { (file, error) in
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        XCTAssertNotNil(file.fileId)
        
        do {
            weak var expectationDownload = expectationWithDescription("Download")
            
            fileStore.download(file) { (file, url: NSURL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNil(error)
                
                if let url = url, let data = NSData(contentsOfURL: url) {
                    XCTAssertEqual(data.length, data.length)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationDownload = nil
            }
        }
        
        do {
            weak var expectationCached = expectationWithDescription("Cached")
            weak var expectationDownload = expectationWithDescription("Download")
            
            fileStore.download(file) { (file, url: NSURL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNotNil(url?.path)
                XCTAssertNil(error)
                
                if let url = url,
                    let path = url.path,
                    let dataTmp = NSData(contentsOfFile: (path as NSString).stringByExpandingTildeInPath)
                {
                    XCTAssertEqual(dataTmp.length, data.length)
                } else {
                    XCTFail()
                }
                
                if let _ = expectationCached {
                    expectationCached?.fulfill()
                    expectationCached = nil
                } else {
                    expectationDownload?.fulfill()
                }
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationCached = nil
                expectationDownload = nil
            }
        }
        
        let data2 = "Hello World".dataUsingEncoding(NSUTF8StringEncoding)!
        
        do {
            weak var expectationUpload = expectationWithDescription("Upload")
            
            fileStore.upload(file, data: data2) { (file, error) in
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        do {
            weak var expectationCached = expectationWithDescription("Cached")
            weak var expectationDownload = expectationWithDescription("Download")
            
            fileStore.download(file) { (file, url: NSURL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNotNil(url?.path)
                XCTAssertNil(error)
                
                if let _ = expectationCached {
                    if let url = url,
                        let path = url.path,
                        let dataTmp = NSData(contentsOfFile: (path as NSString).stringByExpandingTildeInPath)
                    {
                        XCTAssertEqual(dataTmp.length, data.length)
                    } else {
                        XCTFail()
                    }
                    
                    expectationCached?.fulfill()
                    expectationCached = nil
                } else {
                    if let url = url,
                        let path = url.path,
                        let dataTmp = NSData(contentsOfFile: (path as NSString).stringByExpandingTildeInPath)
                    {
                        XCTAssertEqual(dataTmp.length, data2.length)
                    } else {
                        XCTFail()
                    }
                    
                    expectationDownload?.fulfill()
                }
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationCached = nil
                expectationDownload = nil
            }
        }
    }
    
    func testUploadPathDownloadPath() {
        signUp()
        
        let file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let data = "Hello".dataUsingEncoding(NSUTF8StringEncoding)!
        
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("upload").path!
        XCTAssertTrue(data.writeToFile(path, atomically: true))
        
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
        
        XCTAssertNotNil(file.fileId)
        
        do {
            weak var expectationDownload = expectationWithDescription("Download")
            
            fileStore.download(file) { (file, url: NSURL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNil(error)
                
                if let url = url, let data = NSData(contentsOfURL: url) {
                    XCTAssertEqual(data.length, data.length)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationDownload = nil
            }
        }
        
        do {
            weak var expectationCached = expectationWithDescription("Cached")
            weak var expectationDownload = expectationWithDescription("Download")
            
            fileStore.download(file) { (file, url: NSURL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNotNil(url?.path)
                XCTAssertNil(error)
                
                if let url = url,
                    let path = url.path,
                    let dataTmp = NSData(contentsOfFile: (path as NSString).stringByExpandingTildeInPath)
                {
                    XCTAssertEqual(dataTmp.length, data.length)
                } else {
                    XCTFail()
                }
                
                if let _ = expectationCached {
                    expectationCached?.fulfill()
                    expectationCached = nil
                } else {
                    expectationDownload?.fulfill()
                }
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationCached = nil
                expectationDownload = nil
            }
        }
        
        let data2 = "Hello World".dataUsingEncoding(NSUTF8StringEncoding)!
        XCTAssertTrue(data2.writeToFile(path, atomically: true))
        
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
            weak var expectationCached = expectationWithDescription("Cached")
            weak var expectationDownload = expectationWithDescription("Download")
            
            fileStore.download(file) { (file, url: NSURL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNotNil(url?.path)
                XCTAssertNil(error)
                
                if let _ = expectationCached {
                    if let url = url,
                        let path = url.path,
                        let dataTmp = NSData(contentsOfFile: (path as NSString).stringByExpandingTildeInPath)
                    {
                        XCTAssertEqual(dataTmp.length, data.length)
                    } else {
                        XCTFail()
                    }
                    
                    expectationCached?.fulfill()
                    expectationCached = nil
                } else {
                    if let url = url,
                        let path = url.path,
                        let dataTmp = NSData(contentsOfFile: (path as NSString).stringByExpandingTildeInPath)
                    {
                        XCTAssertEqual(dataTmp.length, data2.length)
                    } else {
                        XCTFail()
                    }
                    
                    expectationDownload?.fulfill()
                }
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationCached = nil
                expectationDownload = nil
            }
        }
    }
    
    func testUploadTTLExpired() {
        signUp()
        
        let file = File() {
            $0.publicAccessible = false
        }
        self.file = file
        let data = "Hello".dataUsingEncoding(NSUTF8StringEncoding)!
        
        let beforeDate = NSDate()
        let ttl = TTL(10, .Second)
        
        do {
            weak var expectationUpload = expectationWithDescription("Upload")
            
            fileStore.upload(file, data: data, ttl: ttl) { (file, error) in
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        XCTAssertNotNil(file.fileId)
        XCTAssertNotNil(file.expiresAt)
        
        if let expiresAt = file.expiresAt {
            XCTAssertGreaterThan(expiresAt.timeIntervalSinceDate(beforeDate), ttl.1.toTimeInterval(ttl.0))
            
            let twentySecs = TTL(20, .Second)
            XCTAssertLessThan(expiresAt.timeIntervalSinceDate(beforeDate), twentySecs.1.toTimeInterval(twentySecs.0))
        }
    }
    
    func testDownloadTTLExpired() {
        signUp()
        
        let file = File() {
            $0.publicAccessible = false
        }
        self.file = file
        let data = "Hello".dataUsingEncoding(NSUTF8StringEncoding)!
        
        let ttl = TTL(10, .Second)
        
        do {
            weak var expectationUpload = expectationWithDescription("Upload")
            
            fileStore.upload(file, data: data) { (file, error) in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        XCTAssertNotNil(file.fileId)
        
        file.download = nil
        file.expiresAt = nil
        
        let beforeDate = NSDate()
        
        do {
            weak var expectationDownload = expectationWithDescription("Download")
            
            fileStore.download(file, ttl: ttl) { (file, url: NSURL?, error) in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNil(error)
                
                if let url = url, let data = NSData(contentsOfURL: url) {
                    XCTAssertEqual(data.length, data.length)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationDownload = nil
            }
        }
        
        XCTAssertNotNil(file.expiresAt)
        
        if let expiresAt = file.expiresAt {
            XCTAssertGreaterThan(expiresAt.timeIntervalSinceDate(beforeDate), ttl.1.toTimeInterval(ttl.0))
            
            let twentySecs = TTL(20, .Second)
            XCTAssertLessThan(expiresAt.timeIntervalSinceDate(beforeDate), twentySecs.1.toTimeInterval(twentySecs.0))
        }
    }
    
}
