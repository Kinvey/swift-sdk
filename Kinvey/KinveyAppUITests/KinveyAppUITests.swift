//
//  KinveyAppUITests.swift
//  KinveyAppUITests
//
//  Created by Victor Hugo Carvalho Barros on 2017-10-02.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
import Swifter
import Nimble

extension XCUIElement {
    
    func clearAndTypeText(text: String) {
        guard let stringValue = value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        
        tap()
        
        let deleteString = stringValue.map { _ in XCUIKeyboardKey.delete.rawValue }.joined()
        
        typeText(deleteString)
        typeText(text)
    }
    
}

extension RunLoop {
    
    func run(timeIntervalSinceNow: TimeInterval) {
        run(until: Date(timeIntervalSinceNow: timeIntervalSinceNow))
    }
    
}

class KinveyAppUITests: XCTestCase {
        
    func testMICLoginSafariAuthenticationSession() {
        let app = XCUIApplication()
        let kid = "_kid_"
        let port: in_port_t = 8080
        app.launchEnvironment = [
            "KINVEY_MIC_APP_KEY" : kid,
            "KINVEY_MIC_APP_SECRET" : "_secret_",
            "KINVEY_MIC_API_URL" : "http://localhost:\(port)",
            "KINVEY_MIC_AUTH_URL" : "http://localhost:\(port)",
        ]
        app.launch()
        
        app.staticTexts["MIC Login"].tap()
        app.switches["SFAuthenticationSession"].tap()
        
        let code = UUID().uuidString
        let userId = UUID().uuidString
        let json = [
            "_id" : userId,
            "username" : UUID().uuidString,
            "_kmd" : [
                "lmt" : "2017-09-05T16:48:35.667Z",
                "ect" : "2017-09-05T16:48:35.667Z",
                "authtoken" : UUID().uuidString
            ],
            "_acl" : [
                "creator" : UUID().uuidString
            ]
        ] as [String : Any]
        
        let server = HttpServer()
        server["/:v/oauth/auth"] = { request in
            XCTAssertEqual(request.params[":v"], "v3")
            if let (_, redirectUri) = request.queryParams.filter({ key, value in key == "redirect_uri" }).first {
                return HttpResponse.raw(302, "Found", ["Location" : "\(redirectUri)?code=\(code)"], { bodyWriter in
                    try! bodyWriter.write("Redirecting...".data(using: .utf8)!)
                })
            }
            return .internalServerError
        }
        server["/:v/oauth/token"] = { request in
            XCTAssertEqual(request.params[":v"], "v3")
            if let (_, _code) = request.parseUrlencodedForm().filter({ key, value in key == "code" }).first, code == _code {
                return .ok(.json([
                    "access_token" : UUID().uuidString,
                    "token_type" : "Bearer",
                    "expires_in" : 3599,
                    "refresh_token" : UUID().uuidString
                ] as AnyObject))
            }
            return .internalServerError
        }
        server.post["/user/:kid/login"] = { request in
            XCTAssertEqual(request.params[":kid"], kid)
            return .ok(.json(json as AnyObject))
        }
        server.notFoundHandler = { request in
            XCTFail()
            return .notFound
        }
        try! server.start(port, forceIPv4: true)
        
        defer {
            server.stop()
        }
        
        let tokenMonitor = addUIInterruptionMonitor(withDescription: "SFAuthenticationSession") { (alert) -> Bool in
            alert.buttons["Continue"].tap()
            return true
        }
        defer {
            removeUIInterruptionMonitor(tokenMonitor)
        }
        
        app.buttons["Login"].tap()
        app.tap()
        
        let userIdValue = app.staticTexts["User ID Value"]
        expect(expression: {
            if userIdValue.exists {
                app.tap()
            }
            return userIdValue.exists
        }).toEventually(beFalse(), timeout: 10, pollInterval: 1)
        expect(userIdValue.exists).toEventually(beTrue(), timeout: 30)
        expect(userIdValue.label).toEventually(equal(userId), timeout: 10)
    }
    
    func testMICLoginWKWebView() {
        let app = XCUIApplication()
        let kid = "_kid_"
        let port: in_port_t = 8080
        app.launchEnvironment = [
            "KINVEY_MIC_APP_KEY" : kid,
            "KINVEY_MIC_APP_SECRET" : "_secret_",
            "KINVEY_MIC_API_URL" : "http://localhost:\(port)",
            "KINVEY_MIC_AUTH_URL" : "http://localhost:\(port)",
        ]
        app.launch()
        
        app.staticTexts["MIC Login"].tap()
        app.switches["WKWebView"].tap()
        
        let code = UUID().uuidString
        let userId = UUID().uuidString
        let json = [
            "_id" : userId,
            "username" : UUID().uuidString,
            "_kmd" : [
                "lmt" : "2017-09-05T16:48:35.667Z",
                "ect" : "2017-09-05T16:48:35.667Z",
                "authtoken" : UUID().uuidString
            ],
            "_acl" : [
                "creator" : UUID().uuidString
            ]
        ] as [String : Any]
        
        let server = HttpServer()
        server["/:v/oauth/auth"] = { request in
            XCTAssertEqual(request.params[":v"], "v3")
            if let (_, redirectUri) = request.queryParams.filter({ key, value in key == "redirect_uri" }).first {
                return HttpResponse.raw(302, "Found", ["Location" : "\(redirectUri)?code=\(code)"], { bodyWriter in
                    try! bodyWriter.write("Redirecting...".data(using: .utf8)!)
                })
            }
            return .internalServerError
        }
        server["/:v/oauth/token"] = { request in
            XCTAssertEqual(request.params[":v"], "v3")
            if let (_, _code) = request.parseUrlencodedForm().filter({ key, value in key == "code" }).first, code == _code {
                return .ok(.json([
                    "access_token" : UUID().uuidString,
                    "token_type" : "Bearer",
                    "expires_in" : 3599,
                    "refresh_token" : UUID().uuidString
                ] as AnyObject))
            }
            return .internalServerError
        }
        server.post["/user/:kid/login"] = { request in
            XCTAssertEqual(request.params[":kid"], kid)
            return .ok(.json(json as AnyObject))
        }
        server.notFoundHandler = { request in
            XCTFail()
            return .notFound
        }
        try! server.start(port, forceIPv4: true)
        
        defer {
            server.stop()
        }
        
        addUIInterruptionMonitor(withDescription: "WKWebView") { (alert) -> Bool in
            alert.buttons["Continue"].tap()
            return true
        }
        
        app.buttons["Login"].tap()
        app.tap()
        
        let userIdValue = app.staticTexts["User ID Value"]
        expect(expression: {
            if userIdValue.exists {
                app.tap()
            }
            return userIdValue.exists
        }).toEventually(beFalse(), timeout: 10, pollInterval: 1)
        expect(userIdValue.exists).toEventually(beTrue(), timeout: 30)
        expect(userIdValue.label).toEventually(equal(userId), timeout: 10)
    }
    
}
