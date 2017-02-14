//
//  SSOApp2Tests.swift
//  SSOApp2Tests
//
//  Created by Victor Hugo on 2016-11-10.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey
@testable import SSOApp2

class SSOApp2Tests: KinveyTestCase {
    
    override func setUp() {
    }
    
    override func tearDown() {
    }
    
    func testSSO() {
        class MockURLProtocol: URLProtocol {
            
            override class func canInit(with request: URLRequest) -> Bool {
                if let url = request.url {
                    return url.scheme == "https" && (url.host == "auth.kinvey.com" || url.host == "baas.kinvey.com")
                }
                return false
            }
            
            override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                return request
            }
            
            override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
                return false
            }
            
            override func startLoading() {
                if request.url!.scheme != "https" && request.url!.scheme != "http" {
                    return
                }
                switch request.url!.path {
                case "/user/appKey/login":
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    
                    let json: [String : Any] = [
                        "_id" : UUID().uuidString,
                        "_socialIdentity" : [
                            "kinveyAuth" :[
                                "access_token" : UUID().uuidString,
                                "id" : "custom",
                                "refresh_token" : UUID().uuidString
                            ]
                        ],
                        "username" : UUID().uuidString,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : [
                            "lmt" : "2016-11-10T21:10:50.372Z",
                            "ect" : "2016-10-27T17:19:33.086Z",
                            "authtoken" : UUID().uuidString
                        ]
                    ]
                    let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                    client?.urlProtocol(self, didLoad: data)
                    
                    client?.urlProtocolDidFinishLoading(self)
                default:
                    XCTFail("URL Path not handled: \(request.url!.path)")
                }
            }
            
            override func stopLoading() {
            }
            
        }
        
        setURLProtocol(MockURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        do {
            weak var expectationDiscardLocalUser = expectation(description: "Discard Local User")
            appDelegate.discardLocalCachedUser { user, error in
                XCTAssertTrue(Thread.isMainThread)
                
                if let user = user {
                    user.logout()
                }
                
                expectationDiscardLocalUser?.fulfill()
            }
            
            waitForExpectations(timeout: 5) { error in
                expectationDiscardLocalUser = nil
            }
        }
        
        XCTAssertNil(Kinvey.sharedClient.activeUser)
        
        appDelegate.initializeKinvey()
        
        weak var expectationFetchUser = expectation(description: "Fetch User")
        
        appDelegate.completionHandler = { user, error in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            XCTAssertNotNil(Kinvey.sharedClient.activeUser)
            
            expectationFetchUser?.fulfill()
        }
        
        waitForExpectations(timeout: 10) { error in
            expectationFetchUser = nil
        }
    }
    
}
