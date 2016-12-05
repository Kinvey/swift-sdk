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
            if useMockData {
                mockResponse(json: ["count" : 1])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationRemove = expectation(description: "Remove")
            
            fileStore.remove(file) { (count, error) in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                if let count = count {
                    XCTAssertEqual(count, 1)
                }
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRemove = nil
            }
        }
        
        super.tearDown()
    }
    
    fileprivate func reportMemory() -> Int64? {
        var info = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(TASK_BASIC_INFO),
                          $0,
                          &count)
            }
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
        let path = Bundle(for: type(of: self)).path(forResource: "Caminandes 3 - TRAILER", ofType: "mp4")!
        
        var uploadProgressCount = 0
        
        do {
            if useMockData {
                var count = 0
                mockResponse { request in
                    defer {
                        count += 1
                    }
                    switch count {
                    case 0:
                        return HttpResponse(statusCode: 201, json: [
                            "_public": true,
                            "_id": "2a37d253-752f-42cd-987e-db319a626077",
                            "_filename": "a2f88ffc-e7fe-4d17-aa69-063088cb24fa",
                            "_acl": [
                                "creator": "584287c3b1c6f88d1990e1e8"
                            ],
                            "_kmd": [
                                "lmt": "2016-12-03T08:52:19.204Z",
                                "ect": "2016-12-03T08:52:19.204Z"
                            ],
                            "_uploadURL": "https://www.googleapis.com/upload/storage/v1/b/0b5b1cd673164e3185a2e75e815f5cfe/o?name=2a37d253-752f-42cd-987e-db319a626077%2Fa2f88ffc-e7fe-4d17-aa69-063088cb24fa&uploadType=resumable&predefinedAcl=publicRead&upload_id=AEnB2Uqwlm2GQ0JWMApi0ApeBHQ0PxjY3hSe_VNs5geuZFxLBkrwiI0gLldrE8GgkqX4ahWtRJ1MHombFq8hQc9o5772htAvDQ",
                            "_expiresAt": "2016-12-10T08:52:19.488Z",
                            "_requiredHeaders": [
                            ]
                        ])
                    case 1:
                        if let stream = request.httpBodyStream {
                            stream.open()
                            defer {
                                stream.close()
                            }
                            let chunkSize = 4096
                            var buffer = [UInt8](repeating: 0, count: chunkSize)
                            var data = Data()
                            while stream.hasBytesAvailable {
                                let read = stream.read(&buffer, maxLength: chunkSize)
                                data.append(buffer, count: read)
                                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.0001))
                            }
                            RunLoop.current.run(until: Date(timeIntervalSinceNow: 3))
                        }
                        return HttpResponse(json: [
                            "kind": "storage#object",
                            "id": "0b5b1cd673164e3185a2e75e815f5cfe/2a37d253-752f-42cd-987e-db319a626077/a2f88ffc-e7fe-4d17-aa69-063088cb24fa/1480755141849000",
                            "selfLink": "https://www.googleapis.com/storage/v1/b/0b5b1cd673164e3185a2e75e815f5cfe/o/2a37d253-752f-42cd-987e-db319a626077%2Fa2f88ffc-e7fe-4d17-aa69-063088cb24fa",
                            "name": "2a37d253-752f-42cd-987e-db319a626077/a2f88ffc-e7fe-4d17-aa69-063088cb24fa",
                            "bucket": "0b5b1cd673164e3185a2e75e815f5cfe",
                            "generation": "1480755141849000",
                            "metageneration": "1",
                            "contentType": "application/octet-stream",
                            "timeCreated": "2016-12-03T08:52:21.841Z",
                            "updated": "2016-12-03T08:52:21.841Z",
                            "storageClass": "STANDARD",
                            "timeStorageClassUpdated": "2016-12-03T08:52:21.841Z",
                            "size": "10899706",
                            "md5Hash": "HBplIh4F9FaBs7owRk25KA==",
                            "mediaLink": "https://www.googleapis.com/download/storage/v1/b/0b5b1cd673164e3185a2e75e815f5cfe/o/2a37d253-752f-42cd-987e-db319a626077%2Fa2f88ffc-e7fe-4d17-aa69-063088cb24fa?generation=1480755141849000&alt=media",
                            "cacheControl": "private, max-age=0, no-transform",
                            "acl": [
                                [
                                    "kind": "storage#objectAccessControl",
                                    "id": "0b5b1cd673164e3185a2e75e815f5cfe/2a37d253-752f-42cd-987e-db319a626077/a2f88ffc-e7fe-4d17-aa69-063088cb24fa/1480755141849000/user-00b4903a97d32a07d52ec70a8d0394967758e899886e3a64b82d01f2900a448f",
                                    "selfLink": "https://www.googleapis.com/storage/v1/b/0b5b1cd673164e3185a2e75e815f5cfe/o/2a37d253-752f-42cd-987e-db319a626077%2Fa2f88ffc-e7fe-4d17-aa69-063088cb24fa/acl/user-00b4903a97d32a07d52ec70a8d0394967758e899886e3a64b82d01f2900a448f",
                                    "bucket": "0b5b1cd673164e3185a2e75e815f5cfe",
                                    "object": "2a37d253-752f-42cd-987e-db319a626077/a2f88ffc-e7fe-4d17-aa69-063088cb24fa",
                                    "generation": "1480755141849000",
                                    "entity": "user-00b4903a97d32a07d52ec70a8d0394967758e899886e3a64b82d01f2900a448f",
                                    "role": "OWNER",
                                    "entityId": "00b4903a97d32a07d52ec70a8d0394967758e899886e3a64b82d01f2900a448f",
                                    "etag": "CKjf6uHS19ACEAE="
                                ],
                                [
                                    "kind": "storage#objectAccessControl",
                                    "id": "0b5b1cd673164e3185a2e75e815f5cfe/2a37d253-752f-42cd-987e-db319a626077/a2f88ffc-e7fe-4d17-aa69-063088cb24fa/1480755141849000/allUsers",
                                    "selfLink": "https://www.googleapis.com/storage/v1/b/0b5b1cd673164e3185a2e75e815f5cfe/o/2a37d253-752f-42cd-987e-db319a626077%2Fa2f88ffc-e7fe-4d17-aa69-063088cb24fa/acl/allUsers",
                                    "bucket": "0b5b1cd673164e3185a2e75e815f5cfe",
                                    "object": "2a37d253-752f-42cd-987e-db319a626077/a2f88ffc-e7fe-4d17-aa69-063088cb24fa",
                                    "generation": "1480755141849000",
                                    "entity": "allUsers",
                                    "role": "READER",
                                    "etag": "CKjf6uHS19ACEAE="
                                ]
                            ],
                            "owner": [
                                "entity": "user-00b4903a97d32a07d52ec70a8d0394967758e899886e3a64b82d01f2900a448f",
                                "entityId": "00b4903a97d32a07d52ec70a8d0394967758e899886e3a64b82d01f2900a448f"
                            ],
                            "crc32c": "19icMQ==",
                            "etag": "CKjf6uHS19ACEAE="
                        ])
                    case 2:
                        return HttpResponse(json: [
                            "_id": "2a37d253-752f-42cd-987e-db319a626077",
                            "_public": true,
                            "_filename": "a2f88ffc-e7fe-4d17-aa69-063088cb24fa",
                            "_acl": [
                                "creator": "584287c3b1c6f88d1990e1e8"
                            ],
                            "_kmd": [
                                "lmt": "2016-12-03T08:52:19.204Z",
                                "ect": "2016-12-03T08:52:19.204Z"
                            ],
                            "_downloadURL": "https://storage.googleapis.com/0b5b1cd673164e3185a2e75e815f5cfe/2a37d253-752f-42cd-987e-db319a626077/a2f88ffc-e7fe-4d17-aa69-063088cb24fa"
                        ])
                    default:
                        preconditionFailure()
                    }
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationUpload = expectation(description: "Upload")
            
            let memoryBefore = reportMemory()
            XCTAssertNotNil(memoryBefore)
            
            let request = fileStore.upload(file, path: path) { (file, error) in
                XCTAssertTrue(Thread.isMainThread)
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
            
            var uploadProgressSent: Int64? = nil
            var uploadProgressTotal: Int64? = nil
            request.progress = {
                XCTAssertTrue(Thread.isMainThread)
                if $0.countOfBytesSent == $0.countOfBytesExpectedToSend {
                    //upload finished
                } else {
                    if uploadProgressCount == 0 {
                        uploadProgressSent = $0.countOfBytesSent
                        uploadProgressTotal = $0.countOfBytesExpectedToSend
                    } else {
                        XCTAssertEqual(uploadProgressTotal, $0.countOfBytesExpectedToSend)
                        XCTAssertGreaterThan($0.countOfBytesSent, uploadProgressSent!)
                        uploadProgressSent = $0.countOfBytesSent
                    }
                    uploadProgressCount += 1
                    print("Upload: \($0.countOfBytesSent)/\($0.countOfBytesExpectedToSend)")
                }
            }
            
            let memoryNow = reportMemory()
            XCTAssertNotNil(memoryNow)
            if let memoryBefore = memoryBefore, let memoryNow = memoryNow {
                let diff = memoryNow - memoryBefore
                XCTAssertLessThan(diff, 10899706)
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        if !useMockData {
            XCTAssertGreaterThan(uploadProgressCount, 0)
        }
        
        XCTAssertNotNil(file.fileId)
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            let request = fileStore.download(file) { (file, data: Data?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                
                if let data = data {
                    XCTAssertEqual(data.count, 10899706)
                }
                
                expectationDownload?.fulfill()
            }
            
            var downloadProgressCount = 0
            var downloadProgressSent: Int64? = nil
            var downloadProgressTotal: Int64? = nil
            request.progress = {
                XCTAssertTrue(Thread.isMainThread)
                if downloadProgressCount == 0 {
                    downloadProgressSent = $0.countOfBytesReceived
                    downloadProgressTotal = $0.countOfBytesExpectedToReceive
                } else {
                    XCTAssertEqual(downloadProgressTotal, $0.countOfBytesExpectedToReceive)
                    XCTAssertGreaterThan($0.countOfBytesReceived, downloadProgressSent!)
                    downloadProgressSent = $0.countOfBytesReceived
                }
                downloadProgressCount += 1
                print("Download: \($0.countOfBytesReceived)/\($0.countOfBytesExpectedToReceive)")
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
            
            XCTAssertGreaterThan(downloadProgressCount, 0)
        }
    }
    
    func testUploadAndResume() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        let file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let path = Bundle(for: type(of: self)).path(forResource: "Caminandes 3 - TRAILER", ofType: "mp4")!
        
        do {
            weak var expectationUpload = expectation(description: "Upload")
            
            let request = fileStore.upload(file, path: path) { (file, error) in
                XCTFail()
            }
            
            let delayTime = DispatchTime.now() + Double(Int64(3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                request.cancel()
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        XCTAssertNotNil(file.fileId)
        
        do {
            weak var expectationWait = expectation(description: "Wait")
            
            let delayTime = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                expectationWait?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationWait = nil
            }
        }
        
        do {
            weak var expectationUpload = expectation(description: "Upload")
            
            fileStore.upload(file, path: path) { (file, error) in
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, data: Data?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                
                if let data = data {
                    XCTAssertEqual(data.count, 10899706)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
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
        let path = Bundle(for: type(of: self)).path(forResource: "Caminandes 3 - TRAILER", ofType: "mp4")!
        
        do {
            if useMockData {
                var count = 0
                mockResponse { request in
                    defer {
                        count += 1
                    }
                    switch count {
                    case 0:
                        return HttpResponse(statusCode: 201, json: [
                            "_id": UUID().uuidString,
                            "_public": true,
                            "_filename": UUID().uuidString,
                            "_acl": [
                                "creator": self.client.activeUser?.userId
                            ],
                            "_kmd": [
                                "lmt": Date().toString(),
                                "ect": Date().toString()
                            ],
                            "_uploadURL": "https://www.googleapis.com/upload/storage/v1/b/\(UUID().uuidString)/o?name=\(UUID().uuidString)%2F\(UUID().uuidString)&uploadType=resumable&predefinedAcl=publicRead&upload_id=\(UUID().uuidString)",
                            "_expiresAt": Date().toString(),
                            "_requiredHeaders": [
                            ]
                        ])
                    case 1:
                        return HttpResponse(json: [
                            "kind": "storage#object",
                            "id": "0b5b1cd673164e3185a2e75e815f5cfe/b9cd292d-0f61-480f-854d-9a0d56f86db7/ac5cc5c2-34ef-4aea-94e8-d755acbd08b3/1480734303179000",
                            "selfLink": "https://www.googleapis.com/storage/v1/b/0b5b1cd673164e3185a2e75e815f5cfe/o/b9cd292d-0f61-480f-854d-9a0d56f86db7%2Fac5cc5c2-34ef-4aea-94e8-d755acbd08b3",
                            "name": "b9cd292d-0f61-480f-854d-9a0d56f86db7/ac5cc5c2-34ef-4aea-94e8-d755acbd08b3",
                            "bucket": "0b5b1cd673164e3185a2e75e815f5cfe",
                            "generation": "1480734303179000",
                            "metageneration": "1",
                            "contentType": "application/octet-stream",
                            "timeCreated": "2016-12-03T03:05:03.168Z",
                            "updated": "2016-12-03T03:05:03.168Z",
                            "storageClass": "STANDARD",
                            "timeStorageClassUpdated": "2016-12-03T03:05:03.168Z",
                            "size": "10899706",
                            "md5Hash": "HBplIh4F9FaBs7owRk25KA==",
                            "mediaLink": "https://www.googleapis.com/download/storage/v1/b/0b5b1cd673164e3185a2e75e815f5cfe/o/b9cd292d-0f61-480f-854d-9a0d56f86db7%2Fac5cc5c2-34ef-4aea-94e8-d755acbd08b3?generation=1480734303179000&alt=media",
                            "cacheControl": "private, max-age=0, no-transform",
                            "acl": [
                                [
                                    "kind": "storage#objectAccessControl",
                                    "id": "0b5b1cd673164e3185a2e75e815f5cfe/b9cd292d-0f61-480f-854d-9a0d56f86db7/ac5cc5c2-34ef-4aea-94e8-d755acbd08b3/1480734303179000/user-00b4903a97d32a07d52ec70a8d0394967758e899886e3a64b82d01f2900a448f",
                                    "selfLink": "https://www.googleapis.com/storage/v1/b/0b5b1cd673164e3185a2e75e815f5cfe/o/b9cd292d-0f61-480f-854d-9a0d56f86db7%2Fac5cc5c2-34ef-4aea-94e8-d755acbd08b3/acl/user-00b4903a97d32a07d52ec70a8d0394967758e899886e3a64b82d01f2900a448f",
                                    "bucket": "0b5b1cd673164e3185a2e75e815f5cfe",
                                    "object": "b9cd292d-0f61-480f-854d-9a0d56f86db7/ac5cc5c2-34ef-4aea-94e8-d755acbd08b3",
                                    "generation": "1480734303179000",
                                    "entity": "user-00b4903a97d32a07d52ec70a8d0394967758e899886e3a64b82d01f2900a448f",
                                    "role": "OWNER",
                                    "entityId": "00b4903a97d32a07d52ec70a8d0394967758e899886e3a64b82d01f2900a448f",
                                    "etag": "CPihl5GF19ACEAE="
                                ],
                                [
                                    "kind": "storage#objectAccessControl",
                                    "id": "0b5b1cd673164e3185a2e75e815f5cfe/b9cd292d-0f61-480f-854d-9a0d56f86db7/ac5cc5c2-34ef-4aea-94e8-d755acbd08b3/1480734303179000/allUsers",
                                    "selfLink": "https://www.googleapis.com/storage/v1/b/0b5b1cd673164e3185a2e75e815f5cfe/o/b9cd292d-0f61-480f-854d-9a0d56f86db7%2Fac5cc5c2-34ef-4aea-94e8-d755acbd08b3/acl/allUsers",
                                    "bucket": "0b5b1cd673164e3185a2e75e815f5cfe",
                                    "object": "b9cd292d-0f61-480f-854d-9a0d56f86db7/ac5cc5c2-34ef-4aea-94e8-d755acbd08b3",
                                    "generation": "1480734303179000",
                                    "entity": "allUsers",
                                    "role": "READER",
                                    "etag": "CPihl5GF19ACEAE="
                                ]
                            ],
                            "owner": [
                                "entity": "user-00b4903a97d32a07d52ec70a8d0394967758e899886e3a64b82d01f2900a448f",
                                "entityId": "00b4903a97d32a07d52ec70a8d0394967758e899886e3a64b82d01f2900a448f"
                            ],
                            "crc32c": "19icMQ==",
                            "etag": "CPihl5GF19ACEAE="
                        ])
                    case 2:
                        return HttpResponse(json: [
                            "_id": UUID().uuidString,
                            "_public": true,
                            "_filename": UUID().uuidString,
                            "_acl": [
                                "creator": self.client.activeUser?.userId
                            ],
                            "_kmd": [
                                "lmt": Date().toString(),
                                "ect": Date().toString()
                            ],
                            "_downloadURL": "https://storage.googleapis.com/\(UUID().uuidString)/\(UUID().uuidString)/\(UUID().uuidString)"
                        ])
                    default:
                        preconditionFailure()
                    }
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationUpload = expectation(description: "Upload")
            
            fileStore.upload(file, path: path) { (file, error) in
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        XCTAssertNotNil(file.fileId)
        
        if useMockData {
            let url = Bundle(for: FileTestCase.self).url(forResource: "Caminandes 3 - TRAILER", withExtension: "mp4")
            let data = try! Data(contentsOf: url!)
            let chunkSize = data.count / 10
            var offset = 0
            var chunks = [ChunkData]()
            while offset < data.count {
                let data = Data(data[offset ..< offset + min(chunkSize, data.count - offset)])
                let chunk = ChunkData(data: data, delay: 0.5)
                chunks.append(chunk)
                offset += chunkSize
            }
            XCTAssertEqual(data.count, chunks.reduce(0, { $0 + $1.data.count }))
            mockResponse(headerFields: [
                "Last-Modified": "Sat, 03 Dec 2016 08:19:26 GMT",
                "ETag": "\"1c1a65221e05f45681b3ba30464db928\"",
                "Accept-Ranges": "bytes"
            ], chunks: chunks)
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            let request = fileStore.download(file) { (file, data: Data?, error) in
                XCTFail()
            }
            
            let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                request.cancel()
                expectationDownload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
        }
        
        XCTAssertNotNil(file.resumeDownloadData)
        if let resumeData = file.resumeDownloadData {
            XCTAssertGreaterThan(resumeData.count, 0)
        }
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, data: Data?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                
                if let data = data {
                    XCTAssertEqual(data.count, 10899706)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
        }
    }
    
    func testUploadDataDownloadPath() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        let file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let data = "Hello".data(using: String.Encoding.utf8)!
        
        do {
            weak var expectationUpload = expectation(description: "Upload")
            
            fileStore.upload(file, data: data) { (file, error) in
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        XCTAssertNotNil(file.fileId)
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, url: URL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNil(error)
                
                if let url = url, let _data = try? Data(contentsOf: url) {
                    XCTAssertEqual(data.count, _data.count)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
        }
        
        do {
            weak var expectationCached = expectation(description: "Cached")
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, url: URL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNotNil(url?.path)
                XCTAssertNil(error)
                
                if let url = url {
                    XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
                    
                    if let dataTmp = try? Data(contentsOf: url) {
                        XCTAssertEqual(dataTmp.count, data.count)
                    } else {
                        XCTFail()
                    }
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
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCached = nil
                expectationDownload = nil
            }
        }
        
        let data2 = "Hello World".data(using: String.Encoding.utf8)!
        
        do {
            weak var expectationUpload = expectation(description: "Upload")
            
            fileStore.upload(file, data: data2) { (file, error) in
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        do {
            weak var expectationCached = expectation(description: "Cached")
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, url: URL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNotNil(url?.path)
                XCTAssertNil(error)
                
                if let _ = expectationCached {
                    if let url = url,
                        let dataTmp = try? Data(contentsOf: url)
                    {
                        XCTAssertEqual(dataTmp.count, data.count)
                    } else {
                        XCTFail()
                    }
                    
                    expectationCached?.fulfill()
                    expectationCached = nil
                } else {
                    if let url = url,
                        let dataTmp = try? Data(contentsOf: url)
                    {
                        XCTAssertEqual(dataTmp.count, data2.count)
                    } else {
                        XCTFail()
                    }
                    
                    expectationDownload?.fulfill()
                }
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCached = nil
                expectationDownload = nil
            }
        }
    }
    
    func testUploadPathDownloadPath() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        let file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let data = "Hello".data(using: String.Encoding.utf8)!
        
        let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("upload")
        do {
            try data.write(to: path, options: [.atomic])
        } catch {
            XCTFail()
        }
        
        do {
            weak var expectationUpload = expectation(description: "Upload")
            
            fileStore.upload(file, path: path.path) { (file, error) in
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        XCTAssertNotNil(file.fileId)
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, url: URL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNil(error)
                
                if let url = url, let _data = try? Data(contentsOf: url) {
                    XCTAssertEqual(data.count, _data.count)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
        }
        
        do {
            weak var expectationCached = expectation(description: "Cached")
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, url: URL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNotNil(url?.path)
                XCTAssertNil(error)
                
                if let url = url,
                    let dataTmp = try? Data(contentsOf: url)
                {
                    XCTAssertEqual(dataTmp.count, data.count)
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
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCached = nil
                expectationDownload = nil
            }
        }
        
        let data2 = "Hello World".data(using: String.Encoding.utf8)!
        do {
            try data2.write(to: path, options: [.atomic])
        } catch {
            XCTFail()
        }
        
        do {
            weak var expectationUpload = expectation(description: "Upload")
            
            fileStore.upload(file, path: path.path) { (file, error) in
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        do {
            weak var expectationCached = expectation(description: "Cached")
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, url: URL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNotNil(url?.path)
                XCTAssertNil(error)
                
                if let _ = expectationCached {
                    if let url = url,
                        let dataTmp = try? Data(contentsOf: url)
                    {
                        XCTAssertEqual(dataTmp.count, data.count)
                    } else {
                        XCTFail()
                    }
                    
                    expectationCached?.fulfill()
                    expectationCached = nil
                } else {
                    if let url = url,
                        let dataTmp = try? Data(contentsOf: url)
                    {
                        XCTAssertEqual(dataTmp.count, data2.count)
                    } else {
                        XCTFail()
                    }
                    
                    expectationDownload?.fulfill()
                }
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCached = nil
                expectationDownload = nil
            }
        }
    }
    
    func testUploadTTLExpired() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        let file = File() {
            $0.publicAccessible = false
        }
        self.file = file
        let data = "Hello".data(using: String.Encoding.utf8)!
        
        let beforeDate = Date()
        let ttl = TTL(10, .second)
        
        do {
            weak var expectationUpload = expectation(description: "Upload")
            
            fileStore.upload(file, data: data, ttl: ttl) { (file, error) in
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        XCTAssertNotNil(file.fileId)
        XCTAssertNotNil(file.expiresAt)
        
        if let expiresAt = file.expiresAt {
            XCTAssertGreaterThan(expiresAt.timeIntervalSince(beforeDate), ttl.1.toTimeInterval(ttl.0))
            
            let twentySecs = TTL(20, .second)
            XCTAssertLessThan(expiresAt.timeIntervalSince(beforeDate), twentySecs.1.toTimeInterval(twentySecs.0))
        }
    }
    
    func testDownloadTTLExpired() {
        signUp()
        
        let file = File() {
            $0.publicAccessible = false
        }
        self.file = file
        let data = "Hello".data(using: String.Encoding.utf8)!
        
        let ttl = TTL(10, .second)
        
        do {
            if useMockData {
                var count = 0
                mockResponse { request in
                    defer {
                        count += 1
                    }
                    switch count {
                    case 0:
                        return HttpResponse(statusCode: 201, json: [
                            "_id": UUID().uuidString,
                            "_public": true,
                            "_filename": UUID().uuidString,
                            "_acl": [
                                "creator": self.client.activeUser?.userId
                            ],
                            "_kmd": [
                                "lmt": Date().toString(),
                                "ect": Date().toString()
                            ],
                            "_uploadURL": "https://www.googleapis.com/upload/storage/v1/b/\(UUID().uuidString)/o?name=\(UUID().uuidString)%2F\(UUID().uuidString)&uploadType=resumable&predefinedAcl=publicRead&upload_id=\(UUID().uuidString)",
                            "_expiresAt": Date().toString(),
                            "_requiredHeaders": [
                            ]
                        ])
                    case 1:
                        return HttpResponse(json: [
                            "kind": "storage#object",
                            "id": "0b5b1cd673164e3185a2e75e815f5cfe/79d48489-d197-48c8-98e6-b5b4028858a1/4b27cacf-33d2-4c90-b790-271000631895/1480753865735000",
                            "selfLink": "https://www.googleapis.com/storage/v1/b/0b5b1cd673164e3185a2e75e815f5cfe/o/79d48489-d197-48c8-98e6-b5b4028858a1%2F4b27cacf-33d2-4c90-b790-271000631895",
                            "name": "79d48489-d197-48c8-98e6-b5b4028858a1/4b27cacf-33d2-4c90-b790-271000631895",
                            "bucket": "0b5b1cd673164e3185a2e75e815f5cfe",
                            "generation": "1480753865735000",
                            "metageneration": "1",
                            "contentType": "application/octet-stream",
                            "timeCreated": "2016-12-03T08:31:05.727Z",
                            "updated": "2016-12-03T08:31:05.727Z",
                            "storageClass": "STANDARD",
                            "timeStorageClassUpdated": "2016-12-03T08:31:05.727Z",
                            "size": "5",
                            "md5Hash": "ixqZU8RhEpaoJ6v4xHgE1w==",
                            "mediaLink": "https://www.googleapis.com/download/storage/v1/b/0b5b1cd673164e3185a2e75e815f5cfe/o/79d48489-d197-48c8-98e6-b5b4028858a1%2F4b27cacf-33d2-4c90-b790-271000631895?generation=1480753865735000&alt=media",
                            "crc32c": "gdkOGw==",
                            "etag": "CNj2qoHO19ACEAE="
                        ])
                    case 2:
                        return HttpResponse(json: [
                            "_id": UUID().uuidString,
                            "_public": false,
                            "_filename": UUID().uuidString,
                            "_acl": [
                                "creator": self.client.activeUser?.userId
                            ],
                            "_kmd": [
                                "lmt": Date().toString(),
                                "ect": Date().toString()
                            ],
                            "_downloadURL": "https://storage.googleapis.com/0b5b1cd673164e3185a2e75e815f5cfe/79d48489-d197-48c8-98e6-b5b4028858a1/4b27cacf-33d2-4c90-b790-271000631895?GoogleAccessId=558440376631@developer.gserviceaccount.com&Expires=1480757466&Signature=djWo6FIonq3gdON80i26xfBnOiGobxxbIVEY5wjVbcBnHpXoUbwDhdK5oPZVkTYkqpABj%2FFNDZpeVDG0UCUL8eS4ujD3%2FwPeHdX2z9cnmNXDLvi%2FPoMQHZg6XatKCQvY6swht6Ybptj5%2Ftx8euHnGLf4l4eTRcwBsDv2mAVz6MU%3D",
                            "_expiresAt": Date(timeIntervalSinceNow: 3600).toString()
                        ])
                    default:
                        preconditionFailure()
                    }
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationUpload = expectation(description: "Upload")
            
            fileStore.upload(file, data: data) { (file, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        XCTAssertNotNil(file.fileId)
        
        file.download = nil
        file.expiresAt = nil
        
        let beforeDate = Date()
        
        do {
            if useMockData {
                var count = 0
                mockResponse { request in
                    defer {
                        count += 1
                    }
                    switch count {
                    case 0:
                        return HttpResponse(json: [
                            "_id": UUID().uuidString,
                            "_public": false,
                            "_filename": UUID().uuidString,
                            "_acl": [
                                "creator": self.client.activeUser?.userId
                            ],
                            "_kmd": [
                                "lmt": Date().toString(),
                                "ect": Date().toString()
                            ],
                            "_downloadURL": "https://storage.googleapis.com/\(UUID().uuidString)/\(UUID().uuidString)/\(UUID().uuidString)?GoogleAccessId=\(UUID().uuidString)@developer.gserviceaccount.com&Expires=\(UUID().uuidString)&Signature=\(UUID().uuidString)%2F\(UUID().uuidString)%2B\(UUID().uuidString)%2B\(UUID().uuidString)%3D",
                            "_expiresAt": Date(timeIntervalSinceNow: ttl.1.toTimeInterval(ttl.0)).toString()
                        ])
                    case 1:
                        return HttpResponse(data: data)
                    default:
                        preconditionFailure()
                    }
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file, ttl: ttl) { (file, url: URL?, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNil(error)
                
                if let url = url, let _data = try? Data(contentsOf: url) {
                    XCTAssertEqual(data.count, _data.count)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
        }
        
        XCTAssertNotNil(file.expiresAt)
        
        if let expiresAt = file.expiresAt {
            XCTAssertGreaterThan(expiresAt.timeIntervalSince(beforeDate), ttl.1.toTimeInterval(ttl.0 - 1))
            
            let twentySecs = TTL(20, .second)
            XCTAssertLessThan(expiresAt.timeIntervalSince(beforeDate), twentySecs.1.toTimeInterval(twentySecs.0))
        }
    }
    
}
