//
//  UserTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
import KIF
import WebKit
import KinveyApp
@testable import Kinvey

extension XCTestCase {
    func tester(file : String = __FILE__, _ line : Int = __LINE__) -> KIFUITestActor {
        return KIFUITestActor(inFile: file, atLine: line, delegate: self)
    }
    
    func system(file : String = __FILE__, _ line : Int = __LINE__) -> KIFSystemTestActor {
        return KIFSystemTestActor(inFile: file, atLine: line, delegate: self)
    }
}

extension KIFTestActor {
    func tester(file : String = __FILE__, _ line : Int = __LINE__) -> KIFUITestActor {
        return KIFUITestActor(inFile: file, atLine: line, delegate: self)
    }
    
    func system(file : String = __FILE__, _ line : Int = __LINE__) -> KIFSystemTestActor {
        return KIFSystemTestActor(inFile: file, atLine: line, delegate: self)
    }
}

class UserTests: KinveyTestCase {

    func testSignUp() {
        signUp()
    }
    
    func testSignUp404StatusCode() {
        class ErrorURLProtocol: NSURLProtocol {
            
            override class func canInitWithRequest(request: NSURLRequest) -> Bool {
                return true
            }
            
            override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
                return request
            }
            
            override func startLoading() {
                let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 404, HTTPVersion: "HTTP/1.1", headerFields: [:])!
                client!.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
                client!.URLProtocol(self, didLoadData: NSData())
                client!.URLProtocolDidFinishLoading(self)
            }
            
            override func stopLoading() {
            }
            
        }
        
        setURLProtocol(ErrorURLProtocol.self)
        
        signUp(false) { (user, error) -> Void in
            XCTAssertTrue(NSThread.isMainThread())
            XCTAssertNotNil(error)
            XCTAssertNil(user)
        }
    }
    
    func testSignUpTimeoutError() {
        setURLProtocol(TimeoutErrorURLProtocol.self)
        
        signUp(false) { (user, error) -> Void in
            XCTAssertTrue(NSThread.isMainThread())
            XCTAssertNotNil(error)
            XCTAssertNil(user)
        }
    }
    
    func testSignUpWithUsernameAndPassword() {
        let username = NSUUID().UUIDString
        let password = NSUUID().UUIDString
        signUp(username: username, password: password)
    }
    
    func testSignUpAndDestroy() {
        signUp()
        
        if let user = client.activeUser {
            weak var expectationDestroyUser = expectationWithDescription("Destroy User")
            
            user.destroy(client: client, completionHandler: { (error) -> Void in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                
                expectationDestroyUser?.fulfill()
            })
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationDestroyUser = nil
            }
            
            XCTAssertNil(client.activeUser)
        }
    }
    
    func testSignUpAndDestroyHard() {
        signUp()
        
        if let user = client.activeUser {
            weak var expectationDestroyUser = expectationWithDescription("Destroy User")
            
            user.destroy(hard: true, completionHandler: { (error) -> Void in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                
                expectationDestroyUser?.fulfill()
            })
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationDestroyUser = nil
            }
            
            XCTAssertNil(client.activeUser)
        }
    }
    
    func testSignUpAndDestroyClassFunc() {
        signUp()
        
        if let user = client.activeUser {
            weak var expectationDestroyUser = expectationWithDescription("Destroy User")
            
            User.destroy(userId: user.userId, completionHandler: { (error) -> Void in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                
                expectationDestroyUser?.fulfill()
            })
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationDestroyUser = nil
            }
            
            XCTAssertNil(client.activeUser)
        }
    }
    
    func testSignUpAndDestroyHardClassFunc() {
        signUp()
        
        if let user = client.activeUser {
            weak var expectationDestroyUser = expectationWithDescription("Destroy User")
            
            User.destroy(userId: user.userId, hard: true, completionHandler: { (error) -> Void in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                
                expectationDestroyUser?.fulfill()
            })
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationDestroyUser = nil
            }
            
            XCTAssertNil(client.activeUser)
        }
    }
    
    func testSignUpAndDestroyClientClassFunc() {
        signUp()
        
        if let user = client.activeUser {
            weak var expectationDestroyUser = expectationWithDescription("Destroy User")
            
            User.destroy(userId: user.userId, client: client, completionHandler: { (error) -> Void in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                
                expectationDestroyUser?.fulfill()
            })
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationDestroyUser = nil
            }
            
            XCTAssertNil(client.activeUser)
        }
    }
    
    func testGet() {
        signUp()
        
        if let user = client.activeUser {
            weak var expectationUserExists = expectationWithDescription("User Exists")
            
            User.get(userId: user.userId, completionHandler: { (user, error) -> Void in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationUserExists?.fulfill()
            })
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationUserExists = nil
            }
        }
    }
    
    func testGetTimeoutError() {
        signUp()
        
        if let user = client.activeUser {
            setURLProtocol(TimeoutErrorURLProtocol.self)
            
            weak var expectationUserExists = expectationWithDescription("User Exists")
            
            User.get(userId: user.userId, completionHandler: { (user, error) -> Void in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNotNil(error)
                XCTAssertNil(user)
                
                expectationUserExists?.fulfill()
            })
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationUserExists = nil
            }
        }
    }
    
    func testSave() {
        class MyUser: User {
            
            var foo: String?
            
            required init?(json: [String : AnyObject], client: Client) {
                super.init(json: json, client: client)
                foo = json["foo"] as? String
            }
            
            private override func toJson() -> [String : AnyObject] {
                var json = super.toJson()
                if let foo = foo {
                    json["foo"] = foo
                }
                return json
            }
            
        }
        
        client.userType = MyUser.self
        
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        XCTAssertTrue(client.activeUser is MyUser)
        
        if let user = client.activeUser as? MyUser {
            weak var expectationUserSave = expectationWithDescription("User Save")
            
            user.foo = "bar"
            
            user.save { (user, error) -> Void in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                XCTAssertTrue(user is MyUser)
                if let myUser = user as? MyUser {
                    XCTAssertEqual(myUser.foo, "bar")
                }

                expectationUserSave?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationUserSave = nil
            }
        }
    }
    
    func testSaveTimeoutError() {
        class MyUser: User {
            
            var foo: String?
            
            required init?(json: [String : AnyObject], client: Client) {
                super.init(json: json, client: client)
                foo = json["foo"] as? String
            }
            
            private override func toJson() -> [String : AnyObject] {
                var json = super.toJson()
                if let foo = foo {
                    json["foo"] = foo
                }
                return json
            }
            
        }
        
        client.userType = MyUser.self
        
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        XCTAssertTrue(client.activeUser is MyUser)
        
        if let user = client.activeUser as? MyUser {
            setURLProtocol(TimeoutErrorURLProtocol.self)
            
            weak var expectationUserSave = expectationWithDescription("User Save")
            
            user.foo = "bar"
            
            user.save { (user, error) -> Void in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNotNil(error)
                XCTAssertNil(user)
                
                expectationUserSave?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationUserSave = nil
            }
        }
    }
    
    func testLogoutLogin() {
        let username = NSUUID().UUIDString
        let password = NSUUID().UUIDString
        signUp(username: username, password: password)
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            user.logout()
            
            XCTAssertNil(client.activeUser)
            
            weak var expectationUserLogin = expectationWithDescription("User Login")
            
            User.login(username: username, password: password) { user, error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationUserLogin?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationUserLogin = nil
            }
        }
    }
    
    func testLogoutLoginTimeoutError() {
        let username = NSUUID().UUIDString
        let password = NSUUID().UUIDString
        signUp(username: username, password: password)
        defer {
            weak var expectationUserLogin = expectationWithDescription("User Login")
            
            User.login(username: username, password: password) { user, error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationUserLogin?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationUserLogin = nil
            }
            
            if let activeUser = client.activeUser {
                weak var expectationDestroy = expectationWithDescription("Destroy")
                
                activeUser.destroy { (error) -> Void in
                    XCTAssertTrue(NSThread.isMainThread())
                    XCTAssertNil(error)
                    
                    expectationDestroy?.fulfill()
                }
                
                waitForExpectationsWithTimeout(defaultTimeout) { error in
                    expectationDestroy = nil
                }
            }
        }
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            user.logout()
            
            XCTAssertNil(client.activeUser)
            
            setURLProtocol(TimeoutErrorURLProtocol.self)
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationUserLogin = expectationWithDescription("User Login")
            
            User.login(username: username, password: password) { user, error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNotNil(error)
                XCTAssertNil(user)
                
                expectationUserLogin?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationUserLogin = nil
            }
        }
    }
    
    func testLogoutLogin200ButInvalidResponseError() {
        let username = NSUUID().UUIDString
        let password = NSUUID().UUIDString
        signUp(username: username, password: password)
        defer {
            weak var expectationUserLogin = expectationWithDescription("User Login")
            
            User.login(username: username, password: password) { user, error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationUserLogin?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationUserLogin = nil
            }
            
            if let activeUser = client.activeUser {
                weak var expectationDestroy = expectationWithDescription("Destroy")
                
                activeUser.destroy { (error) -> Void in
                    XCTAssertTrue(NSThread.isMainThread())
                    XCTAssertNil(error)
                    
                    expectationDestroy?.fulfill()
                }
                
                waitForExpectationsWithTimeout(defaultTimeout) { error in
                    expectationDestroy = nil
                }
            }
        }
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            user.logout()
            
            XCTAssertNil(client.activeUser)
            
            class InvalidUserResponseErrorURLProtocol: NSURLProtocol {
                
                override class func canInitWithRequest(request: NSURLRequest) -> Bool {
                    return true
                }
                
                override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
                    return request
                }
                
                override func startLoading() {
                    let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json"])!
                    client!.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
                    let data = try! NSJSONSerialization.dataWithJSONObject(["userId":"123"], options: [])
                    client!.URLProtocol(self, didLoadData: data)
                    client!.URLProtocolDidFinishLoading(self)
                }
                
                override func stopLoading() {
                }
                
            }
            
            setURLProtocol(InvalidUserResponseErrorURLProtocol.self)
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationUserLogin = expectationWithDescription("User Login")
            
            User.login(username: username, password: password) { user, error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNotNil(error)
                XCTAssertNil(user)
                
                expectationUserLogin?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationUserLogin = nil
            }
        }
    }
    
    func testExists() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            XCTAssertNotNil(user.username)
            
            if let username = user.username {
                weak var expectationUserExists = expectationWithDescription("User Exists")
                
                User.exists(username: username) { (exists, error) -> Void in
                    XCTAssertTrue(NSThread.isMainThread())
                    XCTAssertNil(error)
                    XCTAssertTrue(exists)
                    
                    expectationUserExists?.fulfill()
                }
                
                waitForExpectationsWithTimeout(defaultTimeout) { error in
                    expectationUserExists = nil
                }
            }
        }
    }
    
    func testExistsTimeoutError() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            XCTAssertNotNil(user.username)
            
            if let username = user.username {
                setURLProtocol(TimeoutErrorURLProtocol.self)
                
                weak var expectationUserExists = expectationWithDescription("User Exists")
                
                User.exists(username: username) { (exists, error) -> Void in
                    XCTAssertTrue(NSThread.isMainThread())
                    XCTAssertNotNil(error)
                    XCTAssertFalse(exists)
                    
                    expectationUserExists?.fulfill()
                }
                
                waitForExpectationsWithTimeout(defaultTimeout) { error in
                    expectationUserExists = nil
                }
            }
        }
    }
    
    func testDestroyTimeoutError() {
        signUp()
        
        setURLProtocol(TimeoutErrorURLProtocol.self)
        
        if let activeUser = client.activeUser {
            weak var expectationDestroy = expectationWithDescription("Destroy")
            
            activeUser.destroy { (error) -> Void in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNotNil(error)
                
                expectationDestroy?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationDestroy = nil
            }
        }
    }
    
    func testResetPasswordByEmail() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            user.email = "\(user.username)@kinvey.com"
            
            weak var expectationSave = expectationWithDescription("Save")
            
            user.save() { user, error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationSave?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationSave = nil
            }
            
            class Mock204URLProtocol: NSURLProtocol {
                
                override class func canInitWithRequest(request: NSURLRequest) -> Bool {
                    return true
                }
                
                override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
                    return request
                }
                
                private override func startLoading() {
                    let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 204, HTTPVersion: "HTTP/1.1", headerFields: [:])!
                    client!.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
                    client!.URLProtocol(self, didLoadData: NSData())
                    client!.URLProtocolDidFinishLoading(self)
                }
                
                private override func stopLoading() {
                }
                
            }
            
            setURLProtocol(Mock204URLProtocol.self)
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationResetPassword = expectationWithDescription("Reset Password")
            
            user.resetPassword { error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                
                expectationResetPassword?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationResetPassword = nil
            }
        }
    }
    
    func testResetPasswordByUsername() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            weak var expectationResetPassword = expectationWithDescription("Reset Password")
            
            user.resetPassword { error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                
                expectationResetPassword?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationResetPassword = nil
            }
        }
    }
    
    func testResetPasswordNoEmailOrUsername() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            user.username = nil
            
            weak var expectationSave = expectationWithDescription("Save")
            
            user.save() { user, error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationSave?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationSave = nil
            }
            
            weak var expectationResetPassword = expectationWithDescription("Reset Password")
            
            user.resetPassword { error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNotNil(error)
                
                expectationResetPassword?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationResetPassword = nil
            }
        }
    }
    
    func testResetPasswordTimeoutError() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            weak var expectationSave = expectationWithDescription("Save")
            
            user.save() { user, error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationSave?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationSave = nil
            }
            
            setURLProtocol(TimeoutErrorURLProtocol.self)
            
            weak var expectationResetPassword = expectationWithDescription("Reset Password")
            
            user.resetPassword { error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNotNil(error)
                
                expectationResetPassword?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationResetPassword = nil
            }
        }
    }
    
    func testForgotUsername() {
        weak var expectationForgotUsername = expectationWithDescription("Forgot Username")
        
        User.forgotUsername(email: "\(NSUUID().UUIDString)@kinvey.com") { error in
            XCTAssertTrue(NSThread.isMainThread())
            XCTAssertNil(error)
            
            expectationForgotUsername?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationForgotUsername = nil
        }
    }
    
    func testForgotUsernameTimeoutError() {
        setURLProtocol(TimeoutErrorURLProtocol.self)
        
        weak var expectationForgotUsername = expectationWithDescription("Forgot Username")
        
        User.forgotUsername(email: "\(NSUUID().UUIDString)@kinvey.com") { error in
            XCTAssertTrue(NSThread.isMainThread())
            XCTAssertNotNil(error)
            
            expectationForgotUsername?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationForgotUsername = nil
        }
    }
    
    func testMICLoginWKWebView() {
        defer {
            if let user = client?.activeUser {
                user.logout()
            }
        }
        
        tester().tapViewWithAccessibilityIdentifier("MIC Login")
        defer {
            tester().tapViewWithAccessibilityLabel("Back")
        }
        tester().tapViewWithAccessibilityIdentifier("Login")
        
        tester().waitForAnimationsToFinish()
        tester().waitForTimeInterval(1)
        
        if let navigationController = UIApplication.sharedApplication().keyWindow?.rootViewController as? UINavigationController,
            let micLoginViewController = navigationController.topViewController as? MICLoginViewController,
            let navigationController2 = navigationController.presentedViewController as? UINavigationController,
            let micViewController = navigationController2.topViewController as? KCSMICLoginViewController
        {
            weak var expectationLogin: XCTestExpectation? = nil
            
            micLoginViewController.completionHandler = { (user, error) in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationLogin?.fulfill()
            }
            
            let webView = micViewController.valueForKey("webView") as? WKWebView
            XCTAssertNotNil(webView)
            if let webView = webView {
                weak var expectationTypeUsername = expectationWithDescription("Type Username")
                weak var expectationTypePassword = expectationWithDescription("Type Password")
                
                webView.evaluateJavaScript("document.getElementById('ping-username').value = 'ivan'", completionHandler: { (result, error) -> Void in
                    expectationTypeUsername?.fulfill()
                })
                webView.evaluateJavaScript("document.getElementById('ping-password').value = 'Zse45rfv'", completionHandler: { (result, error) -> Void in
                    expectationTypePassword?.fulfill()
                })
                
                waitForExpectationsWithTimeout(defaultTimeout) { error in
                    expectationTypeUsername = nil
                    expectationTypePassword = nil
                }
                
                weak var expectationSubmitForm = expectationWithDescription("Submit Form")
                
                webView.evaluateJavaScript("document.getElementById('userpass').submit()", completionHandler: { (result, error) -> Void in
                    expectationSubmitForm?.fulfill()
                })
                
                waitForExpectationsWithTimeout(defaultTimeout) { error in
                    expectationSubmitForm = nil
                }
            }
            
            expectationLogin = expectationWithDescription("Login")
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationLogin = nil
            }
        } else {
            XCTFail()
        }
    }
    
    func testMICLoginWKWebViewModal() {
        defer {
            if let user = client?.activeUser {
                user.logout()
            }
        }
        
        tester().tapViewWithAccessibilityIdentifier("MIC Login Modal")
        defer {
            if let navigationController = UIApplication.sharedApplication().keyWindow?.rootViewController as? UINavigationController,
                let micLoginViewController = navigationController.presentedViewController as? MICLoginViewController
            {
                micLoginViewController.performSegueWithIdentifier("back", sender: nil)
                tester().waitForAnimationsToFinish()
            }
        }
        tester().tapViewWithAccessibilityIdentifier("Login")
        
        tester().waitForAnimationsToFinish()
        tester().waitForTimeInterval(1)
        
        if let navigationController = UIApplication.sharedApplication().keyWindow?.rootViewController as? UINavigationController,
            let micLoginViewController = navigationController.presentedViewController as? MICLoginViewController,
            let navigationController2 = micLoginViewController.presentedViewController as? UINavigationController,
            let micViewController = navigationController2.topViewController as? KCSMICLoginViewController
        {
            weak var expectationLogin: XCTestExpectation? = nil
            
            micLoginViewController.completionHandler = { (user, error) in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationLogin?.fulfill()
            }
            
            let webView = micViewController.valueForKey("webView") as? WKWebView
            XCTAssertNotNil(webView)
            if let webView = webView {
                weak var expectationTypeUsername = expectationWithDescription("Type Username")
                weak var expectationTypePassword = expectationWithDescription("Type Password")
                
                webView.evaluateJavaScript("document.getElementById('ping-username').value = 'ivan'", completionHandler: { (result, error) -> Void in
                    expectationTypeUsername?.fulfill()
                })
                webView.evaluateJavaScript("document.getElementById('ping-password').value = 'Zse45rfv'", completionHandler: { (result, error) -> Void in
                    expectationTypePassword?.fulfill()
                })
                
                waitForExpectationsWithTimeout(defaultTimeout) { error in
                    expectationTypeUsername = nil
                    expectationTypePassword = nil
                }
                
                weak var expectationSubmitForm = expectationWithDescription("Submit Form")
                
                webView.evaluateJavaScript("document.getElementById('userpass').submit()", completionHandler: { (result, error) -> Void in
                    expectationSubmitForm?.fulfill()
                })
                
                waitForExpectationsWithTimeout(defaultTimeout) { error in
                    expectationSubmitForm = nil
                }
            }
            
            expectationLogin = expectationWithDescription("Login")
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationLogin = nil
            }
        } else {
            XCTFail()
        }
    }
    
    func testMICLoginUIWebView() {
        defer {
            if let user = client?.activeUser {
                user.logout()
            }
        }
        
        tester().tapViewWithAccessibilityIdentifier("MIC Login")
        defer {
            tester().tapViewWithAccessibilityLabel("Back")
        }
        
        tester().setOn(true, forSwitchWithAccessibilityIdentifier: "Force UIWebView Value")
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityIdentifier("Login")
        
        tester().waitForAnimationsToFinish()
        tester().waitForTimeInterval(1)
        
        if let navigationController = UIApplication.sharedApplication().keyWindow?.rootViewController as? UINavigationController,
            let micLoginViewController = navigationController.topViewController as? MICLoginViewController,
            let navigationController2 = navigationController.presentedViewController as? UINavigationController,
            let micViewController = navigationController2.topViewController as? KCSMICLoginViewController
        {
            weak var expectationLogin: XCTestExpectation? = nil
            
            micLoginViewController.completionHandler = { (user, error) in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationLogin?.fulfill()
            }
            
            let webView = micViewController.valueForKey("webView") as? UIWebView
            XCTAssertNotNil(webView)
            if let webView = webView {
                webView.stringByEvaluatingJavaScriptFromString("document.getElementById('ping-username').value = 'ivan'")
                webView.stringByEvaluatingJavaScriptFromString("document.getElementById('ping-password').value = 'Zse45rfv'")
                webView.stringByEvaluatingJavaScriptFromString("document.getElementById('userpass').submit()")
            }
            
            expectationLogin = expectationWithDescription("Login")
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationLogin = nil
            }
        } else {
            XCTFail()
        }
    }
    
    func testMICLoginUIWebViewTimeoutError() {
        defer {
            if let user = client?.activeUser {
                user.logout()
            }
        }
        
        tester().tapViewWithAccessibilityIdentifier("MIC Login")
        defer {
            tester().tapViewWithAccessibilityLabel("Back")
        }
        
        tester().setOn(true, forSwitchWithAccessibilityIdentifier: "Force UIWebView Value")
        tester().waitForAnimationsToFinish()
        
        let registered = NSURLProtocol.registerClass(TimeoutErrorURLProtocol.self)
        defer {
            if registered {
                NSURLProtocol.unregisterClass(TimeoutErrorURLProtocol.self)
            }
        }
        
        if let navigationController = UIApplication.sharedApplication().keyWindow?.rootViewController as? UINavigationController,
            let micLoginViewController = navigationController.topViewController as? MICLoginViewController
        {
            weak var expectationLogin = expectationWithDescription("Login")
            
            micLoginViewController.completionHandler = { (user, error) in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNotNil(error)
                XCTAssertNil(user)
                
                expectationLogin?.fulfill()
            }
            
            tester().tapViewWithAccessibilityIdentifier("Login")
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationLogin = nil
            }
        } else {
            XCTFail()
        }
    }

}
