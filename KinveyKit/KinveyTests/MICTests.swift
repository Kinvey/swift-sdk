//
//  MICTests.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-03-30.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import Foundation

class MICTests: XCTestCase {
    
    override func setUp() {
        KCSClient.sharedClient().initializeKinveyServiceForAppKey(
            "kid_WyYCSd34p",
            withAppSecret: "22a381bca79c407cb0efc6585aaed53e",
            usingOptions: nil
        )
    }
    
    func testValidURL() {
        XCTAssertTrue(KCSUser.isValidMICRedirectURI(
            "kinveyAuthDemo://",
            forURL: NSURL(string: "kinveyAuthDemo://?code=123")
        ))
    }
    
    func testValidURLDifferentURI() {
        XCTAssertFalse(KCSUser.isValidMICRedirectURI(
            "kinveyAuthDemo://",
            forURL: NSURL(string: "facebook://?code=123")
        ))
    }
    
    func testValidURLMutipleParams() {
        XCTAssertTrue(KCSUser.isValidMICRedirectURI(
            "kinveyAuthDemo://",
            forURL: NSURL(string: "kinveyAuthDemo://?type=kinvey_mic&code=123")
        ))
    }
    
    func testParseURLParams() {
        var params: NSDictionary?
        KCSUser2.isValidMICRedirectURI(
            "kinveyAuthDemo://",
            forURL: NSURL(string: "kinveyAuthDemo://?type=kinvey_mic&code=123"),
            params: &params
        )
        XCTAssertEqual(params!.count, 2)
        XCTAssertEqual(params!["code"] as String, "123")
        XCTAssertEqual(params!["type"] as String, "kinvey_mic")
    }
    
    func testAuthCodeApi() {
        let expectation = expectationWithDescription("login")
        
        KCSUser.loginWithMICRedirectURI(
            "kinveyAuthDemo://",
            authorizationGrantType: .AuthCodeAPI,
            options: [
                KCSUsername : "mjs",
                KCSPassword : "demo"
            ]
        ) { (user: KCSUser!, error: NSError!, userActionResult: KCSUserActionResult) -> Void in
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            XCTAssertNotNil(user.userId)
            XCTAssertNotNil(user.username)
            XCTAssertNotNil(user.userAttributes)
            
            let socialIdentity = user.userAttributes["_socialIdentity"] as NSDictionary
            
            XCTAssertNotNil(socialIdentity)
            
            let kinveyAuth = socialIdentity["kinveyAuth"] as NSDictionary
            
            XCTAssertNotNil(kinveyAuth)
            XCTAssertNotNil(kinveyAuth["access_token"])
            XCTAssertNotNil(kinveyAuth["audience"])
            XCTAssertNotNil(kinveyAuth["client_token"])
            XCTAssertNotNil(kinveyAuth["refresh_token"])
            XCTAssertNotNil(kinveyAuth["id"])
            XCTAssertEqual(kinveyAuth["id"] as String, "mjs")
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(30, handler: nil)
    }
    
    func testRefreshToken() {
        let expectationLogin = expectationWithDescription("login")
        
        KCSUser.loginWithMICRedirectURI(
            "kinveyAuthDemo://",
            authorizationGrantType: .AuthCodeAPI,
            options: [
                KCSUsername : "mjs",
                KCSPassword : "demo"
            ]
            ) { (user: KCSUser!, error: NSError!, userActionResult: KCSUserActionResult) -> Void in
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationLogin.fulfill()
        }
        
        waitForExpectationsWithTimeout(30, handler: nil)
        
        class MockURLProtocol: NSURLProtocol {
            
            struct Static {
                
                static var canHandleRequest = true
                
            }
            
            override class func canInitWithRequest(request: NSURLRequest) -> Bool {
                let canHandleRequest = Static.canHandleRequest
                return canHandleRequest
            }
            
            override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
                return request
            }
            
            private override func startLoading() {
                let data = NSJSONSerialization.dataWithJSONObject([ "error" : "ExpiredToken" ], options: NSJSONWritingOptions.allZeros, error: nil)!
                let headers = [
                    "Content-Type" : "application/json; charset=utf-8",
                    "Content-Length" : String(data.length),
                    "X-Powered-By" : "Express"
                ];
                let response = NSHTTPURLResponse(URL: request.URL, statusCode: 401, HTTPVersion: "1.1", headerFields: headers)!
                
                client!.URLProtocol(
                    self,
                    didReceiveResponse: response,
                    cacheStoragePolicy: .NotAllowed
                )
                
                client!.URLProtocol(
                    self,
                    didLoadData: data
                )
                
                client!.URLProtocolDidFinishLoading(self)
                
                Static.canHandleRequest = false
            }
            
        }
        
        KCSURLProtocol.registerClass(MockURLProtocol)
        
        let collection = KCSCollection(fromString: "person", ofClass: NSMutableDictionary.self)
        let store = KCSCachedStore(collection: collection, options: [
            KCSStoreKeyCachePolicy : KCSCachePolicy.LocalFirst.rawValue,
            KCSStoreKeyOfflineUpdateEnabled : true
        ])
        
        let expectationSave = expectationWithDescription("save")
        
        store.saveObject(
            [ "name" : "Victor" ],
            withCompletionBlock: { (results: [AnyObject]!, error: NSError!) -> Void in
                XCTAssertNil(error)
                XCTAssertNotNil(results)
                
                expectationSave.fulfill()
            },
            withProgressBlock: nil
        )
        
        waitForExpectationsWithTimeout(60, handler: { (error: NSError!) -> Void in
            KCSURLProtocol.unregisterClass(MockURLProtocol)
        })
    }
    
}
