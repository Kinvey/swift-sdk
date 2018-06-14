//
//  ClientTestCase.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-04-10.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
import Kinvey
import Nimble

class ClientTestCase: KinveyTestCase {
    
    func testPing() {
        if useMockData {
            mockResponse(json: [
                "version" : "3.9.28",
                "kinvey" : "hello My App",
                "appName" : "My App",
                "environmentName" : "My Environment"
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationPing = self.expectation(description: "Ping")
        
        Kinvey.sharedClient.ping { (envInfo, error) in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(envInfo)
            XCTAssertNil(error)
            
            if let envInfo = envInfo {
                XCTAssertEqual(envInfo.version, "3.9.28")
                XCTAssertEqual(envInfo.kinvey, "hello My App")
                XCTAssertEqual(envInfo.appName, "My App")
                XCTAssertEqual(envInfo.environmentName, "My Environment")
            }
            
            expectationPing?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationPing = nil
        }
    }
    
    func testPingInstanceId() {
        weak var expectationInitialize = self.expectation(description: "Initialize")
        
        let appKey = UUID().uuidString
        let client = Client(appKey: appKey, appSecret: UUID().uuidString, instanceId: "my-instance-id") { result in
            expectationInitialize?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationInitialize = nil
        }
        
        if useMockData {
            mockResponse { request in
                XCTAssertEqual(request.url?.host, "my-instance-id-baas.kinvey.com")
                XCTAssertEqual(request.url?.path, "/appdata/\(appKey)")
                return HttpResponse(json: [
                    "version" : "3.9.28",
                    "kinvey" : "hello My App",
                    "appName" : "My App",
                    "environmentName" : "My Environment"
                ])
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationPing = self.expectation(description: "Ping")
        
        client.ping { (envInfo, error) in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(envInfo)
            XCTAssertNil(error)
            
            if let envInfo = envInfo {
                XCTAssertEqual(envInfo.version, "3.9.28")
                XCTAssertEqual(envInfo.kinvey, "hello My App")
                XCTAssertEqual(envInfo.appName, "My App")
                XCTAssertEqual(envInfo.environmentName, "My Environment")
            }
            
            expectationPing?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationPing = nil
        }
    }
    
    func testPingInstanceIdDeprecateClientInitialization() {
        weak var expectationInitialize = self.expectation(description: "Initialize")
        
        let appKey = UUID().uuidString
        let client = Client()
        client.initialize(appKey: appKey, appSecret: UUID().uuidString) { user, error in
            expectationInitialize?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationInitialize = nil
        }
        
        if useMockData {
            mockResponse { request in
                XCTAssertEqual(request.url?.host, "baas.kinvey.com")
                XCTAssertEqual(request.url?.path, "/appdata/\(appKey)")
                return HttpResponse(json: [
                    "version" : "3.9.28",
                    "kinvey" : "hello My App",
                    "appName" : "My App",
                    "environmentName" : "My Environment"
                ])
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationPing = self.expectation(description: "Ping")
        
        client.ping { (envInfo, error) in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(envInfo)
            XCTAssertNil(error)
            
            if let envInfo = envInfo {
                XCTAssertEqual(envInfo.version, "3.9.28")
                XCTAssertEqual(envInfo.kinvey, "hello My App")
                XCTAssertEqual(envInfo.appName, "My App")
                XCTAssertEqual(envInfo.environmentName, "My Environment")
            }
            
            expectationPing?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationPing = nil
        }
    }
    
    func testPingAppNotFound() {
        if useMockData {
            mockResponse(statusCode: 404, json: [
                "error" : "AppNotFound",
                "description" : "This app backend not found",
                "debug" : ""
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationPing = self.expectation(description: "Ping")
        
        Kinvey.sharedClient.ping { (envInfo, error) in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(envInfo)
            XCTAssertNotNil(error)
            
            if let error = error as? Kinvey.Error {
                XCTAssertEqual(error.description, "This app backend not found")
                switch error {
                case .appNotFound(let description):
                    XCTAssertEqual(description, "This app backend not found")
                default:
                    XCTFail()
                }
            }
            
            expectationPing?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationPing = nil
        }
    }
    
    func testPingClientNotInitialized() {
        let client = Client()
        
        weak var expectationPing = self.expectation(description: "Ping")
        
        client.ping { (envInfo, error) in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(envInfo)
            XCTAssertNotNil(error)
            
            if let error = error as? Kinvey.Error {
                XCTAssertEqual(error.description, "Please initialize your client calling the initialize() method before call ping()")
                switch error {
                case .invalidOperation(let description):
                    XCTAssertEqual(description, "Please initialize your client calling the initialize() method before call ping()")
                default:
                    XCTFail()
                }
            }
            
            expectationPing?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationPing = nil
        }
    }
    
    func testEmptyEnvironmentInfo() {
        XCTAssertNil(EnvironmentInfo(JSON: [:]))
    }
    
    func testClientAppKeyAndAppSecretEmpty() {
        expect { () -> Void in
            let _ = Client(appKey: "", appSecret: "")
        }.to(throwAssertion())
    }
    
    func testDataStoreWithoutInitilizeClient() {
        expect { () -> Void in
            let client = Client()
            let _ = DataStore<Person>.collection(options: Options(client: client))
        }.to(throwAssertion())
    }
    
    func testDefaultMICVersion() {
        XCTAssertEqual(Client().micApiVersion, .v3)
    }
    
    func testLogNetworkDisabled() {
        XCTAssertFalse(Client().logNetworkEnabled)
    }
    
    func testDeviceInfoHeader() {
        if useMockData {
            mockResponse { request in
                guard let allHTTPHeaderFields = request.allHTTPHeaderFields else {
                    XCTAssertNotNil(request.allHTTPHeaderFields)
                    return HttpResponse(statusCode: 404, data: Data())
                }
                
                let headers = Dictionary<String, String>(uniqueKeysWithValues: allHTTPHeaderFields.map({ (pair: (key: String, value: String)) -> (key: String, value: String) in
                    return (key: pair.key.lowercased(), value: pair.value)
                }))
                
                let deviceInfoJsonString = headers["x-kinvey-device-info"]
                guard let data = deviceInfoJsonString?.data(using: .utf8) else {
                    XCTAssertNotNil(deviceInfoJsonString?.data(using: .utf8))
                    return HttpResponse(statusCode: 404, data: Data())
                }
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data)
                    XCTAssertTrue(jsonObject is JsonDictionary)
                    if let jsonObject = jsonObject as? JsonDictionary {
                        XCTAssertNotNil(jsonObject["hv"] as? Int)
                        XCTAssertNotNil(jsonObject["md"] as? String)
                        XCTAssertNotNil(jsonObject["os"] as? String)
                        XCTAssertNotNil(jsonObject["ov"] as? String)
                        XCTAssertNotNil(jsonObject["sdk"] as? String)
                        XCTAssertNotNil(jsonObject["pv"] as? String)
                    }
                } catch {
                    XCTFail(error.localizedDescription)
                }
                
                return HttpResponse(json: [
                    "version" : "3.9.28",
                    "kinvey" : "hello My App",
                    "appName" : "My App",
                    "environmentName" : "My Environment"
                ])
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationPing = self.expectation(description: "Ping")
        
        Kinvey.sharedClient.ping { (envInfo, error) in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(envInfo)
            XCTAssertNil(error)
            
            if let envInfo = envInfo {
                XCTAssertEqual(envInfo.version, "3.9.28")
                XCTAssertEqual(envInfo.kinvey, "hello My App")
                XCTAssertEqual(envInfo.appName, "My App")
                XCTAssertEqual(envInfo.environmentName, "My Environment")
            }
            
            expectationPing?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationPing = nil
        }
    }
    
}
