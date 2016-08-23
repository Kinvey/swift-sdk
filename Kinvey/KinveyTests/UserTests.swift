//
//  UserTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
import WebKit
import KinveyApp
@testable import Kinvey

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
        
        signUp(mustHaveAValidUserInTheEnd: false) { (user, error) -> Void in
            XCTAssertTrue(NSThread.isMainThread())
            XCTAssertNotNil(error)
            XCTAssertNil(user)
        }
    }
    
    func testSignUpTimeoutError() {
        setURLProtocol(TimeoutErrorURLProtocol.self)
        
        signUp(mustHaveAValidUserInTheEnd: false) { (user, error) -> Void in
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
        signUp(username: "tempUser", password: "tempPass")
        
        var userId:String = ""
        
        if let user = client.activeUser {
            userId = user.userId
            weak var expectationDestroyUser = expectationWithDescription("Destroy User")
            
            user.destroy(hard: false, completionHandler: { (error) -> Void in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                expectationDestroyUser?.fulfill()
            })
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationDestroyUser = nil
            }
            
            XCTAssertNil(client.activeUser)
        }
        
        signUp()

        if let _ = client.activeUser {
            weak var expectationFindDestroyedUser = expectationWithDescription("Find Destoyed User")
            
            User.get(userId: userId , completionHandler: { (user, error) in
                XCTAssertNil(user)
                XCTAssertNotNil(error)
                expectationFindDestroyedUser?.fulfill()
            })
            
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationFindDestroyedUser = nil
            }

        }

    }
    
    func testSignUpAndDestroyClassFunc() {
        signUp()
        
        if let user = client.activeUser {
            weak var expectationDestroyUser = expectationWithDescription("Destroy User")
            Client.sharedClient.logNetworkEnabled = true
            
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
    
    func testChangePassword() {
        signUp()
        
        XCTAssertNotNil(Kinvey.sharedClient.activeUser)
        
        guard let user = Kinvey.sharedClient.activeUser else {
            return
        }
        
        let store = DataStore<Person>.collection()
        
        do {
            weak var expectationFind = expectationWithDescription("Find")
            
            store.find(readPolicy: .ForceNetwork) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                expectationFind?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        do {
            client.logNetworkEnabled = true
            defer {
                client.logNetworkEnabled = false
            }
            
            weak var expectationChangePassword = expectationWithDescription("Change Password")
            
            user.changePassword(newPassword: "test") { user, error in
                XCTAssertNotNil(user)
                XCTAssertNil(error)
                
                expectationChangePassword?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationChangePassword = nil
            }
        }
        
        do {
            weak var expectationFind = expectationWithDescription("Find")
            
            store.find(readPolicy: .ForceNetwork) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                expectationFind?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationFind = nil
            }
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
    
    func testLookup() {
        let username = NSUUID().UUIDString
        let password = NSUUID().UUIDString
        let email = "\(username)@kinvey.com"
        signUp(username: username, password: password)
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            do {
                weak var expectationSave = expectationWithDescription("Save")
                
                user.email = email
                
                user.save() { user, error in
                    XCTAssertTrue(NSThread.isMainThread())
                    XCTAssertNil(error)
                    XCTAssertNotNil(user)
                    
                    expectationSave?.fulfill()
                }
                
                waitForExpectationsWithTimeout(defaultTimeout) { error in
                    expectationSave = nil
                }
            }
            
            do {
                client.logNetworkEnabled = true
                
                weak var expectationUserLookup = expectationWithDescription("User Lookup")
                
                let userQuery = UserQuery {
                    $0.username = username
                }
                
                user.lookup(userQuery) { users, error in
                    XCTAssertTrue(NSThread.isMainThread())
                    XCTAssertNotNil(users)
                    XCTAssertNil(error)
                    
                    if let users = users {
                        XCTAssertEqual(users.count, 1)
                        
                        if let user = users.first {
                            XCTAssertEqual(user.username, username)
                            XCTAssertEqual(user.email, email)
                        }
                    }
                    
                    expectationUserLookup?.fulfill()
                }
                
                waitForExpectationsWithTimeout(defaultTimeout) { error in
                    expectationUserLookup = nil
                }
                
                client.logNetworkEnabled = false
            }
        }
    }
    
    class MyUser: User {
        
        var foo: String?
        
        override func mapping(map: Map) {
            super.mapping(map)
            
            foo <- map["foo"]
        }
        
    }
    
    func testSave() {
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
            
            let userDefaults = NSUserDefaults.standardUserDefaults()
            XCTAssertNil(userDefaults.objectForKey(client.appKey!))
            
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
    
    func testSendEmailConfirmation() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            weak var expectationSave = expectationWithDescription("Save")
            
            user.email = "\(user.username!)@kinvey.com"
            
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
            
            weak var expectationSendEmailConfirmation = expectationWithDescription("Send Email Confirmation")
            
            user.sendEmailConfirmation { error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                
                expectationSendEmailConfirmation?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationSendEmailConfirmation = nil
            }
        }
    }
    
    func testResetPasswordByEmail() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            user.email = "\(user.username!)@kinvey.com"
            
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
    
    func testFacebookLogin() {
        class FakeFacebookSocialLoginURLProtocol: NSURLProtocol {
            
            override class func canInitWithRequest(request: NSURLRequest) -> Bool {
                return true
            }
            
            override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
                return request
            }
            
            override func startLoading() {
                let userId = "503bc9806065332d6f000005"
                let headers = [
                    "Location" : "https://baas.kinvey.com/user/:appKey/\(userId)",
                    "Content-Type" : "application/json"
                ]
                let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 201, HTTPVersion: "HTTP/1.1", headerFields: headers)!
                client!.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
                
                let jsonResponse = [
                    "_id": userId,
                    "username": "73abe64e-139e-4034-9f88-08e3d9e1e5f8",
                    "password": "a94fa673-993e-4770-ac64-af82e6ab02b7",
                    "_socialIdentity": [
                        "facebook": [
                            "id": "100004289534145",
                            "name": "Kois Steel",
                            "gender": "female",
                            "email": "kois.steel@testFB.net",
                            "birthday": "2012/08/20",
                            "location": "Cambridge, USA"
                        ]
                    ],
                    "_kmd": [
                        "lmt": "2012-08-27T19:24:47.975Z",
                        "ect": "2012-08-27T19:24:47.975Z",
                        "authtoken": "8d4c427d-51ee-4f0f-bd99-acd2192d43d2.Clii9/Pjq05g8C5rqQgQg9ty+qewsxlTjhgNjyt9Pn4="
                    ],
                    "_acl": [
                        "creator": "503bc9806065332d6f000005"
                    ]
                ]
                
                let data = try! NSJSONSerialization.dataWithJSONObject(jsonResponse, options: [])
                client!.URLProtocol(self, didLoadData: data)
                client!.URLProtocolDidFinishLoading(self)
            }
            
            override func stopLoading() {
            }
            
        }
        
        setURLProtocol(FakeFacebookSocialLoginURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFacebookLogin = expectationWithDescription("Facebook Login")
        
        let fakeFacebookData = [
            "access_token": "AAAD30ogoDZCYBAKS50rOwCxMR7tIX8F90YDyC3vp63j0IvyCU0MELE2QMLnsWXKo2LcRgwA51hFr1UUpqXkSHu4lCj4VZCIuGG7DHZAHuZArzjvzTZAwQ",
            "expires": "5105388"
        ]
        User.login(authSource: .Facebook, fakeFacebookData) { user, error in
            XCTAssertNotNil(user)
            XCTAssertNil(error)
            
            expectationFacebookLogin?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationFacebookLogin = nil
        }
        
        client.activeUser = nil
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
                var wait = true
                while wait {
                    weak var expectationWait = expectationWithDescription("Wait")
                    
                    webView.evaluateJavaScript("document.getElementById('ping-username').value", completionHandler: { (result, error) -> Void in
                        if let result = result where !(result is NSNull) {
                            wait = false
                        }
                        expectationWait?.fulfill()
                    })
                    
                    waitForExpectationsWithTimeout(defaultTimeout) { error in
                        expectationWait = nil
                    }
                }
                
                tester().waitForAnimationsToFinish()
                tester().waitForTimeInterval(1)
                
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
            
            find()
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
            
            tester().waitForAnimationsToFinish()
            tester().waitForTimeInterval(1)
            
            let webView = micViewController.valueForKey("webView") as? WKWebView
            XCTAssertNotNil(webView)
            if let webView = webView {
                var wait = true
                while wait {
                    weak var expectationWait = expectationWithDescription("Wait")
                    
                    webView.evaluateJavaScript("document.getElementById('ping-username').value", completionHandler: { (result, error) -> Void in
                        if let result = result where !(result is NSNull) {
                            wait = false
                        }
                        expectationWait?.fulfill()
                    })
                    
                    waitForExpectationsWithTimeout(defaultTimeout) { error in
                        expectationWait = nil
                    }
                }
                
                tester().waitForAnimationsToFinish()
                tester().waitForTimeInterval(1)
                
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
            
            find()
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
                var result: String?
                while result == nil {
                    result = webView.stringByEvaluatingJavaScriptFromString("document.getElementById('ping-username').value")
                }
                
                tester().waitForAnimationsToFinish()
                tester().waitForTimeInterval(1)
                
                webView.stringByEvaluatingJavaScriptFromString("document.getElementById('ping-username').value = 'ivan'")
                webView.stringByEvaluatingJavaScriptFromString("document.getElementById('ping-password').value = 'Zse45rfv'")
                webView.stringByEvaluatingJavaScriptFromString("document.getElementById('userpass').submit()")
            }
            
            expectationLogin = expectationWithDescription("Login")
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationLogin = nil
            }
            
            find()
        } else {
            XCTFail()
        }
    }
    
    func find() {
        XCTAssertNotNil(Kinvey.sharedClient.activeUser)
        
        if Kinvey.sharedClient.activeUser != nil {
            let store = DataStore<Person>.collection()
            
            weak var expectationFind = expectationWithDescription("Find")
            
            store.find() { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                expectationFind?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationFind = nil
            }
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
    
    func testMICErrorMessage() {
        defer {
            if let user = client?.activeUser {
                user.logout()
            }
        }
        
        weak var expectationLogin = expectationWithDescription("Login")
        
        let redirectURI = NSURL(string: "throwAnError://")!
        User.presentMICViewController(redirectURI: redirectURI, timeout: 60, forceUIWebView: false) { (user, error) -> Void in
            XCTAssertTrue(NSThread.isMainThread())
            XCTAssertNotNil(error)
            XCTAssertNotNil(error as? Kinvey.Error)
            XCTAssertNil(user)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .UnknownJsonError(let json):
                    let responseBody = [
                        "error" : "invalid_client",
                        "error_description" : "Client authentication failed.",
                        "debug" : "Client Verification Failed: redirect uri not valid"
                    ]
                    XCTAssertEqual(json.count, responseBody.count)
                    XCTAssertEqual(json["error"] as? String, responseBody["error"])
                    XCTAssertEqual(json["error_description"] as? String, responseBody["error_description"])
                    XCTAssertEqual(json["debug"] as? String, responseBody["debug"])
                default:
                    XCTFail()
                }
            }
            
            expectationLogin?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationLogin = nil
        }
    }

}
