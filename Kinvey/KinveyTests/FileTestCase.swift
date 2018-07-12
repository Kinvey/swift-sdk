//
//  FileTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-05-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey
import Nimble

#if os(macOS)
    typealias Image = NSImage
#else
    typealias Image = UIImage
#endif

class FileTestCase: StoreTestCase {
    
    let caminandes3TrailerURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Caminandes 3 - TRAILER.mp4")
    let caminandes3TrailerImageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Caminandes 3 - TRAILER.jpg")
    var file: File?
    var myFile: MyFile?
    var caminandes3TrailerFileSize: UInt64 {
        return try! FileManager.default.attributesOfItem(atPath: caminandes3TrailerURL.path).filter { $0.key == .size }.first!.value as! UInt64
    }
    
    lazy var fileStore: FileStore = {
        return FileStore()
    }()
    
    override func setUp() {
        super.setUp()
        
        var count = 0
        
        while count < 10, !FileManager.default.fileExists(atPath: caminandes3TrailerURL.path) || !FileManager.default.fileExists(atPath: caminandes3TrailerImageURL.path) {
            count += 1
            let downloadGroup = DispatchGroup()
            
            if !FileManager.default.fileExists(atPath: self.caminandes3TrailerURL.path) {
                let url = URL(string: "https://download.kinvey.com/iOS/travisci-cache/Caminandes+3+-+TRAILER.mp4")!
                downloadGroup.enter()
                let downloadTask = URLSession.shared.downloadTask(with: url) { url, response, error in
                    if let url = url,
                        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                        let fileSize = attrs[.size] as? UInt64,
                        fileSize > 0
                    {
                        try! FileManager.default.moveItem(at: url, to: self.caminandes3TrailerURL)
                    }
                    
                    downloadGroup.leave()
                }
                downloadTask.resume()
            }
            
            if !FileManager.default.fileExists(atPath: self.caminandes3TrailerImageURL.path) {
                let url = URL(string: "https://download.kinvey.com/iOS/travisci-cache/Caminandes+3+-+TRAILER.jpg")!
                downloadGroup.enter()
                let downloadTask = URLSession.shared.downloadTask(with: url) { url, response, error in
                    if let url = url,
                        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                        let fileSize = attrs[.size] as? UInt64,
                        fileSize > 0
                    {
                        try! FileManager.default.moveItem(at: url, to: self.caminandes3TrailerImageURL)
                    }
                    
                    downloadGroup.leave()
                }
                downloadTask.resume()
            }
            
            downloadGroup.wait()
        }
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: caminandes3TrailerURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: caminandes3TrailerImageURL.path))
    }
    
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
    
    func testDownloadMissingFileId() {
        signUp()
        
        weak var expectationDownload = expectation(description: "Download")
        
        self.fileStore.download(File()) { (file, data: Data?, error) in
            XCTAssertNil(file)
            XCTAssertNil(data)
            XCTAssertNotNil(error)
            if let error = error as? Kinvey.Error {
                switch error {
                case .invalidOperation(let description):
                    XCTAssertEqual(description, "fileId is required")
                default:
                    XCTFail(error.localizedDescription)
                }
            }
            
            expectationDownload?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationDownload = nil
        }
    }
    
    func testDownloadTimeoutError() {
        signUp()
        
        var file = File() {
            $0.fileId = UUID().uuidString
        }
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationDownload = expectation(description: "Download")
        
        fileStore.download(file) { (file, data: Data?, error) in
            XCTAssertTrue(Thread.isMainThread)
            
            XCTAssertNil(file)
            XCTAssertNil(data)
            XCTAssertNotNil(error)
            XCTAssertTimeoutError(error)
            
            expectationDownload?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationDownload = nil
        }
    }
    
    func testDownload404Error() {
        signUp()
        
        var file = File() {
            $0.fileId = UUID().uuidString
        }
        
        mockResponse(statusCode: 404, data: [])
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationDownload = expectation(description: "Download")
        
        fileStore.download(file) { (file, data: Data?, error) in
            XCTAssertTrue(Thread.isMainThread)
            
            XCTAssertNil(file)
            XCTAssertNil(data)
            XCTAssertNotNil(error)
            
            expectationDownload?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationDownload = nil
        }
    }
    
    func testDownloadDataTimeoutError() {
        signUp()
        
        var file = File() {
            $0.fileId = UUID().uuidString
        }
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationDownload = expectation(description: "Download")
        
        fileStore.download(file) { (file, data: Data?, error) in
            XCTAssertTrue(Thread.isMainThread)
            
            XCTAssertNil(file)
            XCTAssertNil(data)
            XCTAssertNotNil(error)
            XCTAssertTimeoutError(error)
            
            expectationDownload?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationDownload = nil
        }
    }
    
    func testDownloadPathTimeoutError() {
        signUp()
        
        var file = File() {
            $0.fileId = UUID().uuidString
        }
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationDownload = expectation(description: "Download")
        
        let request = fileStore.download(file) { (file, url: URL?, error) in
            XCTAssertTrue(Thread.isMainThread)
            
            XCTAssertNil(file)
            XCTAssertNil(url)
            XCTAssertNotNil(error)
            XCTAssertTimeoutError(error)
            
            expectationDownload?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationDownload = nil
        }
        
        XCTAssertNotNil(request.result)
        if let result = request.result {
            do {
                let _ = try result.value()
                XCTFail()
            } catch {
                XCTAssertTimeoutError(error)
            }
        }
    }
    
    func testUploadFileMetadataTimeoutError() {
        signUp()
        
        var file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let path = caminandes3TrailerURL.path
        
        var count = 0
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationUpload = expectation(description: "Upload")
        
        fileStore.upload(file, path: path) { (file, error) in
            XCTAssertTrue(Thread.isMainThread)
            
            XCTAssertNil(file)
            XCTAssertNotNil(error)
            XCTAssertTimeoutError(error)
            
            expectationUpload?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationUpload = nil
        }
    }
    
    func testUploadTimeoutError() {
        signUp()
        
        var file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let path = caminandes3TrailerURL.path
        
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
                return HttpResponse(error: timeoutError)
            default:
                Swift.fatalError()
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationUpload = expectation(description: "Upload")
        
        fileStore.upload(file, path: path) { (file, error) in
            XCTAssertTrue(Thread.isMainThread)
            
            XCTAssertNil(file)
            XCTAssertNotNil(error)
            XCTAssertTimeoutError(error)
            
            expectationUpload?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationUpload = nil
        }
    }
    
    func testUploadDataTimeoutError() {
        signUp()
        
        var file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let path = caminandes3TrailerURL.path
        
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
                return HttpResponse(error: timeoutError)
            default:
                Swift.fatalError()
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        
        weak var expectationUpload = expectation(description: "Upload")
        
        fileStore.upload(file, data: data) { (file, error) in
            XCTAssertTrue(Thread.isMainThread)
            
            XCTAssertNil(file)
            XCTAssertNotNil(error)
            XCTAssertTimeoutError(error)
            
            expectationUpload?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationUpload = nil
        }
    }
    
    func testUploadData404Error() {
        signUp()
        
        var file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let path = caminandes3TrailerURL.path
        
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
                return HttpResponse(statusCode: 404, data: nil)
            default:
                Swift.fatalError()
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        
        weak var expectationUpload = expectation(description: "Upload")
        
        fileStore.upload(file, data: data) { (file, error) in
            XCTAssertTrue(Thread.isMainThread)
            
            XCTAssertNil(file)
            XCTAssertNotNil(error)
            
            expectationUpload?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationUpload = nil
        }
    }
    
    func testUploadImageTimeoutError() {
        signUp()
        
        var file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let path = caminandes3TrailerImageURL.path
        
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
                return HttpResponse(error: timeoutError)
            default:
                Swift.fatalError()
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let image = Image(contentsOfFile: path)!
        
        weak var expectationUpload = expectation(description: "Upload")
        
        fileStore.upload(file, image: image) { (file, error) in
            XCTAssertTrue(Thread.isMainThread)
            
            XCTAssertNil(file)
            XCTAssertNotNil(error)
            XCTAssertTimeoutError(error)
            
            expectationUpload?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationUpload = nil
        }
    }
    
    func testUploadInputStreamTimeoutError() {
        signUp()
        
        var file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let path = caminandes3TrailerImageURL.path
        
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
                return HttpResponse(error: timeoutError)
            default:
                Swift.fatalError()
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let inputStream = InputStream(fileAtPath: path)!
        
        weak var expectationUpload = expectation(description: "Upload")
        
        fileStore.upload(file, stream: inputStream) { (file, error) in
            XCTAssertTrue(Thread.isMainThread)
            
            XCTAssertNil(file)
            XCTAssertNotNil(error)
            XCTAssertTimeoutError(error)
            
            expectationUpload?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationUpload = nil
        }
    }
    
    func testUpload() {
        signUp()
        
        let originalLogNetworkEnabled = client.logNetworkEnabled
        client.logNetworkEnabled = true
        defer {
            client.logNetworkEnabled = originalLogNetworkEnabled
        }
        
        var file = MyFile()
        file.label = "trailer"
        file.publicAccessible = true
        self.file = file
        let path = caminandes3TrailerURL.path
        
        let fileStore = FileStore<MyFile>()
        
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
                        let requestBody = try! JSONSerialization.jsonObject(with: request) as! [String : Any]
                        XCTAssertEqual(requestBody["label"] as? String, "trailer")
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
                            "label" : "trailer",
                            "_downloadURL": "https://storage.googleapis.com/0b5b1cd673164e3185a2e75e815f5cfe/aae29e81-1930-43a5-97e9-bae7964d3820/715dcece-2a05-4d88-a771-d6c7c5cac197"
                        ])
                    default:
                        Swift.fatalError()
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
            
            let request = fileStore.upload(file, path: path) { (uploadedFile, error) in
                XCTAssertTrue(Thread.isMainThread)
                
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                file = uploadedFile!
                
                XCTAssertNotNil(file.path)
                XCTAssertNotNil(file.download)
                XCTAssertNotNil(file.downloadURL)
                
                let memoryNow = reportMemory()
                XCTAssertNotNil(memoryNow)
                if let memoryBefore = memoryBefore, let memoryNow = memoryNow {
                    let diff = memoryNow - memoryBefore
                    XCTAssertLessThan(diff, 15 * 1024 * 1024) //15 MB
                }
                
                expectationUpload?.fulfill()
            }
            
            keyValueObservingExpectation(for: request.progress, keyPath: #selector(getter: request.progress.fractionCompleted).description) { (object, info) -> Bool in
                uploadProgressCount += 1
                XCTAssertLessThanOrEqual(request.progress.completedUnitCount, request.progress.totalUnitCount)
                XCTAssertGreaterThanOrEqual(request.progress.fractionCompleted, 0.0)
                XCTAssertLessThanOrEqual(request.progress.fractionCompleted, 1.0)
                let percentage = request.progress.fractionCompleted * 100.0
                print("Upload: \(request.progress.completedUnitCount) / \(request.progress.totalUnitCount) (\(String(format:"%3.2f", percentage))%)")
                return request.progress.fractionCompleted >= 1.0
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
                
                if let file = file {
                    XCTAssertEqual(file.label, "trailer")
                }
                
                if let data = data {
                    XCTAssertEqual(data.count, 8578265)
                }
                
                expectationDownload?.fulfill()
            }
            
            var reportProgress = 0
            
            keyValueObservingExpectation(for: request.progress, keyPath: #selector(getter: request.progress.fractionCompleted).description) { (object, info) -> Bool in
                reportProgress += 1
                XCTAssertLessThanOrEqual(request.progress.completedUnitCount, request.progress.totalUnitCount)
                XCTAssertGreaterThanOrEqual(request.progress.fractionCompleted, 0.0)
                XCTAssertLessThanOrEqual(request.progress.fractionCompleted, 1.0)
                let percentage = request.progress.fractionCompleted * 100.0
                print("\(request.progress.completedUnitCount) / \(request.progress.totalUnitCount) \(String(format:"%3.2f", percentage))%")
                return request.progress.fractionCompleted >= 1.0
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
            
            XCTAssertGreaterThan(reportProgress, 0)
        }
    }
    
    func testUploadStream() {
        signUp()
        
        var file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let path = caminandes3TrailerURL.path
        
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
                            "_downloadURL": "https://storage.googleapis.com/0b5b1cd673164e3185a2e75e815f5cfe/f85b3eb0-fc22-4147-ae51-19bb201edfdf/0cab2b78-3142-4c10-987a-e837d1a9e269"
                        ])
                    default:
                        Swift.fatalError()
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
            
            let inputStream = InputStream(fileAtPath: path)!
            let request = fileStore.upload(file, stream: inputStream) { (uploadedFile, error) in
                XCTAssertTrue(Thread.isMainThread)
                
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                file = uploadedFile!
                
                XCTAssertNil(file.path)
                XCTAssertNotNil(file.download)
                XCTAssertNotNil(file.downloadURL)
                
                let memoryNow = reportMemory()
                XCTAssertNotNil(memoryNow)
                if let memoryBefore = memoryBefore, let memoryNow = memoryNow {
                    let diff = memoryNow - memoryBefore
                    XCTAssertLessThan(diff, 15 * 1024 * 1024) //15 MB
                }
                
                expectationUpload?.fulfill()
            }
            
            keyValueObservingExpectation(for: request.progress, keyPath: "fractionCompleted") { (object, info) -> Bool in
                uploadProgressCount += 1
                XCTAssertLessThanOrEqual(request.progress.completedUnitCount, request.progress.totalUnitCount)
                XCTAssertGreaterThanOrEqual(request.progress.fractionCompleted, 0.0)
                XCTAssertLessThanOrEqual(request.progress.fractionCompleted, 1.0)
                print("Download: \(request.progress.completedUnitCount) / \(request.progress.totalUnitCount) (\(String(format: "%3.2f", request.progress.fractionCompleted * 100))")
                return request.progress.fractionCompleted >= 1.0
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
        
        if let _ = file.fileId {
            weak var expectationDownload = expectation(description: "Download")
            
            let request = fileStore.download(file) { (file, data: Data?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                
                if let data = data {
                    XCTAssertEqual(data.count, 8578265)
                }
                
                expectationDownload?.fulfill()
            }
            
            var reportProgressCount = 0
            
            keyValueObservingExpectation(for: request.progress, keyPath: "fractionCompleted") { (object, info) -> Bool in
                reportProgressCount += 1
                XCTAssertLessThanOrEqual(request.progress.completedUnitCount, request.progress.totalUnitCount)
                XCTAssertGreaterThanOrEqual(request.progress.fractionCompleted, 0.0)
                XCTAssertLessThanOrEqual(request.progress.fractionCompleted, 1.0)
                print("Download: \(request.progress.completedUnitCount) / \(request.progress.totalUnitCount) (\(String(format: "%3.2f", request.progress.fractionCompleted * 100))")
                return request.progress.fractionCompleted >= 1.0
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
            
            XCTAssertGreaterThan(reportProgressCount, 0)
        }
    }
    
    func testUploadImagePNG() {
        signUp()
        
        var file = File() {
            $0.fileName = "videoplayback.png"
            $0.publicAccessible = true
        }
        let path = caminandes3TrailerImageURL.path
        
        var uploadProgressCount = 0
        
        do {
            if useMockData {
                var count = 0
                let fileId = UUID().uuidString
                mockResponse { request in
                    defer {
                        count += 1
                    }
                    switch count {
                    case 0:
                        return HttpResponse(statusCode: 201, json: [
                            "_public": true,
                            "_id": fileId,
                            "_filename": "videoplayback.png",
                            "mimeType" : "image/png",
                            "size" : 1994579,
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
                            "_id": fileId,
                            "_public": true,
                            "_filename": "videoplayback.png",
                            "mimeType" : "image/png",
                            "_acl": [
                                "creator": "584287c3b1c6f88d1990e1e8"
                            ],
                            "_kmd": [
                                "lmt": "2016-12-03T08:52:19.204Z",
                                "ect": "2016-12-03T08:52:19.204Z"
                            ],
                            "_downloadURL": "https://storage.googleapis.com/0b5b1cd673164e3185a2e75e815f5cfe/429fb893-4bb2-4651-b907-a42145c31015/videoplayback.png"
                        ])
                    default:
                        Swift.fatalError()
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
            
            let image = Image(contentsOfFile: path)!
            
            let request = fileStore.upload(file, image: image) { (uploadedFile, error) in
                XCTAssertTrue(Thread.isMainThread)
                
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                file = uploadedFile!
                
                XCTAssertNotNil(file.download)
                XCTAssertNotNil(file.downloadURL)
                XCTAssertEqual(file.mimeType, "image/png")
                
                let memoryNow = reportMemory()
                XCTAssertNotNil(memoryNow)
                if let memoryBefore = memoryBefore, let memoryNow = memoryNow {
                    let diff = memoryNow - memoryBefore
                    XCTAssertLessThan(diff, 15 * 1024 * 1024) //15 MB
                }
                
                expectationUpload?.fulfill()
            }
            
            keyValueObservingExpectation(for: request.progress, keyPath: "fractionCompleted") { (object, info) -> Bool in
                uploadProgressCount += 1
                XCTAssertLessThanOrEqual(request.progress.completedUnitCount, request.progress.totalUnitCount)
                XCTAssertGreaterThanOrEqual(request.progress.fractionCompleted, 0.0)
                XCTAssertLessThanOrEqual(request.progress.fractionCompleted, 1.0)
                print("Download: \(request.progress.completedUnitCount) / \(request.progress.totalUnitCount) (\(String(format: "%3.2f", request.progress.fractionCompleted * 100))")
                return request.progress.fractionCompleted >= 1.0
            }
            
            let memoryNow = reportMemory()
            XCTAssertNotNil(memoryNow)
            if let memoryBefore = memoryBefore, let memoryNow = memoryNow {
                let diff = memoryNow - memoryBefore
                XCTAssertLessThan(diff, 15 * 1024 * 1024) //15 MB
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
            
            XCTAssertNotNil(request.result)
            if let result = request.result {
                let file = try? result.value()
                XCTAssertNotNil(file?.download)
                XCTAssertNotNil(file?.downloadURL)
                XCTAssertEqual(file?.mimeType, "image/png")
            }
        }
        
        if !useMockData {
            XCTAssertGreaterThan(uploadProgressCount, 0)
        }
        
        XCTAssertNotNil(file.fileId)
        self.file = file
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            let request = fileStore.download(file) { (file, data: Data?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                
                if let data = data {
                    XCTAssertEqual(data.count, 1994579)
                }
                
                expectationDownload?.fulfill()
            }
            
            keyValueObservingExpectation(for: request.progress, keyPath: "fractionCompleted") { (object, info) -> Bool in
                uploadProgressCount += 1
                XCTAssertLessThanOrEqual(request.progress.completedUnitCount, request.progress.totalUnitCount)
                XCTAssertGreaterThanOrEqual(request.progress.fractionCompleted, 0.0)
                XCTAssertLessThanOrEqual(request.progress.fractionCompleted, 1.0)
                print("Download: \(request.progress.completedUnitCount) / \(request.progress.totalUnitCount) (\(String(format: "%3.2f", request.progress.fractionCompleted * 100))")
                return request.progress.fractionCompleted >= 1.0
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
            
            XCTAssertGreaterThan(uploadProgressCount, 0)
        }
    }
    
    func testUploadImageJPEG() {
        signUp()
        
        var file = File() {
            $0.fileName = "videoplayback.jpg"
            $0.publicAccessible = true
        }
        let path = caminandes3TrailerImageURL.path
        
        var uploadProgressCount = 0
        
        do {
            if useMockData {
                var count = 0
                let fileId = UUID().uuidString
                mockResponse { request in
                    defer {
                        count += 1
                    }
                    switch count {
                    case 0:
                        return HttpResponse(statusCode: 201, json: [
                            "_public": true,
                            "_id": fileId,
                            "_filename": "videoplayback.jpg",
                            "mimeType" : "image/jpeg",
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
                            "_id": fileId,
                            "_public": true,
                            "_filename": "videoplayback.jpg",
                            "mimeType" : "image/jpeg",
                            "_acl": [
                                "creator": "584287c3b1c6f88d1990e1e8"
                            ],
                            "_kmd": [
                                "lmt": "2016-12-03T08:52:19.204Z",
                                "ect": "2016-12-03T08:52:19.204Z"
                            ],
                            "_downloadURL": "https://storage.googleapis.com/0b5b1cd673164e3185a2e75e815f5cfe/757a357e-341b-4119-8e38-cd7e96edd28b/videoplayback.jpg"
                        ])
                    default:
                        Swift.fatalError()
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
            
            let image = Image(contentsOfFile: path)!
            
            let request = fileStore.upload(file, image: image, imageRepresentation: .jpeg(compressionQuality: 0.8)) { (uploadedFile, error) in
                XCTAssertTrue(Thread.isMainThread)
                
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                file = uploadedFile!
                
                XCTAssertNotNil(file.download)
                XCTAssertNotNil(file.downloadURL)
                XCTAssertEqual(file.mimeType, "image/jpeg")
                
                let memoryNow = reportMemory()
                XCTAssertNotNil(memoryNow)
                if let memoryBefore = memoryBefore, let memoryNow = memoryNow {
                    let diff = memoryNow - memoryBefore
                    XCTAssertLessThan(diff, 15 * 1024 * 1024) //15 MB
                }
                
                expectationUpload?.fulfill()
            }
            
            keyValueObservingExpectation(for: request.progress, keyPath: "fractionCompleted") { (object, info) -> Bool in
                uploadProgressCount += 1
                XCTAssertLessThanOrEqual(request.progress.completedUnitCount, request.progress.totalUnitCount)
                XCTAssertGreaterThanOrEqual(request.progress.fractionCompleted, 0.0)
                XCTAssertLessThanOrEqual(request.progress.fractionCompleted, 1.0)
                print("Upload: \(request.progress.completedUnitCount) / \(request.progress.totalUnitCount) (\(String(format: "%3.2f", request.progress.fractionCompleted * 100))")
                return request.progress.fractionCompleted >= 1.0
            }
            
            let memoryNow = reportMemory()
            XCTAssertNotNil(memoryNow)
            if let memoryBefore = memoryBefore, let memoryNow = memoryNow {
                let diff = memoryNow - memoryBefore
                XCTAssertLessThan(diff, 15 * 1024 * 1024) //15 MB
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
            
            XCTAssertNotNil(request.result)
            if let result = request.result {
                let file = try? result.value()
                XCTAssertNotNil(file?.download)
                XCTAssertNotNil(file?.downloadURL)
                XCTAssertEqual(file?.mimeType, "image/jpeg")
            }
        }
        
        if !useMockData {
            XCTAssertGreaterThan(uploadProgressCount, 0)
        }
        
        XCTAssertNotNil(file.fileId)
        self.file = file
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            let request = fileStore.download(file) { (file, data: Data?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                
                if let data = data {
                    XCTAssertEqual(data.count, 233281)
                }
                
                expectationDownload?.fulfill()
            }
            
            var reportProgressCount = 0
            
            keyValueObservingExpectation(for: request.progress, keyPath: "fractionCompleted") { (object, info) -> Bool in
                reportProgressCount += 1
                XCTAssertLessThanOrEqual(request.progress.completedUnitCount, request.progress.totalUnitCount)
                XCTAssertGreaterThanOrEqual(request.progress.fractionCompleted, 0.0)
                XCTAssertLessThanOrEqual(request.progress.fractionCompleted, 1.0)
                print("Download: \(request.progress.completedUnitCount) / \(request.progress.totalUnitCount) (\(String(format: "%3.2f", request.progress.fractionCompleted * 100))")
                return request.progress.fractionCompleted >= 1.0
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
            
            XCTAssertGreaterThan(reportProgressCount, 0)
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
        let path = caminandes3TrailerURL.path
        let attributes = try! FileManager.default.attributesOfItem(atPath: path)
        guard let fileSize = attributes[.size] as? Int else {
            Swift.fatalError()
        }
        
        do {
            weak var expectationUpload = expectation(description: "Upload")
            
            let request = fileStore.upload(file, path: path) { (file, error) in
                self.file = file
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
        
        //XCTAssertNotNil(self.file?.entityId)
        
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
            
            fileStore.upload(self.file!, path: path) { (file, error) in
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
            
            fileStore.download(self.file!) { (file, data: Data?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                
                if let data = data {
                    XCTAssertEqual(data.count, fileSize)
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
        
        let file = MyFile()
        file.label = "trailer"
        file.publicAccessible = true
        self.file = file
        let path = caminandes3TrailerURL.path
        
        let fileStore = FileStore<MyFile>()
        
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
                            "label": "trailer",
                            "_downloadURL": "https://storage.googleapis.com/\(UUID().uuidString)/\(UUID().uuidString)/\(UUID().uuidString)"
                        ])
                    default:
                        Swift.fatalError()
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
                self.myFile = file
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        XCTAssertNotNil(self.myFile?.fileId)
        
        if useMockData {
            let url = caminandes3TrailerURL
            let data = try! Data(contentsOf: url)
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
            
            let request = fileStore.download(self.myFile!) { (file, data: Data?, error) in
                self.myFile = file
                XCTFail()
            }
            
            let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                XCTAssertTrue(request.executing)
                XCTAssertFalse(request.cancelled)
                
                request.cancel()
                
                XCTAssertFalse(request.executing)
                XCTAssertTrue(request.cancelled)
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
        }
        
        XCTAssertNotNil(self.myFile?.resumeDownloadData)
        if let resumeData = self.myFile?.resumeDownloadData {
            XCTAssertGreaterThan(resumeData.count, 0)
        }
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            let request = fileStore.download(self.myFile!) { (file, data: Data?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                
                if let file = file {
                    XCTAssertEqual(file.label, "trailer")
                }
                
                if let data = data {
                    XCTAssertEqual(UInt64(data.count), self.caminandes3TrailerFileSize)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
            
            XCTAssertNotNil(request.result)
            if let result = request.result {
                do {
                    let (file, data) = try result.value()
                    XCTAssertEqual(file.label, "trailer")
                    XCTAssertEqual(UInt64(data.count), self.caminandes3TrailerFileSize)
                } catch {
                    XCTFail(error.localizedDescription)
                }
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
    
    func testUploadDataWithFileId() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        let fileId = UUID().uuidString
        
        let file = File() {
            $0.publicAccessible = true
            $0.fileId = fileId
        }
        self.file = file
        var data = "Hello".data(using: String.Encoding.utf8)!
        
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
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, _data: Data?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(_data)
                XCTAssertNil(error)
                
                if let _data = _data {
                    XCTAssertEqual(data.count, _data.count)
                    XCTAssertEqual(data, _data)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
        }
        
        data = "Hello World".data(using: String.Encoding.utf8)!
        
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
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, _data: Data?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(_data)
                XCTAssertNil(error)
                
                if let _data = _data {
                    XCTAssertEqual(data.count, _data.count)
                    XCTAssertEqual(data, _data)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
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
        
        var file = File() {
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
                        Swift.fatalError()
                    }
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationUpload = expectation(description: "Upload")
            
            fileStore.upload(file, data: data) { (uploadedFile, error) in
                XCTAssertTrue(Thread.isMainThread)
                
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                file = uploadedFile!
                
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
                        Swift.fatalError()
                    }
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file, ttl: ttl) { (downloadedFile, url: URL?, error) in
                XCTAssertTrue(Thread.isMainThread)
                
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNil(error)
                
                file = downloadedFile!
                
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
    
    func testGetInstance() {
        let appKey = "file-get_instance-\(UUID().uuidString)"
        let client = Client(appKey: appKey, appSecret: "unit-test")
        let fileStore = FileStore(client: client)
        
        let fileCache = fileStore.cache?.cache as? RealmFileCache<File>
        XCTAssertNotNil(fileCache)
        if let fileCache = fileCache {
            let fileURL = fileCache.realm.configuration.fileURL
            XCTAssertNotNil(fileURL)
            if let fileURL = fileURL {
                let fileManager = FileManager.default
                XCTAssertTrue(fileManager.fileExists(atPath: fileURL.path))
            }
        }
    }
    
    func testAclJson() {
        let file = File {
            $0.acl = Acl {
                $0.writers = ["other-user-id"]
            }
        }
        let result = file.toJSON()
        let expected: JsonDictionary = [
            "_public" : false,
            "_acl" : [
                "w" : ["other-user-id"]
            ]
        ]
        
        let resultData = try! JSONSerialization.data(withJSONObject: result)
        let expectedData = try! JSONSerialization.data(withJSONObject: expected)
        
        let resultString = String(data: resultData, encoding: .utf8)!
        let expectedString = String(data: expectedData, encoding: .utf8)!
        
        XCTAssertEqual(resultString, expectedString)
    }
    
    func testAclShareWithAnotherUser() {
        let username = "aclShareWithAnotherUser_\(UUID().uuidString)"
        let password = UUID().uuidString
        
        signUp(username: username, password: password)
        
        XCTAssertNotNil(Kinvey.sharedClient.activeUser)
        if let user = Kinvey.sharedClient.activeUser {
            let userId = user.userId
            
            user.logout()
            
            XCTAssertNil(Kinvey.sharedClient.activeUser)
            
            signUp()
            
            XCTAssertNotNil(Kinvey.sharedClient.activeUser)
            
            if let user = Kinvey.sharedClient.activeUser {
                let secretMessage = "secret message"
                let secretMessageData = secretMessage.data(using: .utf8)!
                
                var uploadedFileId: String? = nil
                
                do {
                    if useMockData {
                        var count = 0
                        mockResponse { (request) -> HttpResponse in
                            defer {
                                count += 1
                            }
                            switch count {
                            case 0:
                                return HttpResponse(statusCode: 201, json: [
                                    "_public" : false,
                                    "_acl" : [
                                        "r" : ["589e6b0587e8310c76216fbb"],
                                        "w" : ["589e6b0587e8310c76216fbb"],
                                        "creator" : "589e6b0536d98358401c04ae"
                                    ],
                                    "_id" : "b69d8159-e59f-4337-b03b-1c2df3ccfed9",
                                    "_filename" : "9b77d4f0-43ea-4d70-9f65-e40808d1e429",
                                    "_kmd" : [
                                        "lmt" : Date().toString(),
                                        "ect" : Date().toString()
                                    ],
                                    "_uploadURL" : "https://www.googleapis.com/upload/storage/v1/b/0b5b1cd673164e3185a2e75e815f5cfe/o?name=b69d8159-e59f-4337-b03b-1c2df3ccfed9%2F9b77d4f0-43ea-4d70-9f65-e40808d1e429&uploadType=resumable&upload_id=AEnB2Up1heH7qbZXQIqsaT-XJNJTv3OKufiMN_9OXh5qGPVfwP4SaWrU5LW7-ZXswXc11l_Wi027IUjZx44CzajfycP8aam7HQ",
                                    "_expiresAt" : Date(timeIntervalSinceNow: 7 * TimeUnit.day.timeInterval).toString(),
                                    "_requiredHeaders" : [
                                    ]
                                ])
                            case 1:
                                return HttpResponse(json: [
                                    "kind": "storage#object",
                                    "id": "0b5b1cd673164e3185a2e75e815f5cfe/b69d8159-e59f-4337-b03b-1c2df3ccfed9/9b77d4f0-43ea-4d70-9f65-e40808d1e429/1486777096687000",
                                    "selfLink": "https://www.googleapis.com/storage/v1/b/0b5b1cd673164e3185a2e75e815f5cfe/o/b69d8159-e59f-4337-b03b-1c2df3ccfed9%2F9b77d4f0-43ea-4d70-9f65-e40808d1e429",
                                    "name": "b69d8159-e59f-4337-b03b-1c2df3ccfed9/9b77d4f0-43ea-4d70-9f65-e40808d1e429",
                                    "bucket": "0b5b1cd673164e3185a2e75e815f5cfe",
                                    "generation": "1486777096687000",
                                    "metageneration": "1",
                                    "contentType": "application/octet-stream",
                                    "timeCreated": Date().toString(),
                                    "updated": Date().toString(),
                                    "storageClass": "STANDARD",
                                    "timeStorageClassUpdated": Date().toString(),
                                    "size": "14",
                                    "md5Hash": "stMQhvCYJU0yMUQ4qGPmHg==",
                                    "mediaLink": "https://www.googleapis.com/download/storage/v1/b/0b5b1cd673164e3185a2e75e815f5cfe/o/b69d8159-e59f-4337-b03b-1c2df3ccfed9%2F9b77d4f0-43ea-4d70-9f65-e40808d1e429?generation=1486777096687000&alt=media",
                                    "crc32c": "BvSCPw==",
                                    "etag": "CJib1aX0htICEAE="
                                ])
                            case 2:
                                return HttpResponse(json: [
                                    "_id" : "b69d8159-e59f-4337-b03b-1c2df3ccfed9",
                                    "_public" : false,
                                    "_acl" : [
                                        "r" : ["589e6b0587e8310c76216fbb"],
                                        "w" : ["589e6b0587e8310c76216fbb"],
                                        "creator" : "589e6b0536d98358401c04ae"
                                    ],
                                    "_filename" : "9b77d4f0-43ea-4d70-9f65-e40808d1e429",
                                    "_kmd" : [
                                        "lmt" : Date().toString(),
                                        "ect" : Date().toString()
                                    ],
                                    "_downloadURL" : "https://storage.googleapis.com/0b5b1cd673164e3185a2e75e815f5cfe/b69d8159-e59f-4337-b03b-1c2df3ccfed9/9b77d4f0-43ea-4d70-9f65-e40808d1e429?GoogleAccessId=558440376631@developer.gserviceaccount.com&Expires=1486780696&Signature=XW1B07b1srNI890hH0AUKiwroJJ8gl0DrqoDai1G45Txi2YzpJ1UAiDlrxeAMNWRNEYCTmJkuwkNXtdp8sXz7dYbQMK3x96vIQ6QRVVef590rvSbObhziBVBBdn%2B814PmTNEm6737awQNBTc%2FweK2SnDU6jFdbA5cCXqWs5USWk%3D",
                                    "_expiresAt" : Date(timeIntervalSinceNow: TimeUnit.hour.timeInterval).toString()
                                ])
                            default:
                                Swift.fatalError()
                            }
                        }
                    }
                    defer {
                        if useMockData {
                            setURLProtocol(nil)
                        }
                    }
                    
                    let file = File {
                        $0.acl = Acl {
                            $0.readers = [userId]
                            $0.writers = [userId]
                        }
                    }
                    let fileStore = FileStore()
                    
                    weak var expectationUpload = expectation(description: "Upload")
                    
                    fileStore.upload(file, data: secretMessageData) { file, error in
                        XCTAssertNotNil(file)
                        XCTAssertNil(error)
                        
                        if let file = file {
                            uploadedFileId = file.fileId
                        }
                        
                        expectationUpload?.fulfill()
                    }
                    
                    waitForExpectations(timeout: defaultTimeout) { error in
                        expectationUpload = nil
                    }
                }
                
                XCTAssertNotNil(uploadedFileId)
                
                do {
                    if useMockData {
                        mockResponse(statusCode: 204, data: Data())
                    }
                    defer {
                        if useMockData {
                            setURLProtocol(nil)
                        }
                    }
                    
                    weak var expectationDestroy = expectation(description: "Destroy")
                    
                    user.destroy() {
                        XCTAssertTrue(Thread.isMainThread)
                        
                        switch $0 {
                        case .success:
                            break
                        case .failure:
                            XCTFail()
                        }
                        
                        expectationDestroy?.fulfill()
                    }
                    
                    waitForExpectations(timeout: defaultTimeout) { error in
                        expectationDestroy = nil
                    }
                }
                
                XCTAssertNil(Kinvey.sharedClient.activeUser)
                
                do {
                    if useMockData {
                        let userId = "589e6b0587e8310c76216fbb"
                        let user: JsonDictionary = [
                            "_id" : userId,
                            "username" : "aclShareWithAnotherUser_2AB4A3E2-793C-4E6F-B02D-BD4F714CE248",
                            "_kmd" : [
                                "lmt" : Date().toString(),
                                "ect" : Date().toString(),
                                "authtoken" : "f44b8f07-93ab-4c79-b413-f846ed7f34df.24+7RR+w8t845iG/dqkAJ3Vi6cU9ieO6tpg98vfVakY="
                            ],
                            "_acl" : [
                                "creator":"589e6b0587e8310c76216fbb"
                            ]
                        ]
                        mockResponse(json: user)
                        MockKinveyBackend.user[userId] = user
                    }
                    defer {
                        if useMockData {
                            setURLProtocol(nil)
                        }
                    }
                    
                    weak var expectationLogin = expectation(description: "Login")
                    
                    User.login(username: username, password: password) { user, error in
                        XCTAssertNotNil(user)
                        XCTAssertNil(error)
                        
                        expectationLogin?.fulfill()
                    }
                    
                    waitForExpectations(timeout: defaultTimeout) { error in
                        expectationLogin = nil
                    }
                }
                
                XCTAssertNotNil(Kinvey.sharedClient.activeUser)
                
                let file = File { $0.fileId = uploadedFileId }
                let fileStore = FileStore()
                
                do {
                    if useMockData {
                        var count = 0
                        mockResponse { (request) -> HttpResponse in
                            defer {
                                count += 1
                            }
                            switch count {
                            case 0:
                                return HttpResponse(json: [
                                    "_id" : "b69d8159-e59f-4337-b03b-1c2df3ccfed9",
                                    "_public" : false,
                                    "_acl" : [
                                        "r" : ["589e6b0587e8310c76216fbb"],
                                        "w" : ["589e6b0587e8310c76216fbb"],
                                        "creator" : "589e6b0536d98358401c04ae"
                                    ],
                                    "_filename" : "9b77d4f0-43ea-4d70-9f65-e40808d1e429",
                                    "_kmd" : [
                                        "lmt" : Date().toString(),
                                        "ect" : Date().toString()
                                    ],
                                    "_downloadURL" : "https://storage.googleapis.com/0b5b1cd673164e3185a2e75e815f5cfe/b69d8159-e59f-4337-b03b-1c2df3ccfed9/9b77d4f0-43ea-4d70-9f65-e40808d1e429?GoogleAccessId=558440376631@developer.gserviceaccount.com&Expires=1486780697&Signature=dS5zlMOJ3jgNZawRHd%2FZfCGx9eIYgARLDiDV3QcFP6%2BKshaxjbpAbc9NF2%2FkkDt3KxKPKfQKJoKJ%2FYvGJ2H3qH7vnrab7%2F1zx56roHawWnkexusZ1WxWJzmc3KNyGV9PeQrtyMzAoeZEjEmX38IMZrcat3Lzqo3rpzsSwONOiBI%3D",
                                    "_expiresAt" : Date(timeIntervalSinceNow: TimeUnit.hour.timeInterval).toString()
                                ])
                            case 1:
                                return HttpResponse(data: "secret message".data(using: .utf8))
                            default:
                                Swift.fatalError()
                            }
                        }
                    }
                    defer {
                        if useMockData {
                            setURLProtocol(nil)
                        }
                    }
                    
                    weak var expectationDownload = expectation(description: "Download")
                    
                    fileStore.download(file) { (file, data: Data?, error) in
                        XCTAssertNotNil(file)
                        XCTAssertNotNil(data)
                        XCTAssertNil(error)
                        
                        if let data = data {
                            let receivedMessage = String(data: data, encoding: .utf8)
                            XCTAssertEqual(receivedMessage, secretMessage)
                        }
                        
                        expectationDownload?.fulfill()
                    }
                    
                    waitForExpectations(timeout: defaultTimeout) { error in
                        expectationDownload = nil
                    }
                }
                
                do {
                    if useMockData {
                        mockResponse(json: ["count" : 1])
                    }
                    defer {
                        if useMockData {
                            setURLProtocol(nil)
                        }
                    }
                    
                    weak var expectationDelete = expectation(description: "Delete")
                    
                    fileStore.remove(file) { (count, error) in
                        XCTAssertNotNil(count)
                        XCTAssertNil(error)
                        
                        if let count = count {
                            XCTAssertEqual(count, 1)
                        }
                        
                        expectationDelete?.fulfill()
                    }
                    
                    waitForExpectations(timeout: defaultTimeout) { error in
                        expectationDelete = nil
                    }
                }
            }
        }
    }
    
    func testToJson() {
        let file = File()
        file.publicAccessible = true
        let acl = Acl()
        acl.globalRead.value = true
        acl.globalWrite.value = true
        acl.writers = ["user-to-write-1", "user-to-write-2"]
        acl.readers = ["user-to-read-1", "user-to-read-2"]
        file.acl = acl
        let json = file.toJSON()
        XCTAssertEqual(json["_public"] as? Bool, true)
        XCTAssertTrue(json["_acl"] is [String : Any])
        if let acl = json["_acl"] as? [String : Any] {
            XCTAssertEqual(acl["gr"] as? Bool, true)
            XCTAssertEqual(acl["gw"] as? Bool, true)
            
            XCTAssertTrue(acl["r"] is [String])
            if let readers = acl["r"] as? [String] {
                XCTAssertEqual(readers, ["user-to-read-1", "user-to-read-2"])
            }
            
            XCTAssertTrue(acl["w"] is [String])
            if let writers = acl["w"] as? [String] {
                XCTAssertEqual(writers, ["user-to-write-1", "user-to-write-2"])
            }
        }
    }
    
    func testFind() {
        signUp()
        
        let fileStore = FileStore()
        
        if useMockData {
            mockResponse(json: [
                [
                    "_id" : UUID().uuidString,
                    "_acl" : [
                        "gr" : true,
                        "creator" : UUID().uuidString
                    ],
                    "_filename" : "file.txt",
                    "_public" : true,
                    "mimeType" : "plain/txt",
                    "size" : 100,
                    "_kmd" : [
                        "lmt" : Date().toString(),
                        "ect" : Date().toString()
                    ],
                    "_downloadURL" : "https://storage.googleapis.com/file.txt"
                ]
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        fileStore.find() { files, error in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(files)
            XCTAssertNil(error)
            
            if let files = files {
                XCTAssertEqual(files.count, 1)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testRefresh() {
        signUp()
        
        let fileStore = FileStore()
        var _file: File? = nil
        
        do {
            if useMockData {
                mockResponse(json: [
                    [
                        "_id" : UUID().uuidString,
                        "_filename" : "image.png",
                        "size" : 4096,
                        "mimeType" : "image/png",
                        "_acl" : [
                            "gr" : true,
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : [
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
                        ],
                        "_downloadURL" : "https://storage.googleapis.com/image.png",
                        "_expiresAt" : Date(timeIntervalSinceNow: 3).toString()
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            fileStore.find(ttl: (5, .second)) { files, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(files)
                XCTAssertNil(error)
                
                if var files = files {
                    files = files.filter { $0.expiresAt != nil }
                    XCTAssertEqual(files.count, 1)
                    
                    if let file = files.first {
                        _file = file
                        let expiresInSeconds = file.expiresAt?.timeIntervalSinceNow
                        XCTAssertNotNil(expiresInSeconds)
                        if let expiresInSeconds = expiresInSeconds {
                            XCTAssertGreaterThan(expiresInSeconds, 0)
                            XCTAssertLessThanOrEqual(expiresInSeconds, 5)
                        }
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        XCTAssertNotNil(_file)
        
        if let file = _file {
            if useMockData {
                mockResponse(json: [
                    "_id" : UUID().uuidString,
                    "_filename" : "image.png",
                    "size" : 4096,
                    "mimeType" : "image/png",
                    "_acl" : [
                        "gr" : true,
                        "creator" : UUID().uuidString
                    ],
                    "_kmd" : [
                        "lmt" : Date().toString(),
                        "ect" : Date().toString()
                    ],
                    "_downloadURL" : "https://storage.googleapis.com/image.png",
                    "_expiresAt" : Date(timeIntervalSinceNow: 3).toString()
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationRefresh = expectation(description: "Refresh")
            
            fileStore.refresh(file, ttl: (5, .second)) { file, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                if let file = file {
                    let expiresInSeconds = file.expiresAt?.timeIntervalSinceNow
                    XCTAssertNotNil(expiresInSeconds)
                    if let expiresInSeconds = expiresInSeconds {
                        XCTAssertGreaterThan(expiresInSeconds, 0)
                        XCTAssertLessThanOrEqual(expiresInSeconds, 5)
                    }
                }
                
                expectationRefresh?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRefresh = nil
            }
        }
    }
    
    func testRefreshTimeoutError() {
        signUp()
        
        let fileStore = FileStore()
        var _file: File? = nil
        
        do {
            if useMockData {
                mockResponse(json: [
                    [
                        "_id" : UUID().uuidString,
                        "_filename" : "image.png",
                        "size" : 4096,
                        "mimeType" : "image/png",
                        "_acl" : [
                            "gr" : true,
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : [
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
                        ],
                        "_downloadURL" : "https://storage.googleapis.com/image.png",
                        "_expiresAt" : Date(timeIntervalSinceNow: 3).toString()
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            fileStore.find(ttl: (5, .second)) { files, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(files)
                XCTAssertNil(error)
                
                if var files = files {
                    files = files.filter { $0.expiresAt != nil }
                    XCTAssertEqual(files.count, 1)
                    
                    if let file = files.first {
                        _file = file
                        let expiresInSeconds = file.expiresAt?.timeIntervalSinceNow
                        XCTAssertNotNil(expiresInSeconds)
                        if let expiresInSeconds = expiresInSeconds {
                            XCTAssertGreaterThan(expiresInSeconds, 0)
                            XCTAssertLessThanOrEqual(expiresInSeconds, 5)
                        }
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        XCTAssertNotNil(_file)
        
        if let file = _file {
            mockResponse(error: timeoutError)
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationRefresh = expectation(description: "Refresh")
            
            fileStore.refresh(file, ttl: (5, .second)) { file, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(file)
                XCTAssertNotNil(error)
                XCTAssertTimeoutError(error)
                
                expectationRefresh?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRefresh = nil
            }
        }
    }
    
    func testCachedFileNotFound() {
        let file = File() {
            $0.fileId = UUID().uuidString
        }
        expect {
            try self.fileStore.cachedFile(file)
        }.to(beNil())
    }
    
    func testCreateBucketData() {
        let text = "test"
        let data = text.data(using: .utf8)!
        
        mockResponse { request in
            switch (request.url?.path, request.url?.query) {
            case ("/blob/_kid_"?, "tls=true"?):
                guard
                    let object = try? JSONSerialization.jsonObject(with: request),
                    let json = object as? [String : Any]
                else {
                    XCTFail()
                    return HttpResponse(statusCode: 404, data: Data())
                }
                XCTAssertNotNil(json["_public"] as? Bool)
                guard let _public = json["_public"] as? Bool else {
                    XCTFail()
                    return HttpResponse(statusCode: 404, data: Data())
                }
                XCTAssertFalse(_public)
                XCTAssertEqual(json["size"] as? Int, data.count)
                return HttpResponse(
                    statusCode: 201,
                    json: [
                        "size" : data.count,
                        "_public" : _public,
                        "_id" : UUID().uuidString,
                        "_filename" : UUID().uuidString,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : [
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
                        ],
                        "_uploadURL" : "https://www.googleapis.com/upload/storage/v1/b/\(UUID().uuidString)",
                        "_expiresAt" : Date().toString(),
                        "_requiredHeaders" : [
                        ]
                    ]
                )
            default:
                XCTFail(request.url?.absoluteString ?? "nil")
                return HttpResponse(statusCode: 404, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let fileStore = FileStore()
        let request = fileStore.create(File(), data: data)
        let file = try? request.waitForResult().value()
        XCTAssertNotNil(file)
        if let file = file {
            XCTAssertNotNil(file.fileId)
            XCTAssertNotNil(file.uploadURL)
            XCTAssertFalse(file.publicAccessible)
            XCTAssertEqual(file.size.value, Int64(data.count))
        }
    }
    
    func testCreateBucketDataTimeout() {
        let text = "test"
        let data = text.data(using: .utf8)!
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        let fileStore = FileStore()
        let request = fileStore.create(File(), data: data)
        do {
            let _ = try request.waitForResult().value()
            XCTFail()
        } catch {
            XCTAssertTimeoutError(error)
        }
    }
    
    func testCreateBucketPath() {
        let size = try! FileManager.default.attributesOfItem(atPath: caminandes3TrailerImageURL.path)[.size] as! Int64
        
        mockResponse { request in
            switch (request.url?.path, request.url?.query) {
            case ("/blob/_kid_"?, "tls=true"?):
                guard
                    let object = try? JSONSerialization.jsonObject(with: request),
                    let json = object as? [String : Any]
                else {
                    XCTFail()
                    return HttpResponse(statusCode: 404, data: Data())
                }
                XCTAssertNotNil(json["_public"] as? Bool)
                guard let _public = json["_public"] as? Bool else {
                    XCTFail()
                    return HttpResponse(statusCode: 404, data: Data())
                }
                XCTAssertFalse(_public)
                XCTAssertEqual(json["size"] as? Int64, size)
                return HttpResponse(
                    statusCode: 201,
                    json: [
                        "size" : size,
                        "_public" : _public,
                        "_id" : UUID().uuidString,
                        "_filename" : UUID().uuidString,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : [
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
                        ],
                        "_uploadURL" : "https://www.googleapis.com/upload/storage/v1/b/\(UUID().uuidString)",
                        "_expiresAt" : Date().toString(),
                        "_requiredHeaders" : [
                        ]
                    ]
                )
            default:
                XCTFail(request.url?.absoluteString ?? "nil")
                return HttpResponse(statusCode: 404, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let fileStore = FileStore()
        let request = fileStore.create(File(), path: caminandes3TrailerImageURL.path)
        let file = try? request.waitForResult().value()
        XCTAssertNotNil(file)
        if let file = file {
            XCTAssertNotNil(file.fileId)
            XCTAssertNotNil(file.uploadURL)
            XCTAssertFalse(file.publicAccessible)
            XCTAssertEqual(file.size.value, size)
        }
    }
    
    func testCreateBucketPathTimeout() {
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        let fileStore = FileStore()
        let request = fileStore.create(File(), path: caminandes3TrailerImageURL.path)
        do {
            let _ = try request.waitForResult().value()
            XCTFail()
        } catch {
            XCTAssertTimeoutError(error)
        }
    }
    
    func testCreateBucketInputStream() {
        let inputStream = InputStream(data: "test".data(using: .utf8)!)
        defer {
            inputStream.close()
        }
        
        mockResponse { request in
            switch (request.url?.path, request.url?.query) {
            case ("/blob/_kid_"?, "tls=true"?):
                guard
                    let object = try? JSONSerialization.jsonObject(with: request),
                    let json = object as? [String : Any]
                else {
                    XCTFail()
                    return HttpResponse(statusCode: 404, data: Data())
                }
                XCTAssertNotNil(json["_public"] as? Bool)
                guard let _public = json["_public"] as? Bool else {
                    XCTFail()
                    return HttpResponse(statusCode: 404, data: Data())
                }
                XCTAssertFalse(_public)
                return HttpResponse(
                    statusCode: 201,
                    json: [
                        "_public" : _public,
                        "_id" : UUID().uuidString,
                        "_filename" : UUID().uuidString,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : [
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
                        ],
                        "_uploadURL" : "https://www.googleapis.com/upload/storage/v1/b/\(UUID().uuidString)",
                        "_expiresAt" : Date().toString(),
                        "_requiredHeaders" : [
                        ]
                    ]
                )
            default:
                XCTFail(request.url?.absoluteString ?? "nil")
                return HttpResponse(statusCode: 404, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let fileStore = FileStore()
        let request = fileStore.create(File(), stream: inputStream)
        let file = try? request.waitForResult().value()
        XCTAssertNotNil(file)
        if let file = file {
            XCTAssertNotNil(file.fileId)
            XCTAssertNotNil(file.uploadURL)
            XCTAssertFalse(file.publicAccessible)
        }
    }
    
    func testCreateBucketInputStreamTimeout() {
        let inputStream = InputStream(data: "test".data(using: .utf8)!)
        defer {
            inputStream.close()
        }
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        let fileStore = FileStore()
        let request = fileStore.create(File(), stream: inputStream)
        do {
            let _ = try request.waitForResult().value()
            XCTFail()
        } catch {
            XCTAssertTimeoutError(error)
        }
    }
    
}
