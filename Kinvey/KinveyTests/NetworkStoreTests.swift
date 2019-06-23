//
//  NetworkStoreTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-15.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
import Foundation
@testable import Kinvey
import CoreLocation
import MapKit
import Nimble

#if os(macOS)
    typealias BezierPath = NSBezierPath
#else
    typealias BezierPath = UIBezierPath
#endif

class NetworkStoreTests: StoreTestCase {
    
    override func setUp() {
        super.setUp()
        signUp()
        
        store = try! DataStore<Person>.collection()
    }
    
    override func assertThread() {
        XCTAssertTrue(Thread.isMainThread)
    }
    
    func testSaveEvent() {
        guard !useMockData else {
            return
        }
        
        let store = try! DataStore<Event>.collection(.network)
        
        let event = Event()
        event.name = "Friday Party!"
        event.publishDate = Date(timeIntervalSince1970: 1468001397) // Fri, 08 Jul 2016 18:09:57 GMT
        event.location = "The closest pub!"
        
        event.acl?.globalRead.value = true
        event.acl?.globalWrite.value = true
        
        do {
            weak var expectationCreate = expectation(description: "Create")
            
            let request = store.save(event) {
                switch $0 {
                case .success(let event):
                    XCTAssertNotNil(event.entityId)
                    XCTAssertNotNil(event.name)
                    XCTAssertNotNil(event.publishDate)
                    XCTAssertNotNil(event.location)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationCreate?.fulfill()
            }
            
            var progressReportCount = 0
            
            keyValueObservingExpectation(for: request.progress, keyPath: "fractionCompleted") { (object, info) -> Bool in
                progressReportCount += 1
                XCTAssertLessThanOrEqual(request.progress.completedUnitCount, request.progress.totalUnitCount)
                XCTAssertGreaterThanOrEqual(request.progress.fractionCompleted, 0.0)
                XCTAssertLessThanOrEqual(request.progress.fractionCompleted, 1.0)
                return request.progress.fractionCompleted >= 1.0
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCreate = nil
            }
            
            XCTAssertGreaterThan(progressReportCount, 0)
        }
        
        XCTAssertNotNil(event.entityId)
        
        if let eventId = event.entityId {
            weak var expectationFind = expectation(description: "Find")
            
            let request = store.find(eventId) {
                switch $0 {
                case .success(let event):
                    XCTAssertNotNil(event.entityId)
                    XCTAssertNotNil(event.name)
                    XCTAssertNotNil(event.publishDate)
                    XCTAssertNotNil(event.location)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        do {
            class DelayURLProtocol: URLProtocol {
                
                static var delay: TimeInterval?
                
                let urlSession = URLSession(configuration: URLSessionConfiguration.default)
                
                override class func canInit(with request: URLRequest) -> Bool {
                    return true
                }
                
                override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                    return request
                }
                
                override func startLoading() {
                    if let delay = DelayURLProtocol.delay {
                        RunLoop.current.run(until: Date(timeIntervalSinceNow: delay))
                    }
                    
                    let dataTask = urlSession.dataTask(with: request) { data, response, error in
                        self.client?.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
                        if let data = data {
                            let chuckSize = Int(ceil(Double(data.count) / 10.0))
                            var offset = 0
                            while offset < data.count {
                                let chunk = data.subdata(in: offset ..< offset + min(chuckSize, data.count - offset))
                                self.client?.urlProtocol(self, didLoad: chunk)
                                if let delay = DelayURLProtocol.delay {
                                    RunLoop.current.run(until: Date(timeIntervalSinceNow: delay))
                                }
                                offset += chuckSize
                            }
                        }
                        self.client?.urlProtocolDidFinishLoading(self)
                    }
                    dataTask.resume()
                }
                
                override func stopLoading() {
                }
                
            }
            
            DelayURLProtocol.delay = 1
            
            setURLProtocol(DelayURLProtocol.self)
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            let request = store.find() {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success(let events):
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            var reportProgressCount = 0
            
            keyValueObservingExpectation(for: request.progress, keyPath: "fractionCompleted") { (object, info) -> Bool in
                reportProgressCount += 1
                XCTAssertLessThanOrEqual(request.progress.completedUnitCount, request.progress.totalUnitCount)
                XCTAssertGreaterThanOrEqual(request.progress.fractionCompleted, 0.0)
                XCTAssertLessThanOrEqual(request.progress.fractionCompleted, 1.0)
                print("Download: \(request.progress.completedUnitCount) / \(request.progress.totalUnitCount) \(String(format: "%3.2f", request.progress.fractionCompleted * 100))")
                return request.progress.fractionCompleted >= 1.0
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
            
            XCTAssertGreaterThan(reportProgressCount, 0)
        }
    }
    
    func testSaveAddress() {
        if useMockData {
            mockResponse(json: [
                "name": "Victor Barros",
                "age": 0,
                "address": [
                    "city": "Vancouver"
                ],
                "_acl": [
                    "creator": "58450d87c077970e38a388ba"
                ],
                "_kmd": [
                    "lmt": "2016-12-05T06:47:35.711Z",
                    "ect": "2016-12-05T06:47:35.711Z"
                ],
                "_id": "58450d87f29e22207c83a236"
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        let person = Person()
        person.name = "Victor Barros"
        
        let address = Address()
        address.city = "Vancouver"
        
        person.address = address
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person, options: try! Options(writePolicy: .forceNetwork)) {
            switch $0 {
            case .success(let person):
                XCTAssertNotNil(person.address)
                
                if let address = person.address {
                    XCTAssertNotNil(address.city)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSave = nil
        }
    }
    
    func testSaveArray() {
        let originalRestApiVersion = Kinvey.restApiVersion
        Kinvey.restApiVersion = 5
        defer {
            Kinvey.restApiVersion = originalRestApiVersion
        }
        if useMockData {
            mockResponse { request in
                let apiVersion = request.allHTTPHeaderFields?[KinveyHeaderField.apiVersion.rawValue]
                XCTAssertEqual(apiVersion, "5")
                var json = try! JSONSerialization.jsonObject(with: request) as! [[String : Any]]
                XCTAssertEqual(json.count, 2)
                XCTAssertEqual(json.first?["name"] as? String, "Victor")
                XCTAssertEqual(json.last?["name"] as? String, "Hugo")
                return HttpResponse(json: [
                    "entities": json,
                    "errors": []
                ])
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        let persons = [
            Person { $0.name = "Victor" },
            Person { $0.name = "Hugo" }
        ]
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(persons, options: try! Options(writePolicy: .forceNetwork)) {
            switch $0 {
            case .success(let result):
                XCTAssertEqual(result.entities.count, 2)
                XCTAssertEqual(result.entities.first??.name, "Victor")
                XCTAssertEqual(result.entities.last??.name, "Hugo")
                XCTAssertEqual(result.errors.count, 0)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSave = nil
        }
    }
    
    func testSaveArraySameId() {
        let originalRestApiVersion = Kinvey.restApiVersion
        Kinvey.restApiVersion = 5
        defer {
            Kinvey.restApiVersion = originalRestApiVersion
        }
        let id = UUID().uuidString
        if useMockData {
            mockResponse { request in
                let apiVersion = request.allHTTPHeaderFields?[KinveyHeaderField.apiVersion.rawValue]
                XCTAssertEqual(apiVersion, "5")
                var json = try! JSONSerialization.jsonObject(with: request) as! [[String : Any]]
                XCTAssertEqual(json.count, 2)
                XCTAssertEqual(json.first?["name"] as? String, "Victor")
                XCTAssertEqual(json.last?["name"] as? String, "Hugo")
                return HttpResponse(json: [
                    "entities": [json.first!, nil],
                    "errors": [
                        [
                            "index": 1,
                            "code": 11000,
                            "errmsg": "E11000 duplicate key error index: kdb1923.\(self.client.appKey!).Person.$_id_ dup key: { : \"\(id)\" }"
                        ]
                    ]
                ])
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        let persons = [
            Person { $0.entityId = id; $0.name = "Victor" },
            Person { $0.entityId = id; $0.name = "Hugo" }
        ]
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(persons, options: try! Options(writePolicy: .forceNetwork)) {
            switch $0 {
            case .success(let result):
                XCTAssertEqual(result.entities.count, 2)
                XCTAssertEqual(result.entities.first??.name, "Victor")
                XCTAssertNil(result.entities.last!)
                XCTAssertEqual(result.errors.count, 1)
                let error = result.errors.first as? MultiSaveError
                XCTAssertNotNil(error)
                if let error = error {
                    XCTAssertEqual(error.index, 1)
                    XCTAssertEqual(error.code, 11000)
                    XCTAssertEqual(error.message, "E11000 duplicate key error index: kdb1923.\(self.client.appKey!).Person.$_id_ dup key: { : \"\(id)\" }")
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSave = nil
        }
    }
    
    func testSaveArrayIdsAlreadyExists() {
        let originalRestApiVersion = Kinvey.restApiVersion
        Kinvey.restApiVersion = 5
        defer {
            Kinvey.restApiVersion = originalRestApiVersion
        }
        let id = UUID().uuidString
        XCTAssertFalse(isNew(entityId: id))
        var requests = [URLRequest]()
        if useMockData {
            mockResponse { request in
                requests.append(request)
                let apiVersion = request.allHTTPHeaderFields?[KinveyHeaderField.apiVersion.rawValue]
                XCTAssertEqual(apiVersion, "5")
                switch requests.count {
                case 1 ... 3 :
                    XCTAssertEqual(request.httpMethod, "PUT")
                    let json = try! JSONSerialization.jsonObject(with: request) as! [String : Any]
                    return HttpResponse(json: json)
                default:
                    XCTFail(request.url!.absoluteString)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        do {
            let person = Person { $0.entityId = id; $0.name = "Victor" }
            
            weak var expectationSave = expectation(description: "Save")
            
            store.save(person, options: try! Options(writePolicy: .forceNetwork)) {
                switch $0 {
                case .success(let person):
                    XCTAssertEqual(person.name, "Victor")
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSave = nil
            }
        }
        
        XCTAssertEqual(requests.count, useMockData ? 1 : 0)
        
        do {
            let persons = [
                Person { $0.personId = id; $0.name = "Hugo" },
                Person { $0.personId = id; $0.name = "Barros" }
            ]
            
            weak var expectationSave = expectation(description: "Save")
            
            store.save(persons, options: try! Options(writePolicy: .forceNetwork)) {
                switch $0 {
                case .success(let result):
                    XCTAssertEqual(result.entities.count, 2)
                    XCTAssertEqual(result.errors.count, 0)
                    XCTAssertNotNil(result.entities.first!)
                    XCTAssertNotNil(result.entities.last!)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSave = nil
            }
        }
        
        XCTAssertEqual(requests.count, useMockData ? 3 : 0)
    }
    
    func testSaveArrayFeatureUnavailableError() {
        var requestCount = 0
        defer {
            XCTAssertEqual(requestCount, useMockData ? 1 : 0)
        }
        if useMockData {
            mockResponse { request in
                requestCount += 1
                let apiVersion = request.allHTTPHeaderFields?[KinveyHeaderField.apiVersion.rawValue]
                XCTAssertNotEqual(apiVersion, "5")
                return HttpResponse(
                    statusCode: 400,
                    json: [
                        "error": "FeatureUnavailable",
                        "description": "Requested functionality is unavailable in this API version.",
                        "debug": "Inserting multiple entities is not available in this Kinvey API version"
                    ]
                )
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        let persons = [
            Person { $0.name = "Victor" },
            Person { $0.name = "Hugo" }
        ]
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(persons, options: try! Options(writePolicy: .forceNetwork)) {
            switch $0 {
            case .success:
                XCTFail("Should throw an FeatureUnavailable error")
            case .failure(let error):
                let _error = error as? Kinvey.Error
                guard let error = _error else {
                    XCTAssertNotNil(_error)
                    return
                }
                switch error {
                case .featureUnavailable(let debug, let description):
                    XCTAssertEqual(description, "Requested functionality is unavailable in this API version.")
                    XCTAssertEqual(debug, "Inserting multiple entities is not available in this Kinvey API version")
                default:
                    XCTFail(error.localizedDescription)
                }
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSave = nil
        }
    }
    
    func testSaveArrayEmpty() {
        let originalRestApiVersion = Kinvey.restApiVersion
        Kinvey.restApiVersion = 5
        defer {
            Kinvey.restApiVersion = originalRestApiVersion
        }
        if useMockData {
            mockResponse { request in
                let apiVersion = request.allHTTPHeaderFields?[KinveyHeaderField.apiVersion.rawValue]
                XCTAssertEqual(apiVersion, "5")
                var json = try! JSONSerialization.jsonObject(with: request) as! [[String : Any]]
                XCTAssertEqual(json.count, 2)
                XCTAssertEqual(json.first?["name"] as? String, "Victor")
                XCTAssertEqual(json.last?["name"] as? String, "Hugo")
                return HttpResponse(json: [
                    "entities": json,
                    "errors": []
                ])
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save([], options: try! Options(writePolicy: .forceNetwork)) {
            switch $0 {
            case .success(let result):
                fail("it should fail")
            case .failure(let error):
                XCTAssertNotNil(error as? Kinvey.Error)
                guard let kinveyError = error as? Kinvey.Error else {
                    return
                }
                switch kinveyError {
                case .badRequest(let httpResponse, let data, let description):
                    XCTAssertNil(httpResponse)
                    XCTAssertNil(data)
                    XCTAssertEqual(description, "Request body cannot be an empty array")
                default:
                    fail(error.localizedDescription)
                }
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSave = nil
        }
    }
    
    func testSaveArrayLimitSingleRequest() {
        let originalRestApiVersion = Kinvey.restApiVersion
        Kinvey.restApiVersion = 5
        defer {
            Kinvey.restApiVersion = originalRestApiVersion
        }
        var requests = 0
        if useMockData {
            mockResponse { request in
                requests += 1
                let apiVersion = request.allHTTPHeaderFields?[KinveyHeaderField.apiVersion.rawValue]
                XCTAssertEqual(apiVersion, "5")
                var json = try! JSONSerialization.jsonObject(with: request) as! [[String : Any]]
                XCTAssertEqual(json.count, 100)
                return HttpResponse(json: [
                    "entities": json,
                    "errors": []
                ])
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        let persons = (0 ..< 100).map { _ in
            return Person { $0.name = UUID().uuidString }
        }
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(persons, options: try! Options(writePolicy: .forceNetwork)) {
            switch $0 {
            case .success(let result):
                XCTAssertEqual(result.entities.count, 100)
                XCTAssertEqual(result.errors.count, 0)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSave = nil
        }
        
        XCTAssertEqual(requests, useMockData ? 1 : 0)
    }
    
    func testSaveArrayMultiRequest() {
        let originalRestApiVersion = Kinvey.restApiVersion
        Kinvey.restApiVersion = 5
        defer {
            Kinvey.restApiVersion = originalRestApiVersion
        }
        var requests = 0
        if useMockData {
            mockResponse { request in
                requests += 1
                let apiVersion = request.allHTTPHeaderFields?[KinveyHeaderField.apiVersion.rawValue]
                XCTAssertEqual(apiVersion, "5")
                var json = try! JSONSerialization.jsonObject(with: request) as! [[String : Any]]
                XCTAssertEqual(json.count, requests == 1 ? 100 : 1)
                return HttpResponse(json: [
                    "entities": json,
                    "errors": []
                ])
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        let persons = (0 ... 100).map { _ in
            return Person { $0.name = UUID().uuidString }
        }
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(persons, options: try! Options(writePolicy: .forceNetwork)) {
            switch $0 {
            case .success(let result):
                XCTAssertEqual(result.entities.count, 101)
                XCTAssertEqual(result.errors.count, 0)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSave = nil
        }
        
        XCTAssertEqual(requests, useMockData ? 2 : 0)
    }
    
    func testSaveAddressCodable() {
        let person = PersonCodable()
        person.name = "Victor Barros"
        
        let address = AddressCodable()
        address.city = "Vancouver"
        
        person.address = address
        
        if useMockData {
            mockResponse { response in
                let jsonObject = try? JSONSerialization.jsonObject(with: response)
                XCTAssertNotNil(jsonObject)
                if let jsonObject = jsonObject {
                    let json = jsonObject as? [String : Any]
                    XCTAssertNotNil(json)
                    if let json = json {
                        XCTAssertEqual(json["name"] as? String, person.name)
                        let address = json["address"] as? [String : Any]
                        XCTAssertNotNil(address)
                        if let address = address {
                            XCTAssertEqual(address["city"] as? String, person.address?.city)
                        }
                    }
                }
                return HttpResponse(json: [
                    "name": "Victor Barros",
                    "age": 0,
                    "address": [
                        "city": "Vancouver"
                    ],
                    "_acl": [
                        "creator": "58450d87c077970e38a388ba"
                    ],
                    "_kmd": [
                        "lmt": "2016-12-05T06:47:35.711Z",
                        "ect": "2016-12-05T06:47:35.711Z"
                    ],
                    "_id": "58450d87f29e22207c83a236"
                ])
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        let store = try! DataStore<PersonCodable>.collection(.network)
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person) {
            switch $0 {
            case .success(let person):
                XCTAssertNotNil(person.address)
                
                if let address = person.address {
                    XCTAssertNotNil(address.city)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSave = nil
        }
    }
    
    func testSaveAddressSync() {
        if useMockData {
            mockResponse(json: [
                "name": "Victor Barros",
                "age": 0,
                "address": [
                    "city": "Vancouver"
                ],
                "_acl": [
                    "creator": "58450d87c077970e38a388ba"
                ],
                "_kmd": [
                    "lmt": "2016-12-05T06:47:35.711Z",
                    "ect": "2016-12-05T06:47:35.711Z"
                ],
                "_id": "58450d87f29e22207c83a236"
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        let person = Person()
        person.name = "Victor Barros"
        
        let address = Address()
        address.city = "Vancouver"
        
        person.address = address
        
        let request = store.save(person, options: try! Options(writePolicy: .forceNetwork))
        XCTAssertTrue(request.wait(timeout: defaultTimeout))
        guard let result = request.result else {
            return
        }
        switch result {
        case .success(let person):
            XCTAssertNotNil(person.address)
            
            if let address = person.address {
                XCTAssertNotNil(address.city)
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testSaveAddressTryCatchSync() {
        if useMockData {
            mockResponse(json: [
                "name": "Victor Barros",
                "age": 0,
                "address": [
                    "city": "Vancouver"
                ],
                "_acl": [
                    "creator": "58450d87c077970e38a388ba"
                ],
                "_kmd": [
                    "lmt": "2016-12-05T06:47:35.711Z",
                    "ect": "2016-12-05T06:47:35.711Z"
                ],
                "_id": "58450d87f29e22207c83a236"
                ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        let person = Person()
        person.name = "Victor Barros"
        
        let address = Address()
        address.city = "Vancouver"
        
        person.address = address
        
        let request = store.save(person, options: try! Options(writePolicy: .forceNetwork))
        do {
            let person = try request.waitForResult(timeout: defaultTimeout).value()
            XCTAssertNotNil(person.address)
            
            if let address = person.address {
                XCTAssertNotNil(address.city)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testCount() {
        let store = try! DataStore<Event>.collection(.network)
        
        var eventsCount: Int? = nil
        
        do {
            if useMockData {
                mockResponse(json: ["count" : 85])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationCount = expectation(description: "Count")
            
            store.count {
                switch $0 {
                case .success(let count):
                    XCTAssertEqual(count, 85)
                    eventsCount = count
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationCount?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCount = nil
            }
        }
        
        do {
            weak var expectationCount = expectation(description: "Count")
            
            store.count(options: try! Options(readPolicy: .forceLocal)) {
                switch $0 {
                case .success(let count):
                    XCTAssertEqual(count, 0)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationCount?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCount = nil
            }
        }
        
        XCTAssertNotNil(eventsCount)
        
        do {
            if useMockData {
                mockResponse(statusCode: 201, json: [
                    "name": "Friday Party!",
                    "_acl": [
                        "creator": "58450c8000a5907e7dfb37bf"
                    ],
                    "_kmd": [
                        "lmt": "2016-12-05T06:43:12.395Z",
                        "ect": "2016-12-05T06:43:12.395Z"
                    ],
                    "_id": "58450c80d5ee86507a8b4e7e"
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            let event = Event()
            event.name = "Friday Party!"
            
            weak var expectationCreate = expectation(description: "Create")
            
            store.save(event) {
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationCreate?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCreate = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse(json: ["count" : 86])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationCount = expectation(description: "Count")
            
            store.count {
                switch $0 {
                case .success(let count):
                    XCTAssertNotNil(eventsCount)
                    if let eventsCount = eventsCount {
                        XCTAssertEqual(eventsCount + 1, count)
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationCount?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCount = nil
            }
        }
    }
    
    func testCountSync() {
        let store = try! DataStore<Event>.collection(.network)
        
        var eventsCount: Int? = nil
        
        do {
            if useMockData {
                mockResponse(json: ["count" : 85])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            let request = store.count(options: nil)
            XCTAssertTrue(request.wait(timeout: defaultTimeout))
            guard let result = request.result else {
                return
            }
            switch result {
            case .success(let count):
                XCTAssertEqual(count, 85)
                eventsCount = count
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        do {
            let request = store.count(options: try! Options(readPolicy: .forceLocal))
            XCTAssertTrue(request.wait(timeout: defaultTimeout))
            guard let result = request.result else {
                return
            }
            switch result {
            case .success(let count):
                XCTAssertEqual(count, 0)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        XCTAssertNotNil(eventsCount)
        
        do {
            if useMockData {
                mockResponse(statusCode: 201, json: [
                    "name": "Friday Party!",
                    "_acl": [
                        "creator": "58450c8000a5907e7dfb37bf"
                    ],
                    "_kmd": [
                        "lmt": "2016-12-05T06:43:12.395Z",
                        "ect": "2016-12-05T06:43:12.395Z"
                    ],
                    "_id": "58450c80d5ee86507a8b4e7e"
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            let event = Event()
            event.name = "Friday Party!"
            
            let request = store.save(event, options: nil)
            XCTAssertTrue(request.wait(timeout: defaultTimeout))
            guard let result = request.result else {
                return
            }
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        do {
            if useMockData {
                mockResponse(json: ["count" : 86])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            let request = store.count(options: nil)
            XCTAssertTrue(request.wait(timeout: defaultTimeout))
            guard let result = request.result else {
                return
            }
            switch result {
            case .success(let count):
                XCTAssertNotNil(eventsCount)
                guard let eventsCount = eventsCount else {
                    return
                }
                XCTAssertEqual(eventsCount + 1, count)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func testCountTryCatchSync() {
        let store = try! DataStore<Event>.collection(.network)
        
        var eventsCount: Int? = nil
        
        do {
            if useMockData {
                mockResponse(json: ["count" : 85])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            let request = store.count(options: nil)
            do {
                let count = try request.waitForResult(timeout: defaultTimeout).value()
                XCTAssertEqual(count, 85)
                eventsCount = count
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        do {
            let request = store.count(options: try! Options(readPolicy: .forceLocal))
            let count = try request.waitForResult(timeout: defaultTimeout).value()
            XCTAssertEqual(count, 0)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        XCTAssertNotNil(eventsCount)
        
        do {
            if useMockData {
                mockResponse(statusCode: 201, json: [
                    "name": "Friday Party!",
                    "_acl": [
                        "creator": "58450c8000a5907e7dfb37bf"
                    ],
                    "_kmd": [
                        "lmt": "2016-12-05T06:43:12.395Z",
                        "ect": "2016-12-05T06:43:12.395Z"
                    ],
                    "_id": "58450c80d5ee86507a8b4e7e"
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            let event = Event()
            event.name = "Friday Party!"
            
            let request = store.save(event, options: nil)
            let _ = try request.waitForResult(timeout: defaultTimeout).value()
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        do {
            if useMockData {
                mockResponse(json: ["count" : 86])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            let request = store.count(options: nil)
            let count = try request.waitForResult(timeout: defaultTimeout).value()
            XCTAssertNotNil(eventsCount)
            guard let eventsCount = eventsCount else {
                return
            }
            XCTAssertEqual(eventsCount + 1, count)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testCountTranslateQuery() {
        let store = try! DataStore<Event>.collection(.network)
        
        if useMockData {
            mockResponse { (request) -> HttpResponse in
                let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                let queryString = urlComponents.queryItems!.filter { $0.name == "query" }.first!.value!
                let query = try! JSONSerialization.jsonObject(with: queryString.data(using: .utf8)!) as! JsonDictionary
                XCTAssertNil(query["publishDate"])
                XCTAssertNotNil(query["date"])
                return HttpResponse(json: ["count" : 85])
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationCount = expectation(description: "Count")
        
        let query = Query(format: "publishDate >= %@", Date())
        
        store.count(query) {
            switch $0 {
            case .success(let count):
                XCTAssertEqual(count, 85)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationCount?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCount = nil
        }
    }
    
    func testCountTimeoutError() {
        let store = try! DataStore<Event>.collection(.network)
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationCount = expectation(description: "Count")
        
        store.count {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTimeoutError(error)
            }
            
            expectationCount?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCount = nil
        }
    }
    
    func testSaveAndFind10SkipLimit() {
        XCTAssertNotNil(Kinvey.sharedClient.activeUser)
        
        guard let user = Kinvey.sharedClient.activeUser else {
            return
        }
        
        var i = 0
        
        var mockData = [JsonDictionary]()
        do {
            if useMockData {
                mockResponse { request in
                    var json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
                    json["_acl"] = [
                        "creator": self.client.activeUser?.userId
                    ]
                    json["_kmd"] = [
                        "lmt": Date().toISO8601(),
                        "ect": Date().toISO8601()
                    ]
                    json["_id"] = UUID().uuidString
                    mockData.append(json)
                    return HttpResponse(statusCode: 201, json: json)
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            measure {
                let person = Person {
                    $0.name = "Person \(i)"
                }
                
                weak var expectationSave = self.expectation(description: "Save")
                
                self.store.save(person, options: try! Options(writePolicy: .forceNetwork)) {
                    switch $0 {
                    case .success:
                        break
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationSave?.fulfill()
                }
                
                self.waitForExpectations(timeout: self.defaultTimeout) { error in
                    expectationSave = nil
                }
                
                i += 1
            }
        }
        
        var skip = 0
        let limit = 2
        
        if useMockData {
            mockResponse { request in
                let regex = try! NSRegularExpression(pattern: "([^&=]*)=([^&]*)")
                let query = request.url!.query!
                let matches = regex.matches(in: query, range: NSRange(location: 0, length: query.count))
                var skip: Int?
                var limit: Int?
                for match in matches {
                    let key = query[query.index(query.startIndex, offsetBy: match.range(at: 1).location) ..< query.index(query.startIndex, offsetBy: match.range(at: 1).location + match.range(at: 1).length)]
                    let value = query[query.index(query.startIndex, offsetBy: match.range(at: 2).location) ..< query.index(query.startIndex, offsetBy: match.range(at: 2).location + match.range(at: 2).length)]
                    switch key {
                    case "skip":
                        skip = Int(value)
                    case "limit":
                        limit = Int(value)
                    default:
                        break
                    }
                }
                var results = mockData.sorted(by: { ($0["name"] as! String) < ($1["name"] as! String) })
                results = [JsonDictionary](results[skip! ..< skip! + limit!])
                return HttpResponse(statusCode: 200, json: results)
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        for _ in 0 ..< 5 {
            weak var expectationFind = expectation(description: "Find")
            
            let query = Query {
                $0.predicate = NSPredicate(format: "acl.creator == %@", user.userId)
                $0.skip = skip
                $0.limit = limit
                $0.ascending(\Person.name)
            }
            
            store.find(query, options: try! Options(readPolicy: .forceNetwork)) {
                switch $0 {
                case .success(let results):
                    XCTAssertEqual(results.count, limit)
                    
                    XCTAssertNotNil(results.first)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Person \(skip)")
                    }
                    
                    XCTAssertNotNil(results.last)
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Person \(skip + 1)")
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                skip += limit
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
    }
    
    class MethodNotAllowedError: URLProtocol {
        
        static let debugValue = "insert' method is not allowed for this collection."
        static let descriptionValue = "The method is not allowed for this resource."
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            let response = HTTPURLResponse(url: request.url!, statusCode: 405, httpVersion: "1.1", headerFields: [:])!
            client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            let responseBody = [
                "error": "MethodNotAllowed",
                "debug": MethodNotAllowedError.debugValue,
                "description": MethodNotAllowedError.descriptionValue
            ]
            let responseBodyData = try! JSONSerialization.data(withJSONObject: responseBody)
            client!.urlProtocol(self, didLoad: responseBodyData)
            
            client!.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {
        }
        
    }
    
    class DataLinkEntityNotFoundError: URLProtocol {
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: "1.1", headerFields: [:])!
            client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            let responseBody = [
                "error": "DataLinkEntityNotFound",
                "debug": "Error: Not Found",
                "description": "The data link could not find this entity"
            ]
            let responseBodyData = try! JSONSerialization.data(withJSONObject: responseBody)
            client!.urlProtocol(self, didLoad: responseBodyData)
            
            client!.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {
        }
        
    }
    
    func testGetDataLinkEntityNotFound() {
        setURLProtocol(DataLinkEntityNotFoundError.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find("sample-id", options: try! Options(readPolicy: .forceNetwork)) {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTrue(error is Kinvey.Error)
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .dataLinkEntityNotFound(_, _, let debug, let description):
                        XCTAssertEqual(debug, "Error: Not Found")
                        XCTAssertEqual(description, "The data link could not find this entity")
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testSaveMethodNotAllowed() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        let person = Person()
        person.name = "Victor Barros"
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person, options: try! Options(writePolicy: .forceNetwork)) {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTrue(error is Kinvey.Error)
                if let error = error as? Kinvey.Error {
                    XCTAssertEqual(error.description, MethodNotAllowedError.descriptionValue)
                    XCTAssertEqual(error.debugDescription, MethodNotAllowedError.debugValue)
                    
                    XCTAssertEqual("\(error)", MethodNotAllowedError.descriptionValue)
                    XCTAssertEqual("\(String(describing: error))", MethodNotAllowedError.descriptionValue)
                    XCTAssertEqual("\(String(reflecting: error))", MethodNotAllowedError.debugValue)
                    
                    switch error {
                    case .methodNotAllowed(_, _, let debug, let description):
                        XCTAssertEqual(description, MethodNotAllowedError.descriptionValue)
                        XCTAssertEqual(debug, MethodNotAllowedError.debugValue)
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSave = nil
        }
    }
    
    func testFindMethodNotAllowed() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(options: try! Options(readPolicy: .forceNetwork)) {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTrue(error is Kinvey.Error)
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .methodNotAllowed(_, _, let debug, let description):
                        XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                        XCTAssertEqual(description, "The method is not allowed for this resource.")
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testFindMethodNotAllowedSync() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        let request = store.find(options: try! Options(readPolicy: .forceNetwork))
        XCTAssertTrue(request.wait(timeout: defaultTimeout))
        guard let result = request.result else {
            return
        }
        switch result {
        case .success:
            XCTFail("A failure result is expected")
        case .failure(let error):
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .methodNotAllowed(_, _, let debug, let description):
                    XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                    XCTAssertEqual(description, "The method is not allowed for this resource.")
                default:
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }
    
    func testFindMethodNotAllowedTryCatchSync() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        let request = store.find(options: try! Options(readPolicy: .forceNetwork))
        do {
            let _ = try request.waitForResult(timeout: defaultTimeout).value()
            XCTFail("Error is expected")
        } catch {
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .methodNotAllowed(_, _, let debug, let description):
                    XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                    XCTAssertEqual(description, "The method is not allowed for this resource.")
                default:
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }
    
    func testFindByIdEntityNotFoundError() {
        mockResponse(
            statusCode: 404,
            json: [
                "error" : "EntityNotFound",
                "description" : "This entity not found in the collection",
                "debug" : ""
            ]
        )
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find("id-not-found", options: try! Options(readPolicy: .forceNetwork)) {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTrue(error is Kinvey.Error)
                
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .entityNotFound(let debug, let description):
                        XCTAssertEqual(debug, "")
                        XCTAssertEqual(description, "This entity not found in the collection")
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testFindByIdEntityNotFoundErrorSync() {
        mockResponse(
            statusCode: 404,
            json: [
                "error" : "EntityNotFound",
                "description" : "This entity not found in the collection",
                "debug" : ""
            ]
        )
        defer {
            setURLProtocol(nil)
        }
        
        let request = store.find("id-not-found", options: try! Options(readPolicy: .forceNetwork))
        XCTAssertTrue(request.wait(timeout: defaultTimeout))
        guard let result = request.result else {
            return
        }
        switch result {
        case .success:
            XCTFail("A failure result is expected")
        case .failure(let error):
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .entityNotFound(let debug, let description):
                    XCTAssertEqual(debug, "")
                    XCTAssertEqual(description, "This entity not found in the collection")
                default:
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }
    
    func testFindByIdEntityNotFoundErrorTryCatchSync() {
        mockResponse(
            statusCode: 404,
            json: [
                "error" : "EntityNotFound",
                "description" : "This entity not found in the collection",
                "debug" : ""
            ]
        )
        defer {
            setURLProtocol(nil)
        }
        
        let request = store.find("id-not-found", options: try! Options(readPolicy: .forceNetwork))
        do {
            let _ = try request.waitForResult(timeout: defaultTimeout).value()
            XCTFail("Error is expected")
        } catch {
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .entityNotFound(let debug, let description):
                    XCTAssertEqual(debug, "")
                    XCTAssertEqual(description, "This entity not found in the collection")
                default:
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }
    
    func testFindMethodObjectIdMissing() {
        mockResponse(json: [
            [
                "name" : "Victor"
            ]
        ])
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        let store = try! DataStore<Person>.collection(.network)
        
        store.find(options: nil) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
            switch result {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                let error = error as? Kinvey.Error
                XCTAssertNotNil(error)
                if let error = error {
                    switch error {
                    case .invalidOperation(let description):
                        XCTAssertEqual(description, "_id is required: \(Person.self)\n[\"name\": Victor]")
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testFindMethodObjectIdMissingAndRandomSampleValidationStrategy() {
        mockResponse(json: [
            [
                "name" : "Victor"
            ]
        ])
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        let store = try! DataStore<Person>.collection(.network, validationStrategy: .randomSample(percentage: 0.1))
        
        store.find(options: nil) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
            switch result {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                switch error {
                case let error as Kinvey.Error:
                    switch error {
                    case .objectIdMissing:
                        break
                    default:
                        XCTFail(error.localizedDescription)
                    }
                default:
                    XCTFail(error.localizedDescription)
                }
            }
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testFindMethodObjectIdMissingAndAllValidationStrategy() {
        mockResponse(json: [
            [
                "name" : "Victor"
            ]
        ])
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        let store = try! DataStore<Person>.collection(.network, validationStrategy: .all)
        
        store.find(options: nil) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
            switch result {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                switch error {
                case let error as Kinvey.Error:
                    switch error {
                    case .objectIdMissing:
                        break
                    default:
                        XCTFail(error.localizedDescription)
                    }
                default:
                    XCTFail(error.localizedDescription)
                }
            }
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testFindMethodObjectIdNotMissingAndAllValidationStrategy() {
        mockResponse(json: [
            [
                Entity.EntityCodingKeys.entityId.rawValue : UUID().uuidString,
                "name" : "Victor"
            ]
        ])
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        let store = try! DataStore<Person>.collection(.network, validationStrategy: .all)
        
        store.find(options: nil) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
            switch result {
            case .success(let persons):
                XCTAssertEqual(persons.count, 1)
                XCTAssertEqual(persons.first?.name, "Victor")
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testFindMethodObjectIdMissingAndZeroRandomSampleValidationStrategy() {
        mockResponse(json: [
            [
                "name" : "Victor"
            ]
        ])
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        let store = try! DataStore<Person>.collection(.network, validationStrategy: .randomSample(percentage: 0))
        
        store.find(options: nil) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
            switch result {
            case .success(let results):
                XCTAssertEqual(results.count, 1)
                XCTAssertNotNil(results.first)
                if let person = results.first {
                    XCTAssertEqual(person.name, "Victor")
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testFindMethodObjectIdMissingAndCustomValidationStrategy() {
        mockResponse(json: [
            [
                "name" : "Victor"
            ]
        ])
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        let store = try! DataStore<Person>.collection(.network, validationStrategy: .custom(validationBlock: { (entity: Array<Dictionary<String, Any>>) in
        }))
        
        store.find(options: nil) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
            switch result {
            case .success(let results):
                XCTAssertEqual(results.count, 1)
                XCTAssertNotNil(results.first)
                if let person = results.first {
                    XCTAssertEqual(person.name, "Victor")
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testGetMethodNotAllowed() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find("sample-id", options: try! Options(readPolicy: .forceNetwork)) {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTrue(error is Kinvey.Error)
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .methodNotAllowed(_, _, let debug, let description):
                        XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                        XCTAssertEqual(description, "The method is not allowed for this resource.")
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testRemoveByIdMethodNotAllowed() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectation(description: "Remove")
        
        store.remove(byId: "sample-id", options: try! Options(writePolicy: .forceNetwork)) {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTrue(error is Kinvey.Error)
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .methodNotAllowed(_, _, let debug, let description):
                        XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                        XCTAssertEqual(description, "The method is not allowed for this resource.")
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            
            expectationRemove?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testRemoveByIdMethodNotAllowedSync() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        let request = store.remove(byId: "sample-id", options: try! Options(writePolicy: .forceNetwork))
        XCTAssertTrue(request.wait(timeout: defaultTimeout))
        guard let result = request.result else {
            return
        }
        switch result {
        case .success:
            XCTFail("A failure result is expected")
        case .failure(let error):
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .methodNotAllowed(_, _, let debug, let description):
                    XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                    XCTAssertEqual(description, "The method is not allowed for this resource.")
                default:
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }
    
    func testRemoveByIdMethodNotAllowedTryCatchSync() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        let request = store.remove(byId: "sample-id", options: try! Options(writePolicy: .forceNetwork))
        do {
            let _ = try request.waitForResult(timeout: defaultTimeout).value()
            XCTFail("Error is expected")
        } catch {
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .methodNotAllowed(_, _, let debug, let description):
                    XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                    XCTAssertEqual(description, "The method is not allowed for this resource.")
                default:
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }
    
    func testRemoveMethodNotAllowed() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectation(description: "Remove")
        
        store.remove(options: try! Options(writePolicy: .forceNetwork)) {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTrue(error is Kinvey.Error)
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .methodNotAllowed(_, _, let debug, let description):
                        XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                        XCTAssertEqual(description, "The method is not allowed for this resource.")
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            
            expectationRemove?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testRemoveArrayTimeoutError() {
        let mockObjs: [[String : Any]] = [
            [
                "_id": UUID().uuidString,
                "name": "Test 1",
                "age": 18,
                "_acl": [
                    "creator": UUID().uuidString
                ],
                "_kmd": [
                    "lmt": Date().toISO8601(),
                    "ect": Date().toISO8601()
                ]
            ],
            [
                "_id": UUID().uuidString,
                "name": "Test 2",
                "age": 21,
                "_acl": [
                    "creator": UUID().uuidString
                ],
                "_kmd": [
                    "lmt": Date().toISO8601(),
                    "ect": Date().toISO8601()
                ]
            ]
        ]
        
        var _persons: AnyRandomAccessCollection<Person>? = nil
        
        do {
            mockResponse(json: mockObjs)
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(options: try! Options(readPolicy: .forceNetwork)) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 2)
                    _persons = persons
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout, handler: { (error) in
                expectationFind = nil
            })
        }
        
        XCTAssertNotNil(_persons)
        
        if let persons = _persons {
            mockResponse(error: timeoutError)
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationRemove = expectation(description: "Remove")
            
            store.remove(persons, options: try! Options(writePolicy: .forceNetwork)) {
                switch $0 {
                case .success:
                    XCTFail("A failure result is expected")
                case .failure(let error):
                    XCTAssertTimeoutError(error)
                }
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRemove = nil
            }
        }
    }
    
    func testFindArrayByIdCodable() {
        let id1 = UUID().uuidString
        let name1 = UUID().uuidString
        let age1 = Int(arc4random())
        let creator1 = UUID().uuidString
        let lmt1 = Date().toISO8601()
        let ect1 = Date().toISO8601()
        
        let id2 = UUID().uuidString
        let name2 = UUID().uuidString
        let age2 = Int(arc4random())
        let creator2 = UUID().uuidString
        let lmt2 = Date().toISO8601()
        let ect2 = Date().toISO8601()
        
        let mockObjs: [[String : Any]] = [
            [
                "_id": id1,
                "name": name1,
                "age": age1,
                "_acl": [
                    "creator": creator1
                ],
                "_kmd": [
                    "lmt": lmt1,
                    "ect": ect1
                ]
            ],
            [
                "_id": id2,
                "name": name2,
                "age": age2,
                "_acl": [
                    "creator": creator2
                ],
                "_kmd": [
                    "lmt": lmt2,
                    "ect": ect2
                ]
            ]
        ]
        
        do {
            mockResponse(json: mockObjs)
            defer {
                setURLProtocol(nil)
            }
            
            let store = try! DataStore<PersonCodable>.collection(.network)
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find() {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 2)
                    if let person = persons.first {
                        XCTAssertEqual(person.entityId, id1)
                        XCTAssertEqual(person.personId, id1)
                        XCTAssertEqual(person.name, name1)
                        XCTAssertEqual(person.age, age1)
                        XCTAssertEqual(person.acl?.creator, creator1)
                        XCTAssertEqual(person.metadata?.lmt, lmt1)
                        XCTAssertEqual(person.metadata?.ect, ect1)
                    }
                    if let person = persons.last {
                        XCTAssertEqual(person.entityId, id2)
                        XCTAssertEqual(person.personId, id2)
                        XCTAssertEqual(person.name, name2)
                        XCTAssertEqual(person.age, age2)
                        XCTAssertEqual(person.acl?.creator, creator2)
                        XCTAssertEqual(person.metadata?.lmt, lmt2)
                        XCTAssertEqual(person.metadata?.ect, ect2)
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout, handler: { (error) in
                expectationFind = nil
            })
        }
    }
    
    func testFindArrayByIdCustomParser() {
        let id1 = UUID().uuidString
        let name1 = UUID().uuidString
        let age1 = Int(arc4random())
        let creator1 = UUID().uuidString
        let lmt1 = Date().toISO8601()
        let ect1 = Date().toISO8601()
        
        let id2 = UUID().uuidString
        let name2 = UUID().uuidString
        let age2 = Int(arc4random())
        let creator2 = UUID().uuidString
        let lmt2 = Date().toISO8601()
        let ect2 = Date().toISO8601()
        
        let mockObjs: [[String : Any]] = [
            [
                "_id": id1,
                "name": name1,
                "age": age1,
                "_acl": [
                    "creator": creator1
                ],
                "_kmd": [
                    "lmt": lmt1,
                    "ect": ect1
                ]
            ],
            [
                "_id": id2,
                "name": name2,
                "age": age2,
                "_acl": [
                    "creator": creator2
                ],
                "_kmd": [
                    "lmt": lmt2,
                    "ect": ect2
                ]
            ]
        ]
        
        do {
            mockResponse(json: mockObjs)
            defer {
                setURLProtocol(nil)
            }
            
            let store = try! DataStore<PersonCustomParser>.collection(.network)
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find() {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 2)
                    if let person = persons.first {
                        XCTAssertEqual(person.entityId, id1)
                        XCTAssertEqual(person.personId, id1)
                        XCTAssertEqual(person.name, name1)
                        XCTAssertEqual(person.age, age1)
                    }
                    if let person = persons.last {
                        XCTAssertEqual(person.entityId, id2)
                        XCTAssertEqual(person.personId, id2)
                        XCTAssertEqual(person.name, name2)
                        XCTAssertEqual(person.age, age2)
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout, handler: { (error) in
                expectationFind = nil
            })
        }
    }
    
    func testRemoveArrayById() {
        let mockObjs: [[String : Any]] = [
            [
                "_id": UUID().uuidString,
                "name": "Test 1",
                "age": 18,
                "_acl": [
                    "creator": UUID().uuidString
                ],
                "_kmd": [
                    "lmt": Date().toISO8601(),
                    "ect": Date().toISO8601()
                ]
            ],
            [
                "_id": UUID().uuidString,
                "name": "Test 2",
                "age": 21,
                "_acl": [
                    "creator": UUID().uuidString
                ],
                "_kmd": [
                    "lmt": Date().toISO8601(),
                    "ect": Date().toISO8601()
                ]
            ]
        ]
        
        var _persons: AnyRandomAccessCollection<Person>? = nil
        
        do {
            mockResponse(json: mockObjs)
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(options: try! Options(readPolicy: .forceNetwork)) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 2)
                    _persons = persons
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout, handler: { (error) in
                expectationFind = nil
            })
        }
        
        XCTAssertNotNil(_persons)
        
        if let persons = _persons {
            mockResponse(json: ["count" : persons.count])
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationRemove = expectation(description: "Remove")
            
            store.remove(byIds: persons.map { $0.entityId! }, options: try! Options(writePolicy: .forceNetwork)) {
                switch $0 {
                case .success(let count):
                    XCTAssertEqual(count, persons.count)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRemove = nil
            }
        }
    }
    
    func testRemoveArrayByIdTimeoutError() {
        let mockObjs: [[String : Any]] = [
            [
                "_id": UUID().uuidString,
                "name": "Test 1",
                "age": 18,
                "_acl": [
                    "creator": UUID().uuidString
                ],
                "_kmd": [
                    "lmt": Date().toISO8601(),
                    "ect": Date().toISO8601()
                ]
            ],
            [
                "_id": UUID().uuidString,
                "name": "Test 2",
                "age": 21,
                "_acl": [
                    "creator": UUID().uuidString
                ],
                "_kmd": [
                    "lmt": Date().toISO8601(),
                    "ect": Date().toISO8601()
                ]
            ]
        ]
        
        var _persons: AnyRandomAccessCollection<Person>? = nil
        
        do {
            mockResponse(json: mockObjs)
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(options: try! Options(readPolicy: .forceNetwork)) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 2)
                    _persons = persons
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout, handler: { (error) in
                expectationFind = nil
            })
        }
        
        XCTAssertNotNil(_persons)
        
        if let persons = _persons {
            mockResponse(error: timeoutError)
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationRemove = expectation(description: "Remove")
            
            store.remove(byIds: persons.map { $0.entityId! }, options: try! Options(writePolicy: .forceNetwork)) {
                switch $0 {
                case .success:
                    XCTFail("A failure result is expected")
                case .failure(let error):
                    XCTAssertTimeoutError(error)
                }
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRemove = nil
            }
        }
    }
    
    func testRemoveEmptyArray() {
        mockResponse(json: [])
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectation(description: "Remove")
        
        store.remove(byIds: [], options: try! Options(writePolicy: .forceNetwork)) {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertEqual(error.localizedDescription, "ids cannot be an empty array")
            }
            
            expectationRemove?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testRemoveAll() {
        if useMockData {
            mockResponse { request in
                switch request.url!.path {
                case "/appdata/\(self.client.appKey!)/Person":
                    let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
                    let query = urlComponents?.queryItems?.filter{ $0.name == "query" }.first?.value
                    XCTAssertEqual(query, "{}")
                    return HttpResponse(json: ["count" : 100])
                default:
                    XCTFail(request.url!.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        let store = try! DataStore<Person>.collection(.network)
        
        weak var expectationRemove = expectation(description: "Remove")
        
        store.removeAll(options: nil) {
            switch $0 {
            case .success(let count):
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectationRemove?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testRemoveAllTimeoutError() {
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectation(description: "Remove")
        
        store.removeAll(options: try! Options(writePolicy: .forceNetwork)) {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                XCTAssertTimeoutError(error)
            }
            
            expectationRemove?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testSyncCount() {
        let person = Person()
        person.name = "Test"
        
        let store = try! DataStore<Person>.collection(.sync)
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person) {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSave = nil
        }
        
        XCTAssertEqual(try! DataStore<Person>.collection(.network).syncCount(), 0)
        XCTAssertEqual(try! DataStore<Person>.collection(.sync).syncCount(), 1)
        
        DataStore<Person>.clearCache()
        
        XCTAssertEqual(try! DataStore<Person>.collection(.sync).syncCount(), 0)
    }
    
    func testClientAppVersion() {
        mockResponse { (request) -> HttpResponse in
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Kinvey-Client-App-Version"], "1.0.0")
            return HttpResponse(json: [])
        }
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(
            options: try! Options(
                readPolicy: .forceNetwork,
                clientAppVersion: "1.0.0"
            )
        ) {
            switch $0 {
            case .success(let results):
                XCTAssertEqual(results.count, 0)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testCustomRequestProperties() {
        mockResponse { (request) -> HttpResponse in
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Kinvey-Custom-Request-Properties"], "{\"someKey\":\"someValue\"}")
            return HttpResponse(json: [])
        }
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(
            options: try! Options(
                readPolicy: .forceNetwork,
                customRequestProperties: [
                    "someKey" : "someValue"
                ]
            )
        ) {
            switch $0 {
            case .success(let results):
                XCTAssertEqual(results.count, 0)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testCustomRequestPropertiesPerRequest() {
        mockResponse { (request) -> HttpResponse in
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Kinvey-Custom-Request-Properties"], "{\"someKeyPerRequest\":\"someValuePerRequest\"}")
            return HttpResponse(json: [])
        }
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        let options = try! Options(
            readPolicy: .forceNetwork,
            customRequestProperties: [
                "someKeyPerRequest" : "someValuePerRequest"
            ]
        )
        store.find(
            options: options
        ) {
            switch $0 {
            case .success(let results):
                XCTAssertEqual(results.count, 0)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testDefaultHeaders() {
        mockResponse { request in
            let userAgent = request.allHTTPHeaderFields?["User-Agent"]
            XCTAssertNotNil(userAgent)
            if let userAgent = userAgent {
                let regex = try! NSRegularExpression(pattern: "Kinvey SDK (.*) \\(Swift (.*)\\)")
                let textCheckingResults = regex.matches(in: userAgent, range: NSRange(location: 0, length: userAgent.count))
                XCTAssertEqual(textCheckingResults.count, 1)
                if let textCheckingResult = textCheckingResults.first {
                    XCTAssertEqual(textCheckingResult.numberOfRanges, 3)
                    
                    let regex = try! NSRegularExpression(pattern: "(\\d+)\\.(\\d+)(?:\\.(\\d+))?")
                    
                    if textCheckingResult.numberOfRanges > 1 {
                        let kinveySdkVersion = userAgent.substring(with: textCheckingResult.range(at: 1))
                        let textCheckingResults = regex.matches(in: kinveySdkVersion, range: NSRange(location: 0, length: kinveySdkVersion.count))
                        XCTAssertEqual(textCheckingResults.count, 1)
                        if let textCheckingResult = textCheckingResults.first {
                            XCTAssertGreaterThanOrEqual(textCheckingResult.numberOfRanges, 3)
                            XCTAssertLessThanOrEqual(textCheckingResult.numberOfRanges, 4)
                            if textCheckingResult.numberOfRanges > 1 {
                                let majorVersion = kinveySdkVersion.substring(with: textCheckingResult.range(at: 1))
                                XCTAssertEqual(majorVersion, "3")
                            }
                        }
                    }
                    
                    if textCheckingResult.numberOfRanges > 2 {
                        let swiftVersion = userAgent.substring(with: textCheckingResult.range(at: 2))
                        let textCheckingResults = regex.matches(in: swiftVersion, range: NSRange(location: 0, length: swiftVersion.count))
                        XCTAssertEqual(textCheckingResults.count, 1)
                        if let textCheckingResult = textCheckingResults.first {
                            XCTAssertGreaterThanOrEqual(textCheckingResult.numberOfRanges, 3)
                            XCTAssertLessThanOrEqual(textCheckingResult.numberOfRanges, 4)
                            if textCheckingResult.numberOfRanges > 1 {
                                let majorVersion = swiftVersion.substring(with: textCheckingResult.range(at: 1))
                                XCTAssertEqual(majorVersion, "5")
                            }
                        }
                    }
                }
            }
            
            let deviceInfo = request.allHTTPHeaderFields?["X-Kinvey-Device-Info"]
            XCTAssertNotNil(deviceInfo)
            if let deviceInfo = deviceInfo {
                let data = deviceInfo.data(using: .utf8)
                XCTAssertNotNil(data)
                if let data = data {
                    let deviceInfoObj = try? JSONDecoder().decode(DeviceInfo.self, from: data)
                    XCTAssertNotNil(deviceInfoObj)
                }
            }
            
            return HttpResponse(json: [])
        }
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(options: try! Options(readPolicy: .forceNetwork)) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
            switch result {
            case .success(let results):
                XCTAssertEqual(results.count, 0)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testPlusSign() {
        var person = Person()
        person.name = "C++"
        
        var mockJson: JsonDictionary?
        do {
            if useMockData {
                let personId = UUID().uuidString
                mockResponse { (request) -> HttpResponse in
                    var json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
                    json[Entity.EntityCodingKeys.entityId] = personId
                    mockJson = json
                    return HttpResponse(json: json)
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSave = expectation(description: "Save")
            
            store.save(person, options: try! Options(writePolicy: .forceNetwork)) {
                switch $0 {
                case .success(let _person):
                    person = _person
                    XCTAssertNotNil(person.name)
                    if let name = person.name {
                        XCTAssertEqual(name, "C++")
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSave = nil
            }
        }
        
        XCTAssertNotNil(person.personId)
        guard let personId = person.personId else {
            return
        }
        
        do {
            if useMockData {
                mockResponse(json: [mockJson!])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            let query = Query(format: "name == %@", "C++")
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(query, options: try! Options(readPolicy: .forceNetwork)) {
                switch $0 {
                case .success(let persons):
                    XCTAssertGreaterThan(persons.count, 0)
                    XCTAssertNotNil(persons.first)
                    if let person = persons.first {
                        XCTAssertNotNil(person.name)
                        if let name = person.name {
                            XCTAssertEqual(name, "C++")
                        }
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
    }
    
    func testGeolocationQuery() {
        var person = Person()
        person.name = "Victor Barros"
        let latitude = 42.3133521
        let longitude = -71.1271963
        person.geolocation = GeoPoint(latitude: latitude, longitude: longitude)
        
        let json = person.toJSON()
        
        let geolocation = json[GeoPoint.CodingKey] as? [Double]
        XCTAssertNotNil(geolocation)
        if let geolocation = geolocation {
            XCTAssertEqual(geolocation[1], latitude)
            XCTAssertEqual(geolocation[0], longitude)
        }
        
        var mockJson: JsonDictionary?
        do {
            if useMockData {
                let personId = UUID().uuidString
                mockResponse(completionHandler: { (request) -> HttpResponse in
                    var json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
                    json[Entity.EntityCodingKeys.entityId] = personId
                    mockJson = json
                    return HttpResponse(json: json)
                })
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSave = expectation(description: "Save")
            
            store.save(person, options: try! Options(writePolicy: .forceNetwork)) {
                switch $0 {
                case .success(let _person):
                    person = _person
                    XCTAssertNotNil(person.geolocation)
                    if let geolocation = person.geolocation {
                        XCTAssertEqual(geolocation.latitude, latitude)
                        XCTAssertEqual(geolocation.longitude, longitude)
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSave = nil
            }
        }
        
        XCTAssertNotNil(person.personId)
        if let personId = person.personId {
            do {
                if useMockData {
                    mockResponse(json: mockJson!)
                }
                defer {
                    if useMockData {
                        setURLProtocol(nil)
                    }
                }
                
                weak var expectationFind = expectation(description: "Find")
                
                store.find(personId, options: try! Options(readPolicy: .forceNetwork)) {
                    switch $0 {
                    case .success(let person):
                        XCTAssertNotNil(person.geolocation)
                        if let geolocation = person.geolocation {
                            XCTAssertEqual(geolocation.latitude, latitude)
                            XCTAssertEqual(geolocation.longitude, longitude)
                        }
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationFind?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationFind = nil
                }
            }
            
            circle(latitude: latitude, longitude: longitude, mockJson: mockJson)
            polygon(latitude: latitude, longitude: longitude, mockJson: mockJson)
        }
    }
    
    func circle(latitude: Double, longitude: Double, mockJson: JsonDictionary?) {
        if useMockData {
            mockResponse(completionHandler: { (request) -> HttpResponse in
                let queryComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                let queryValue = queryComponents.queryItems!.filter { $0.name == "query" }.first!.value!
                let queryJson = try! JSONSerialization.jsonObject(with: queryValue.data(using: .utf8)!) as! JsonDictionary
                let geolocation = queryJson[GeoPoint.CodingKey] as! JsonDictionary
                let geoWithin = geolocation["$geoWithin"] as! JsonDictionary
                let centerSphere = geoWithin["$centerSphere"] as! [Any]
                let coordinates = centerSphere[0] as! [Double]
                let location = CLLocation(latitude: coordinates[1], longitude: coordinates[0])
                let radius = (centerSphere[1] as! Double) * 6371000.0
                return HttpResponse(json: [mockJson!].filter({ (item) -> Bool in
                    let itemGeolocation = item[GeoPoint.CodingKey] as! [Double]
                    let itemLocation = CLLocation(latitude: itemGeolocation[1], longitude: itemGeolocation[0])
                    return itemLocation.distance(from: location) <= radius
                }))
            })
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: 42.3536701, longitude: -71.0607657)
        
        do {
            let query = Query(format: "geolocation = %@", MKCircle(center: coordinate, radius: 8000))
            
            do {
                weak var expectationQuery = expectation(description: "Query")
                
                store.find(query, options: try! Options(readPolicy: .forceNetwork)) {
                    switch $0 {
                    case .success(let persons):
                        XCTAssertNotNil(persons.first)
                        if let person = persons.first {
                            XCTAssertNotNil(person.geolocation)
                            if let geolocation = person.geolocation {
                                XCTAssertEqual(geolocation.latitude, latitude)
                                XCTAssertEqual(geolocation.longitude, longitude)
                            }
                        }
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationQuery?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationQuery = nil
                }
            }
            
            do {
                weak var expectationQuery = expectation(description: "Query")
                
                store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                    switch $0 {
                    case .success(let persons):
                        XCTAssertNotNil(persons.first)
                        if let person = persons.first {
                            XCTAssertNotNil(person.geolocation)
                            if let geolocation = person.geolocation {
                                XCTAssertEqual(geolocation.latitude, latitude)
                                XCTAssertEqual(geolocation.longitude, longitude)
                            }
                        }
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationQuery?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationQuery = nil
                }
            }
        }
        
        do {
            let query = Query(format: "geolocation = %@", MKCircle(center: coordinate, radius: 7000))
            
            do {
                weak var expectationQuery = expectation(description: "Query")
                
                store.find(query, options: try! Options(readPolicy: .forceNetwork)) {
                    switch $0 {
                    case .success(let persons):
                        XCTAssertNil(persons.first)
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationQuery?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationQuery = nil
                }
            }
            
            do {
                weak var expectationQuery = expectation(description: "Query")
                
                store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                    switch $0 {
                    case .success(let persons):
                        XCTAssertNil(persons.first)
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationQuery?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationQuery = nil
                }
            }
        }
    }
    
    func polygon(latitude: Double, longitude: Double, mockJson: JsonDictionary?) {
        if useMockData {
            mockResponse(completionHandler: { (request) -> HttpResponse in
                let queryComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                let queryValue = queryComponents.queryItems!.filter { $0.name == "query" }.first!.value!
                let queryJson = try! JSONSerialization.jsonObject(with: queryValue.data(using: .utf8)!) as! JsonDictionary
                let geolocation = queryJson[GeoPoint.CodingKey] as! JsonDictionary
                let geoWithin = geolocation["$geoWithin"] as! JsonDictionary
                let polygonCoordinates = geoWithin["$polygon"] as! [[Double]]
                let locationCoordinates = polygonCoordinates.map {
                    return CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0])
                }
                XCTAssertEqual(polygonCoordinates.first!, polygonCoordinates.last!)
                let polygon = MKPolygon(coordinates: locationCoordinates, count: locationCoordinates.count)
                let path = BezierPath()
                for (i, locationCoordinate) in locationCoordinates.dropLast().enumerated() {
                    let point = CGPoint(x: locationCoordinate.latitude, y: locationCoordinate.longitude)
                    if i == 0 {
                        path.move(to: point)
                    } else {
                        #if os(macOS)
                            path.line(to: point)
                        #else
                            path.addLine(to: point)
                        #endif
                    }
                }
                path.close()
                return HttpResponse(json: [mockJson!].filter { item in
                    let itemGeolocation = item[GeoPoint.CodingKey] as! [Double]
                    let itemCoordinate = CLLocationCoordinate2D(latitude: itemGeolocation[1], longitude: itemGeolocation[0])
                    let itemPoint = CGPoint(x: itemCoordinate.latitude, y: itemCoordinate.longitude)
                    return path.contains(itemPoint)
                })
            })
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        do {
            let coordinates = [
                CLLocationCoordinate2D(latitude: 42.30229389364817, longitude: -71.14453953484005),
                CLLocationCoordinate2D(latitude: 42.30118020216164, longitude: -71.1079452220194),
                CLLocationCoordinate2D(latitude: 42.32628747399235, longitude: -71.10934348908339),
                CLLocationCoordinate2D(latitude: 42.32487077061631, longitude: -71.14195570326387),
                CLLocationCoordinate2D(latitude: 42.30229389364817, longitude: -71.14453953484005),
            ]
            let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
            let query = Query(format: "geolocation = %@", polygon)
            
            do {
                weak var expectationQuery = expectation(description: "Query")
                
                store.find(query, options: try! Options(readPolicy: .forceNetwork)) {
                    switch $0 {
                    case .success(let persons):
                        XCTAssertNotNil(persons.first)
                        if let person = persons.first {
                            XCTAssertNotNil(person.geolocation)
                            if let geolocation = person.geolocation {
                                XCTAssertEqual(geolocation.latitude, latitude)
                                XCTAssertEqual(geolocation.longitude, longitude)
                            }
                        }
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationQuery?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationQuery = nil
                }
            }
            
            do {
                weak var expectationQuery = expectation(description: "Query")
                
                store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                    switch $0 {
                    case .success(let persons):
                        XCTAssertNotNil(persons.first)
                        if let person = persons.first {
                            XCTAssertNotNil(person.geolocation)
                            if let geolocation = person.geolocation {
                                XCTAssertEqual(geolocation.latitude, latitude)
                                XCTAssertEqual(geolocation.longitude, longitude)
                            }
                        }
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationQuery?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationQuery = nil
                }
            }
        }
        
        do {
            let coordinates = [
                CLLocationCoordinate2D(latitude: 42.31363114297847, longitude: -71.12454163288896),
                CLLocationCoordinate2D(latitude: 42.31359338001615, longitude: -71.11596352589291),
                CLLocationCoordinate2D(latitude: 42.32375212671243, longitude: -71.11492645316849),
                CLLocationCoordinate2D(latitude: 42.32182013184487, longitude: -71.13022491168071),
                CLLocationCoordinate2D(latitude: 42.31363114297847, longitude: -71.12454163288896),
            ]
            let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
            let query = Query(format: "geolocation = %@", polygon)
            
            do {
                weak var expectationQuery = expectation(description: "Query")
                
                store.find(query, options: try! Options(readPolicy: .forceNetwork)) {
                    switch $0 {
                    case .success(let persons):
                        XCTAssertNil(persons.first)
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationQuery?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationQuery = nil
                }
            }
            
            do {
                weak var expectationQuery = expectation(description: "Query")
                
                store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                    switch $0 {
                    case .success(let persons):
                        XCTAssertNil(persons.first)
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationQuery?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationQuery = nil
                }
            }
        }
    }
    
    func testGroupCustomAggregation() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.network)
        
        if useMockData {
            mockResponse(json: [
                ["sum" : 926]
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationGroup = expectation(description: "Group")
        
        store.group(
            initialObject: ["sum" : 0],
            reduceJSFunction: "function(doc,out) { out.sum += doc.age; }",
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18))
        ) {
            switch $0 {
            case .success(let results):
                XCTAssertGreaterThan(results.count, 0)
                if let (person, result) = results.first {
                    XCTAssertNil(person.name)
                    XCTAssertNotNil(result["sum"] as? Int)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationGroup?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationGroup = nil
        }
    }
    
    func testGroupCustomAggregationSync() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.network)
        
        if useMockData {
            mockResponse(json: [
                ["sum" : 926]
                ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        let request = store.group(
            initialObject: ["sum" : 0],
            reduceJSFunction: "function(doc,out) { out.sum += doc.age; }",
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18)),
            options: nil
        )
        XCTAssertTrue(request.wait(timeout: defaultTimeout))
        guard let result = request.result else {
            return
        }
        switch result {
        case .success(let results):
            if let (person, result) = results.first {
                XCTAssertNil(person.name)
                XCTAssertNotNil(result["sum"] as? Int)
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testGroupCustomAggregationTryCatchSync() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.network)
        
        if useMockData {
            mockResponse(json: [
                ["sum" : 926]
                ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        let request = store.group(
            initialObject: ["sum" : 0],
            reduceJSFunction: "function(doc,out) { out.sum += doc.age; }",
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18)),
            options: nil
        )
        do {
            let results = try request.waitForResult(timeout: defaultTimeout).value()
            if let (person, result) = results.first {
                XCTAssertNil(person.name)
                XCTAssertNotNil(result["sum"] as? Int)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testGroupCustomAggregationByName() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.network)
        
        if useMockData {
            mockResponse(json: [
                [
                    "name" : "Victor",
                    "sum" : 926
                ]
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationGroup = expectation(description: "Group")
        
        store.group(
            keys: ["name"],
            initialObject: ["sum" : 0],
            reduceJSFunction: "function(doc,out) { out.sum += doc.age; }",
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18))
        ) {
            switch $0 {
            case .success(let results):
                XCTAssertGreaterThan(results.count, 0)
                if let (person, result) = results.first {
                    XCTAssertNotNil(person.name)
                    XCTAssertNotNil(result["sum"] as? Int)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationGroup?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationGroup = nil
        }
    }
    
    func testGroupCustomAggregationTimeoutError() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.network)
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationGroup = expectation(description: "Group")
        
        store.group(
            initialObject: ["sum" : 0],
            reduceJSFunction: "function(doc,out) { out.sum += doc.age; }",
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18))
        ) {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTimeoutError(error)
            }
            
            expectationGroup?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationGroup = nil
        }
    }
    
    func testGroupAggregationCountByName() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.network)
        
        if useMockData {
            mockResponse(json: [
                [
                    "name" : "Victor",
                    "count" : 32
                ]
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationGroup = expectation(description: "Group")
        
        store.group(
            count: ["name"],
            countType: Int.self,
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18))
        ) {
            switch $0 {
            case .success(let results):
                XCTAssertGreaterThanOrEqual(results.count, 0)
                
                if let first = results.first {
                    XCTAssertNotNil(first.value.name)
                    XCTAssertEqual(first.count, 32)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationGroup?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationGroup = nil
        }
    }
    
    func testGroupAggregationCountByNameTimeoutError() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.network)
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationGroup = expectation(description: "Group")
        
        store.group(
            count: ["name"],
            countType: Int.self,
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18))
        ) {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTimeoutError(error)
            }
            
            expectationGroup?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationGroup = nil
        }
    }
    
    func testGroupAggregationSumByName() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.network)
        
        if useMockData {
            mockResponse(json: [
                [
                    "name" : "Victor",
                    "sum" : 926.2
                ]
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationGroup = expectation(description: "Group")
        
        store.group(
            keys: ["name"],
            sum: "age",
            sumType: Double.self,
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18))
        ) {
            switch $0 {
            case .success(let results):
                XCTAssertGreaterThanOrEqual(results.count, 0)
                
                if let first = results.first {
                    XCTAssertNotNil(first.value.name)
                    XCTAssertEqual(first.sum, 926.2)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationGroup?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationGroup = nil
        }
    }
    
    func testGroupAggregationSumByNameTimeoutError() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.network)
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationGroup = expectation(description: "Group")
        
        store.group(
            keys: ["name"],
            sum: "age",
            sumType: Double.self,
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18))
        ) {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTimeoutError(error)
            }
            
            expectationGroup?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationGroup = nil
        }
    }
    
    func testGroupAggregationAvgByName() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.network)
        
        if useMockData {
            mockResponse(json: [
                [
                    "name" : "Victor",
                    "sum" : 926,
                    "count" : 32,
                    "avg" : 28.9375
                ]
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationGroup = expectation(description: "Group")
        
        store.group(
            keys: ["name"],
            avg: "age",
            avgType: Double.self,
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18))
        ) {
            switch $0 {
            case .success(let result):
                XCTAssertGreaterThanOrEqual(result.count, 0)
                
                if let first = result.first {
                    XCTAssertNotNil(first.value.name)
                    XCTAssertEqual(first.avg, 28.9375)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationGroup?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationGroup = nil
        }
    }
    
    func testGroupAggregationAvgByNameTimeoutError() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.network)
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationGroup = expectation(description: "Group")
        
        store.group(
            keys: ["name"],
            avg: "age",
            avgType: Double.self,
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18))
        ) {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTimeoutError(error)
            }
            
            expectationGroup?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationGroup = nil
        }
    }
    
    func testGroupAggregationMinByName() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.network)
        
        if useMockData {
            mockResponse(json: [
                [
                    "name" : "Victor",
                    "min" : 27.6
                ]
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationGroup = expectation(description: "Group")
        
        store.group(
            keys: ["name"],
            min: "age",
            minType: Double.self,
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18))
        ) {
            switch $0 {
            case .success(let result):
                XCTAssertGreaterThanOrEqual(result.count, 0)
                
                if let (person, min) = result.first {
                    XCTAssertNotNil(person.name)
                    XCTAssertEqual(min, 27.6)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationGroup?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationGroup = nil
        }
    }
    
    func testGroupAggregationMinByNameTimeoutError() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.network)
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationGroup = expectation(description: "Group")
        
        store.group(
            keys: ["name"],
            min: "age",
            minType: Float.self,
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18))
        ) {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTimeoutError(error)
            }
            
            expectationGroup?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationGroup = nil
        }
    }
    
    func testGroupAggregationMaxByName() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.network)
        
        if useMockData {
            mockResponse(json: [
                [
                    "name" : "Victor",
                    "max" : 30.5
                ]
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationGroup = expectation(description: "Group")
        
        store.group(
            keys: ["name"],
            max: "age",
            maxType: Float.self,
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18))
        ) {
            switch $0 {
            case .success(let result):
                XCTAssertGreaterThanOrEqual(result.count, 0)
                
                if let (person, max) = result.first {
                    XCTAssertNotNil(person.name)
                    XCTAssertEqual(max, 30.5)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationGroup?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationGroup = nil
        }
    }
    
    func testGroupAggregationMaxByNameTimeoutError() {
        signUp()
        
        let store = try! DataStore<Person>.collection(.network)
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationGroup = expectation(description: "Group")
        
        store.group(
            keys: ["name"],
            max: "age",
            maxType: Float.self,
            condition: NSPredicate(format: "age > %@", NSNumber(value: 18))
        ) {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTimeoutError(error)
            }
            
            expectationGroup?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationGroup = nil
        }
    }
    
    func testGroupCustomResultKey() {
        expect {
            try Aggregation.custom(keys: [], initialObject: [:], reduceJSFunction: "").resultKey()
        }.to(throwError())
    }
    
    func testRemoveByEmptyId() {
        let store = try! DataStore<Person>.collection(.network)
        
        weak var expectationRemove = expectation(description: "Remove")
        
        store.remove(byId: "") {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                let error = error as? Kinvey.Error
                XCTAssertNotNil(error)
                if let error = error {
                    switch error {
                    case .invalidOperation(let description):
                        XCTAssertEqual(description, "id cannot be an empty string")
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            expectationRemove?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testAutoPaginationDisabled() {
        let store = try! DataStore<Products>.collection(.network)
        
        mockResponse(
            statusCode: 400,
            json: [
                "error" : "ResultSetSizeExceeded",
                "description" : "Your query produced more than 10,000 results. Please rewrite your query to be more selective.",
                "debug" : "Your query returned 320193 results"
            ]
        )
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find { (result: Result<AnyRandomAccessCollection<Products>, Swift.Error>) in
            switch result {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .resultSetSizeExceeded(let debug, let description):
                        XCTAssertEqual(description, "Your query produced more than 10,000 results. Please rewrite your query to be more selective.")
                        XCTAssertTrue(debug.hasPrefix("Your query returned "))
                        XCTAssertTrue(debug.hasSuffix(" results"))
                    default:
                        XCTFail(error.debugDescription)
                    }
                } else {
                    XCTFail(error.localizedDescription)
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testAutoPaginationEnabledNetworkOnly() {
        mockResponse { (request) -> HttpResponse in
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            switch urlComponents.path {
            case "/appdata/_kid_/products/_count":
                return HttpResponse(json: ["count" : 21000])
            case "/appdata/_kid_/products/":
                let skip = Int(urlComponents.queryItems!.filter({ $0.name == "skip" }).first!.value!)!
                let limit = Int(urlComponents.queryItems!.filter({ $0.name == "limit" }).first!.value!)!
                let json = (0 ..< limit).map {
                    return [
                        "_id" : String(skip + $0 + 1),
                        "Description" : UUID().uuidString,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : [
                            "lmt" : Date().toISO8601(),
                            "ect" : Date().toISO8601()
                        ]
                    ]
                }
                return HttpResponse(json: json)
            default:
                XCTFail(request.url!.absoluteString)
                return HttpResponse(statusCode: 404, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let store = try! DataStore<Products>.collection(.network, autoPagination: true)
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find { (result: Result<AnyRandomAccessCollection<Products>, Swift.Error>) in
            switch result {
            case .success(let products):
                XCTAssertEqual(products.count, 21000)
                XCTAssertNotNil(products.first)
                if let product = products.first {
                    XCTAssertEqual(product.entityId, "1")
                }
                XCTAssertNotNil(products.last)
                if let product = products.last {
                    XCTAssertEqual(product.entityId, "21000")
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout * 5) { error in
            expectationFind = nil
        }
    }
    
    func testAutoPaginationEnabled() {
        let pageSizeLimit = 2_000
        let expectedCount = 21_000
        mockResponse { (request) -> HttpResponse in
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            let lastPage = Int(ceil(Double(21_000) / Double(pageSizeLimit)))
            switch urlComponents.path {
            case "/appdata/_kid_/products/_count":
                return HttpResponse(json: ["count" : 21000])
            case "/appdata/_kid_/products/":
                let skip = Int(urlComponents.queryItems!.filter({ $0.name == "skip" }).first!.value!)!
                let limit = Int(urlComponents.queryItems!.filter({ $0.name == "limit" }).first!.value!)!
                let json = (0 ..< limit).map {
                    return [
                        "_id" : String(skip + $0 + 1),
                        "Description" : UUID().uuidString,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : [
                            "lmt" : Date().toISO8601(),
                            "ect" : Date().toISO8601()
                        ]
                    ]
                }
                return HttpResponse(json: json)
            default:
                XCTFail(request.url!.absoluteString)
                return HttpResponse(statusCode: 404, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        let store = try! DataStore<Products>.collection(.sync, autoPagination: true)
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(options: try! Options(readPolicy: .forceNetwork, maxSizePerResultSet: pageSizeLimit)) { (result: Result<AnyRandomAccessCollection<Products>, Swift.Error>) in
            switch result {
            case .success(let products):
                XCTAssertEqual(products.count, expectedCount)
                XCTAssertNotNil(products.first)
                if let product = products.first {
                    XCTAssertEqual(product.entityId, "1")
                }
                XCTAssertNotNil(products.last)
                if let product = products.last {
                    XCTAssertEqual(product.entityId, "21000")
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout * 5) { error in
            expectationFind = nil
        }
    }
    
    func testNestedMapping() {
        mockResponse(json: [
            [
                "_id": "5a585afc8401f74dfdf21edb",
                "editions_rating": [],
                "editions": [
                    [
                        "year": 2015,
                        "rating": 0,
                        "available": false,
                        "retail_price": 10
                    ],
                    [
                        "year": 2016,
                        "rating": 0,
                        "available": false,
                        "retail_price": 20
                    ],
                    [
                        "year": 2017,
                        "rating": 0,
                        "available": false,
                        "retail_price": 30
                    ]
                ],
                "editions_available": [],
                "editions_retail_price": [],
                "next_edition": [
                    "year": 2018,
                    "rating": 0,
                    "available": false,
                    "retail_price": 40
                ],
                "title": "Learning Swift",
                "author_names": [],
                "editions_year": [],
                "_acl": [
                    "creator": "5a57ed14bb95120140f7f803"
                ],
                "_kmd": [
                    "lmt": "2018-01-12T06:51:40.220Z",
                    "ect": "2018-01-12T06:51:40.220Z"
                ]
            ]
        ])
        
        let book = Book()
        book.title = "Learning Swift"
        
        let firstEdition = BookEdition()
        firstEdition.year = 2015
        firstEdition.retailPrice = 10
        book.editions.append(firstEdition)
        
        let secondEdition = BookEdition()
        secondEdition.year = 2016
        secondEdition.retailPrice = 20
        book.editions.append(secondEdition)
        
        let thirdEdition = BookEdition()
        thirdEdition.year = 2017
        thirdEdition.retailPrice = 30
        book.editions.append(thirdEdition)
        
        let nextEdition = BookEdition()
        nextEdition.year = 2018
        nextEdition.retailPrice = 40
        book.nextEdition = nextEdition
        
        let store = try! DataStore<Book>.collection(.sync)
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            store.find(Query(format: "title == %@", book.title!), options: try! Options(readPolicy: .forceNetwork)) { (result: Result<AnyRandomAccessCollection<Book>, Swift.Error>) in
                switch result {
                case .success(let books):
                    XCTAssertEqual(books.count, 1)
                    if let book = books.first {
                        XCTAssertEqual(book.editions.count, 3)
                        if let _firstEdition = book.editions.first {
                            XCTAssertEqual(_firstEdition.year, firstEdition.year)
                            XCTAssertEqual(_firstEdition.retailPrice, firstEdition.retailPrice)
                        }
                        if let _thirdEdition = book.editions.last {
                            XCTAssertEqual(_thirdEdition.year, thirdEdition.year)
                            XCTAssertEqual(_thirdEdition.retailPrice, thirdEdition.retailPrice)
                        }
                        XCTAssertNotNil(book.nextEdition)
                        if let _nextEdition = book.nextEdition {
                            XCTAssertEqual(_nextEdition.year, nextEdition.year)
                            XCTAssertEqual(_nextEdition.retailPrice, nextEdition.retailPrice)
                        }
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            store.find(Query(format: "title == %@", book.title!), options: nil) { (result: Result<AnyRandomAccessCollection<Book>, Swift.Error>) in
                switch result {
                case .success(let books):
                    XCTAssertEqual(books.count, 1)
                    if let book = books.first {
                        XCTAssertEqual(book.editions.count, 3)
                        if let _firstEdition = book.editions.first {
                            XCTAssertEqual(_firstEdition.year, firstEdition.year)
                            XCTAssertEqual(_firstEdition.retailPrice, firstEdition.retailPrice)
                        }
                        if let _thirdEdition = book.editions.last {
                            XCTAssertEqual(_thirdEdition.year, thirdEdition.year)
                            XCTAssertEqual(_thirdEdition.retailPrice, thirdEdition.retailPrice)
                        }
                        XCTAssertNotNil(book.nextEdition)
                        if let _nextEdition = book.nextEdition {
                            XCTAssertEqual(_nextEdition.year, nextEdition.year)
                            XCTAssertEqual(_nextEdition.retailPrice, nextEdition.retailPrice)
                        }
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
    }
    
    func testDataStoreCacheInstances() {
        let ds1 = try! DataStore<Person>.collection(.network, options: try! Options(deltaSet: true))
        let ds2 = try! DataStore<Person>.collection(.network, options: try! Options(deltaSet: false))
        XCTAssertTrue(ds1.deltaSet)
        XCTAssertFalse(ds2.deltaSet)
        
        let addr1 = Unmanaged.passUnretained(ds1).toOpaque()
        let addr2 = Unmanaged.passUnretained(ds2).toOpaque()
        XCTAssertNotEqual(addr1, addr2)
        XCTAssertNotEqual(ds1, ds2)
        XCTAssertNotEqual(ds1.hashValue, ds2.hashValue)
        
        var h1 = Hasher()
        ds1.hash(into: &h1)
        
        var h2 = Hasher()
        ds2.hash(into: &h2)
        
        XCTAssertNotEqual(h1.finalize(), h2.finalize())
    }
    
    func testFindCancel() {
        signUp()
        
        let dataStore = try! DataStore<Person>.collection(.network)
        
        var running = true
        
        var runLoop: CFRunLoop?
        defer {
            if let runLoop = runLoop {
                CFRunLoopStop(runLoop)
            }
        }
        mockResponse { (request) -> HttpResponse in
            let currentRunLoop = CFRunLoopGetCurrent()
            while running {
                autoreleasepool {
                    DispatchQueue.main.async { runLoop = currentRunLoop }
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                    DispatchQueue.main.async { runLoop = nil }
                }
            }
            return HttpResponse(statusCode: 404, data: Data())
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        let request = dataStore.find(options: nil) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
            XCTFail("Handler was not expected to be called")
            expectationFind?.fulfill()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            request.cancel()
            running = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testBLRuntimeError() {
        signUp()
        
        let description = "The Business Logic script has a runtime error. See debug message for details."
        let debug = "ReferenceError: asdadsa is not defined"
        let stack = "ReferenceError: asdadsa is not defined\n  at onPreFetch (Person/onPreFetch:2:5)"
        
        mockResponse(
            statusCode: 400,
            json: [
                "error": "BLRuntimeError",
                "description": description,
                "debug": debug,
                "stack": stack.replacingOccurrences(of: "\n", with: "\\n")
            ]
        )
        defer {
            setURLProtocol(nil)
        }
        
        let dataStore = try! DataStore<Person>.collection(.network)
        
        weak var expectationFind = expectation(description: "Find")
        
        dataStore.find() {
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTrue(error is Kinvey.Error)
                XCTAssertNotNil(error as? Kinvey.Error)
                if let error = error as? Kinvey.Error {
                    XCTAssertEqual(error.debugDescription, debug)
                    XCTAssertEqual(error.description, description)
                    switch error {
                    case .blRuntime(let _debug, let _description, let _stack):
                        XCTAssertEqual(_debug, debug)
                        XCTAssertEqual(_description, description)
                        XCTAssertEqual(_stack, stack)
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
}

class Products: Entity {
    
    @objc
    dynamic var desc: String?
    
    override static func collectionName() -> String {
        return "products"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        desc <- ("desc", map["Description"])
    }
    
}
