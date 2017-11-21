//
//  KinveyAppUITests.swift
//  KinveyAppUITests
//
//  Created by Victor Hugo Carvalho Barros on 2017-10-02.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
import Swifter

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

class KinveyAppUITests: XCTestCase {
        
    func testMICLoginSafariAuthenticationSession() {
        let app = XCUIApplication()
        let kid = "_kid_"
        app.launchEnvironment = [
            "KINVEY_MIC_APP_KEY" : kid,
            "KINVEY_MIC_APP_SECRET" : "_secret_",
            "KINVEY_MIC_API_URL" : "http://localhost:8080",
            "KINVEY_MIC_AUTH_URL" : "http://localhost:8080",
        ]
        app.launch()
        
        app.staticTexts["MIC Login"].tap()
        app.switches["SFAuthenticationSession"].tap()
        
        addUIInterruptionMonitor(withDescription: "SFAuthenticationSession") { (alert) -> Bool in
            alert.buttons["Continue"].tap()
            return true
        }
        
        app.buttons["Login"].tap()
        app.tap()
        
        let code = UUID().uuidString
        let userId = UUID().uuidString
        
        let server = HttpServer()
        server["/v1/oauth/auth"] = { request in
            if let (_, redirectUri) = request.queryParams.filter({ key, value in key == "redirect_uri" }).first {
                return HttpResponse.raw(302, "Found", ["Location" : "\(redirectUri)?code=\(code)"], { bodyWriter in
                    try! bodyWriter.write("Redirecting...".data(using: .utf8)!)
                })
            }
            return .internalServerError
        }
        server["/v1/oauth/token"] = { request in
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
        server["/user/\(kid)/login"] = { request in
            return .ok(.json([
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
            ] as AnyObject))
        }
        try! server.start()
        
        defer {
            server.stop()
        }
        
        let userIdValue = app.staticTexts["User ID Value"]
        XCTAssertTrue(userIdValue.waitForExistence(timeout: 30))
        XCTAssertEqual(userIdValue.label, userId)
    }
    
}
