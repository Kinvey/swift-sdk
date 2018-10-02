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
    
    let defaultTimeout: TimeInterval = 60
        
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
        
        XCTContext.runActivity(named: "Launch App") { activity in
            app.launch()
            activity.add(XCTAttachment(screenshot: app.screenshot()))
        }
        
        XCTContext.runActivity(named: "Open MIC Login") { activity in
            app.staticTexts["MIC Login"].tap()
            activity.add(XCTAttachment(screenshot: app.screenshot()))
        }
        
        XCTContext.runActivity(named: "Tap SFAuthenticationSession switcher") { activity in
            app.switches["SFAuthenticationSession"].tap()
            activity.add(XCTAttachment(screenshot: app.screenshot()))
        }
        
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
        XCTContext.runActivity(named: "Server Setup") { _ in
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
                XCTFail("Handler was not expected to be called")
                return .notFound
            }
            try! server.start(port, forceIPv4: true)
            expect(server.state == .running).toEventually(beTrue(), timeout: defaultTimeout)
        }
        defer {
            server.stop()
        }
        
        let userIdValue = app.staticTexts["User ID Value"]
        expect(userIdValue.exists).to(beTrue())
        
        XCTContext.runActivity(named: "Tap Login Button") { activity in
            let tokenMonitor = addUIInterruptionMonitor(withDescription: "SFAuthenticationSession") { (alert) -> Bool in
                expect(userIdValue.exists).to(beTrue())
                alert.buttons["Continue"].tap()
                expect(userIdValue.exists).toEventually(beFalse(), timeout: self.defaultTimeout)
                activity.add(XCTAttachment(screenshot: app.screenshot()))
                expect(userIdValue.exists).toEventually(beTrue(), timeout: self.defaultTimeout)
                return true
            }
            defer {
                removeUIInterruptionMonitor(tokenMonitor)
            }
            
            activity.add(XCTAttachment(screenshot: app.screenshot()))
            
            app.buttons["Login"].tap()
            app.tap()
            
            activity.add(XCTAttachment(screenshot: app.screenshot()))
            
            expect(userIdValue.exists).toEventually(beTrue(), timeout: defaultTimeout)
            expect(userIdValue.label).toEventually(equal(userId), timeout: defaultTimeout)
        }
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
            XCTFail("A handler for the request could not be found. Request: \(request)")
            return .notFound
        }
        try! server.start(port, forceIPv4: true)
        expect(server.state == .running).toEventually(beTrue(), timeout: defaultTimeout)
        
        defer {
            server.stop()
        }
        
        let userIdValue = app.staticTexts["User ID Value"]
        
        addUIInterruptionMonitor(withDescription: "WKWebView") { (alert) -> Bool in
            expect(userIdValue.exists).to(beTrue())
            alert.buttons["Continue"].tap()
            expect(userIdValue.exists).toEventually(beFalse(), timeout: self.defaultTimeout)
            expect(userIdValue.exists).toEventually(beTrue(), timeout: self.defaultTimeout)
            return true
        }
        
        app.buttons["Login"].tap()
        app.tap()
        
        XCTAssertTrue(userIdValue.waitForExistence(timeout: defaultTimeout))
        expect(userIdValue.exists).toEventually(beTrue(), timeout: defaultTimeout)
        expect(userIdValue.label).toEventually(equal(userId), timeout: defaultTimeout)
    }
    
}
