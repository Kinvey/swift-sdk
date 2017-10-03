//
//  SSOApp1Tests.swift
//  SSOApp1Tests
//
//  Created by Victor Hugo on 2016-11-10.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
import Foundation
import WebKit
@testable import Kinvey
@testable import SSOApp1

class SSOApp1Tests: KinveyTestCase {
    
    override func setUp() {
        UIApplication.shared.keyWindow?.layer.speed = 1
    }
    
    override func tearDown() {
        UIApplication.shared.keyWindow?.layer.speed = 1
    }
    
    func testLogin() {
        class MockURLProtocol: URLProtocol {
            
            static let regexRedirectUri = try! NSRegularExpression(pattern: "redirect_uri=([^&]*)")
            let regexRedirectUri: NSRegularExpression = MockURLProtocol.regexRedirectUri
            
            static var appKey: String?
            
            override class func canInit(with request: URLRequest) -> Bool {
                if let url = request.url {
                    return url.scheme == "https" && (url.host == "auth.kinvey.com" || url.host == "baas.kinvey.com")
                }
                return false
            }
            
            override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                switch request.url!.path {
                case "/v3/oauth/login":
                    let requestBody = String(data: request.httpBody!, encoding: .utf8)!
                    let textCheckingResult = regexRedirectUri.matches(in: requestBody, range: NSMakeRange(0, requestBody.characters.count)).first!
                    let range = textCheckingResult.range(at: 1)
                    let redirectUri = requestBody[requestBody.index(requestBody.startIndex, offsetBy: range.location)...requestBody.index(requestBody.startIndex, offsetBy: range.location + range.length - 1)].removingPercentEncoding!
                    let url = URL(string: "\(redirectUri)?code=\(UUID().uuidString)")!
                    return URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 30)
                default:
                    return request
                }
            }
            
            override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
                return false
            }
            
            override func startLoading() {
                if request.url!.scheme != "https" && request.url!.scheme != "http" {
                    return
                }
                switch request.url!.path {
                case "/v3/oauth/auth":
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: [:])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    
                    let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                    XCTAssertNotNil(urlComponents.queryItems)
                    if let queryItems = urlComponents.queryItems {
                        let clientId = queryItems.filter { $0.name == "client_id" }.first?.value
                        XCTAssertNotNil(clientId)
                        if let clientId = clientId {
                            XCTAssertTrue(clientId.contains("."))
                            let regex = try? NSRegularExpression(pattern: "([^:]+).([^:]+)")
                            XCTAssertNotNil(regex)
                            if let regex = regex {
                                let match = regex.firstMatch(in: clientId, range: NSMakeRange(0, clientId.characters.count))
                                XCTAssertNotNil(match)
                                if let match = match {
                                    XCTAssertEqual(match.numberOfRanges, 3)
                                    let appKey = clientId.substring(with: match.range(at: 1))
                                    XCTAssertNotNil(appKey)
                                    XCTAssertFalse(appKey.isEmpty)
                                    
                                    let clientIdValue = clientId.substring(with: match.range(at: 1))
                                    XCTAssertNotNil(clientIdValue)
                                    XCTAssertFalse(clientIdValue.isEmpty)
                                }
                            }
                        }
                    }
                    
                    let url = Bundle(for: SSOApp1Tests.self).url(forResource: "auth", withExtension: "html")!
                    let data = try! Data(contentsOf: url)
                    var html = String(data: data, encoding: .utf8)!
                    let requestUrlQuery = request.url!.query!
                    let textCheckingResult = regexRedirectUri.matches(in: requestUrlQuery, range: NSMakeRange(0, requestUrlQuery.characters.count)).first!
                    let range = textCheckingResult.range(at: 1)
                    let redirectUri = requestUrlQuery[requestUrlQuery.index(requestUrlQuery.startIndex, offsetBy: range.location)...requestUrlQuery.index(requestUrlQuery.startIndex, offsetBy: range.location + range.length - 1)].removingPercentEncoding!
                    html = html.replacingOccurrences(of: "@redirect_uri@", with: redirectUri)
                    client?.urlProtocol(self, didLoad: html.data(using: .utf8)!)
                    
                    client?.urlProtocolDidFinishLoading(self)
                case "/v3/oauth/token":
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    
                    let json = [
                        "access_token" : UUID().uuidString,
                        "token_type" : "bearer",
                        "expires_in" : 3599,
                        "refresh_token" : UUID().uuidString
                    ] as [String : Any]
                    let data = try! JSONSerialization.data(withJSONObject: json)
                    client?.urlProtocol(self, didLoad: data)
                    
                    client?.urlProtocolDidFinishLoading(self)
                case "/user/\(MockURLProtocol.appKey ?? "")/login":
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    
                    let json = [
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
                    ] as [String : Any]
                    let data = try! JSONSerialization.data(withJSONObject: json)
                    client?.urlProtocol(self, didLoad: data)
                    
                    client?.urlProtocolDidFinishLoading(self)
                case "/user/\(MockURLProtocol.appKey ?? "")/_logout":
                    let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: "1.1", headerFields: [:])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    client?.urlProtocol(self, didLoad: Data())
                    client?.urlProtocolDidFinishLoading(self)
                default:
                    XCTFail("URL Path not handled: \(request.url!.path)")
                }
            }
            
            override func stopLoading() {
            }
            
        }
        
        MockURLProtocol.appKey = Kinvey.sharedClient.appKey
        setURLProtocol(MockURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        guard let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController,
            let viewController = navigationController.topViewController as? ViewController else
        {
            XCTFail()
            return
        }
        
        viewController.micUserInterface = .uiWebView
        
        let signInButtonIdentifier = "Sign In"
        XCTAssertTrue(waitForCondition(self.tester().tryFindingView(withAccessibilityIdentifier: signInButtonIdentifier), timeout: 30))
        
        if Kinvey.sharedClient.activeUser != nil {
            tester().tapView(withAccessibilityIdentifier: signInButtonIdentifier)
            tester().waitForAnimationsToFinish()
            
            XCTAssertNil(Kinvey.sharedClient.activeUser)
        }
        
        tester().tapView(withAccessibilityIdentifier: signInButtonIdentifier)
        
        tester().waitForAnimationsToFinish()
        
        if let navigationController2 = navigationController.presentedViewController as? UINavigationController,
            let micViewController = navigationController2.topViewController as? Kinvey.MICLoginViewController,
            let webView = micViewController.value(forKey: "webView") as? UIWebView
        {
            weak var expectationLogin = expectation(description: "Login")
            
            viewController.completionHandler = { (user, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                XCTAssertNotNil(Kinvey.sharedClient.activeUser)
                
                expectationLogin?.fulfill()
            }
            
            tester().waitForAnimationsToFinish()
            
            webView.stringByEvaluatingJavaScript(from: "document.getElementsByName('username')[0].value = 'custom'")
            
            tester().waitForAnimationsToFinish()
            
            webView.stringByEvaluatingJavaScript(from: "document.getElementsByName('password')[0].value = '1234'")
            
            tester().waitForAnimationsToFinish()
            
            webView.stringByEvaluatingJavaScript(from: "document.getElementsByTagName('form')[0].submit()")
            
            tester().waitForAnimationsToFinish()
            
            waitForExpectations(timeout: 30) { error in
                expectationLogin = nil
            }
        } else {
            XCTFail()
        }
    }
    
}
