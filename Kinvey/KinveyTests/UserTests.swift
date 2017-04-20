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
import ObjectMapper

typealias MICLoginViewController = KinveyApp.MICLoginViewController

class UserTests: KinveyTestCase {

    func testSignUp() {
        signUp()
        XCTAssertNotNil(client.activeUser)
    }
    
    func testSignUp404StatusCode() {
        mockResponse(statusCode: 404, data: Data())
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationSignUp = expectation(description: "Sign Up")
        
        User.signup { user, error in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(error)
            XCTAssertNil(user)
            
            expectationSignUp?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSignUp = nil
        }
    }
    
    func testSignUpTimeoutError() {
        setURLProtocol(TimeoutErrorURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationSignUp = expectation(description: "Sign Up")
        
        User.signup { user, error in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(error)
            XCTAssertNil(user)
            
            expectationSignUp?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSignUp = nil
        }
    }
    
    func testSignUpWithUsernameAndPassword() {
        guard !useMockData else {
            return
        }
        
        let username = UUID().uuidString
        let password = UUID().uuidString
        signUp(username: username, password: password)
        XCTAssertNotNil(client.activeUser)
    }
    
    func testSignUpAndDestroy() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        if let user = client.activeUser {
            weak var expectationDestroyUser = expectation(description: "Destroy User")
            
            user.destroy(client: client, completionHandler: { (error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                
                expectationDestroyUser?.fulfill()
            })
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDestroyUser = nil
            }
            
            XCTAssertNil(client.activeUser)
        }
    }
    
    func testSignUpAndDestroyHard() {
        signUp(username: "tempUser", password: "tempPass")
        
        var userId:String = ""
        
        if let user = client.activeUser {
            if useMockData {
                mockResponse(statusCode: 204, data: Data())
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            userId = user.userId
            weak var expectationDestroyUser = expectation(description: "Destroy User")
            
            user.destroy(hard: true, completionHandler: { (error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                expectationDestroyUser?.fulfill()
            })
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDestroyUser = nil
            }
            
            XCTAssertNil(client.activeUser)
        }
        
        signUp()

        if let _ = client.activeUser {
            if useMockData {
                mockResponse(statusCode: 404, json: [
                    "error": "UserNotFound",
                    "description": "This user does not exist for this app backend",
                    "debug": ""
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFindDestroyedUser = expectation(description: "Find Destoyed User")
            
            User.get(userId: userId , completionHandler: { (user, error) in
                XCTAssertNil(user)
                XCTAssertNotNil(error)
                expectationFindDestroyedUser?.fulfill()
            })
            
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFindDestroyedUser = nil
            }
        }
    }
    
    func testSignUpAndDestroyClassFunc() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        if let user = client.activeUser {
            weak var expectationDestroyUser = expectation(description: "Destroy User")
            
            User.destroy(userId: user.userId, completionHandler: { (error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                
                expectationDestroyUser?.fulfill()
            })
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDestroyUser = nil
            }
            
            XCTAssertNil(client.activeUser)
        }
    }
    
    func testSignUpAndDestroyHardClassFunc() {
        signUp()
        
        if let user = client.activeUser {
            if useMockData {
                mockResponse(statusCode: 204, data: Data())
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationDestroyUser = expectation(description: "Destroy User")
            
            User.destroy(userId: user.userId, hard: true, completionHandler: { (error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                
                expectationDestroyUser?.fulfill()
            })
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDestroyUser = nil
            }
            
            XCTAssertNil(client.activeUser)
        }
    }
    
    func testSignUpAndDestroyClientClassFunc() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        if let user = client.activeUser {
            weak var expectationDestroyUser = expectation(description: "Destroy User")
            
            User.destroy(userId: user.userId, client: client, completionHandler: { (error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                
                expectationDestroyUser?.fulfill()
            })
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDestroyUser = nil
            }
            
            XCTAssertNil(client.activeUser)
        }
    }
    
    func testChangePassword() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        XCTAssertNotNil(Kinvey.sharedClient.activeUser)
        
        guard let user = Kinvey.sharedClient.activeUser else {
            return
        }
        
        let store = DataStore<Person>.collection()
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            store.find(readPolicy: .forceNetwork) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        do {
            weak var expectationChangePassword = expectation(description: "Change Password")
            
            user.changePassword(newPassword: "test") { user, error in
                XCTAssertNotNil(user)
                XCTAssertNil(error)
                
                expectationChangePassword?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationChangePassword = nil
            }
        }
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            store.find(readPolicy: .forceNetwork) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
    }
    
    func testGet() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            if useMockData {
                mockResponse(json: user.toJSON())
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationUserExists = expectation(description: "User Exists")
            
            User.get(userId: user.userId) { user, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationUserExists?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUserExists = nil
            }
        }
    }
    
    func testGetTimeoutError() {
        signUp()
        
        if let user = client.activeUser {
            setURLProtocol(TimeoutErrorURLProtocol.self)
            
            weak var expectationUserExists = expectation(description: "User Exists")
            
            User.get(userId: user.userId, completionHandler: { (user, error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(error)
                XCTAssertNil(user)
                
                expectationUserExists?.fulfill()
            })
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUserExists = nil
            }
        }
    }
    
    func testRefresh() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            XCTAssertNil(user.email)
            
            let emailTest = "me@kinvey.com"
            
            if useMockData {
                var json = user.toJSON()
                json["email"] = emailTest
                mockResponse(json: json)
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationRefresh = expectation(description: "Refresh")
            
            user.refresh() { error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                
                XCTAssertEqual(user.email, emailTest)
                
                expectationRefresh?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRefresh = nil
            }
        }
    }
    
    func testLookup() {
        guard !useMockData else {
            return
        }
        
        let username = UUID().uuidString
        let password = UUID().uuidString
        let email = "\(username)@kinvey.com"
        signUp(username: username, password: password)
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            do {
                weak var expectationSave = expectation(description: "Save")
                
                user.email = email
                
                user.save() { user, error in
                    XCTAssertTrue(Thread.isMainThread)
                    XCTAssertNil(error)
                    XCTAssertNotNil(user)
                    
                    expectationSave?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationSave = nil
                }
            }
            
            do {
                weak var expectationUserLookup = expectation(description: "User Lookup")
                
                let userQuery = UserQuery {
                    $0.username = username
                }
                
                user.lookup(userQuery) { users, error in
                    XCTAssertTrue(Thread.isMainThread)
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
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationUserLookup = nil
                }
            }
        }
    }
    
    class MyUser: User {
        
        var foo: String?
        
        override func mapping(map: Map) {
            super.mapping(map: map)
            
            foo <- map["foo"]
        }
        
    }
    
    func testSave() {
        guard !useMockData else {
            return
        }
        
        client.userType = MyUser.self
        
        let user = User()
        user.email = "my-email@kinvey.com"
        signUp(user: user)
        
        XCTAssertNotNil(client.activeUser)
        XCTAssertTrue(client.activeUser is MyUser)
        
        if let user = client.activeUser as? MyUser {
            setURLProtocol(MockKinveyBackend.self)
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationUserSave = expectation(description: "User Save")
            
            user.foo = "bar"
            
            user.save { (user, error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                XCTAssertTrue(user is MyUser)
                if let myUser = user as? MyUser {
                    XCTAssertEqual(myUser.foo, "bar")
                    XCTAssertEqual(myUser.email, "my-email@kinvey.com")
                }

                expectationUserSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUserSave = nil
            }
        }
    }
    
    func testSaveCustomUser() {
        client.userType = MyUser.self
        
        let user = MyUser()
        user.foo = "bar"
        signUp(user: user)
        
        XCTAssertNotNil(client.activeUser)
        XCTAssertTrue(client.activeUser is MyUser)
        
        if let user = client.activeUser as? MyUser {
            if useMockData {
                mockResponse(completionHandler: { (request) -> HttpResponse in
                    let json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
                    return HttpResponse(json: json)
                })
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationUserSave = expectation(description: "User Save")
            
            user.save { (user, error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                
                XCTAssertNotNil(user)
                XCTAssertTrue(user is MyUser)
                
                XCTAssertNotNil(self.client.activeUser)
                XCTAssertTrue(self.client.activeUser is MyUser)
                
                if let myUser = user as? MyUser {
                    XCTAssertEqual(myUser.foo, "bar")
                }
                
                expectationUserSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUserSave = nil
            }
        }
    }
    
    func testSaveTimeoutError() {
        guard !useMockData else {
            return
        }
        
        client.userType = MyUser.self
        
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        XCTAssertTrue(client.activeUser is MyUser)
        
        if let user = client.activeUser as? MyUser {
            setURLProtocol(TimeoutErrorURLProtocol.self)
            
            weak var expectationUserSave = expectation(description: "User Save")
            
            user.foo = "bar"
            
            user.save { (user, error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(error)
                XCTAssertNil(user)
                
                expectationUserSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUserSave = nil
            }
        }
    }
    
    func testCustomUserLookup() {
        client.userType = MyUser.self
        
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        XCTAssertTrue(client.activeUser is MyUser)
        
        if let user = client.activeUser as? MyUser {
            let email = "victor@kinvey.com"
            
            if useMockData {
                mockResponse(json: [
                    [
                        "_id" : UUID().uuidString,
                        "username" : "victor",
                        "email" : email
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            do {
                weak var expectationUserLookup = expectation(description: "User Lookup")
                
                let userQuery = UserQuery {
                    $0.email = email
                }
                user.lookup(userQuery) { users, error in
                    XCTAssertTrue(Thread.isMainThread)
                    XCTAssertNotNil(users)
                    XCTAssertNil(error)
                    
                    if let users = users {
                        XCTAssertEqual(users.count, 1)
                        
                        if let user = users.first {
                            XCTAssertTrue(user is MyUser)
                            XCTAssertEqual(user.email, email)
                        }
                    }
                    
                    expectationUserLookup?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationUserLookup = nil
                }
            }
            
            do {
                weak var expectationUserLookup = expectation(description: "User Lookup")
                
                let userQuery = UserQuery {
                    $0.email = email
                }
                user.lookup(userQuery) { (users: [MyUser]?, error) in
                    XCTAssertTrue(Thread.isMainThread)
                    XCTAssertNotNil(users)
                    XCTAssertNil(error)
                    
                    if let users = users {
                        XCTAssertEqual(users.count, 1)
                        
                        if let user = users.first {
                            XCTAssertEqual(user.email, email)
                        }
                    }
                    
                    expectationUserLookup?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationUserLookup = nil
                }
            }
        }
    }
    
    func testLogoutLogin() {
        guard !useMockData else {
            return
        }
        
        let username = UUID().uuidString
        let password = UUID().uuidString
        signUp(username: username, password: password)
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            user.logout()
            
            XCTAssertNil(client.activeUser)
            
            let userDefaults = UserDefaults.standard
            XCTAssertNil(userDefaults.object(forKey: client.appKey!))
            
            weak var expectationUserLogin = expectation(description: "User Login")
            
            User.login(username: username, password: password) { user, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationUserLogin?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUserLogin = nil
            }
        }
    }
    
    func testLogoutLoginTimeoutError() {
        guard !useMockData else {
            return
        }
        
        let username = UUID().uuidString
        let password = UUID().uuidString
        signUp(username: username, password: password)
        defer {
            weak var expectationUserLogin = expectation(description: "User Login")
            
            User.login(username: username, password: password) { user, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationUserLogin?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUserLogin = nil
            }
            
            if let activeUser = client.activeUser {
                weak var expectationDestroy = expectation(description: "Destroy")
                
                activeUser.destroy { (error) -> Void in
                    XCTAssertTrue(Thread.isMainThread)
                    XCTAssertNil(error)
                    
                    expectationDestroy?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
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
            
            weak var expectationUserLogin = expectation(description: "User Login")
            
            User.login(username: username, password: password) { user, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(error)
                XCTAssertNil(user)
                
                expectationUserLogin?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUserLogin = nil
            }
        }
    }
    
    func testLogoutLogin200ButInvalidResponseError() {
        guard !useMockData else {
            return
        }
        
        let username = UUID().uuidString
        let password = UUID().uuidString
        signUp(username: username, password: password)
        defer {
            weak var expectationUserLogin = expectation(description: "User Login")
            
            User.login(username: username, password: password) { user, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationUserLogin?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUserLogin = nil
            }
            
            if let activeUser = client.activeUser {
                weak var expectationDestroy = expectation(description: "Destroy")
                
                activeUser.destroy { (error) -> Void in
                    XCTAssertTrue(Thread.isMainThread)
                    XCTAssertNil(error)
                    
                    expectationDestroy?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationDestroy = nil
                }
            }
        }
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            user.logout()
            
            XCTAssertNil(client.activeUser)
            
            class InvalidUserResponseErrorURLProtocol: URLProtocol {
                
                override class func canInit(with request: URLRequest) -> Bool {
                    return true
                }
                
                override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                    return request
                }
                
                override func startLoading() {
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json"])!
                    client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let data = try! JSONSerialization.data(withJSONObject: ["userId":"123"], options: [])
                    client!.urlProtocol(self, didLoad: data)
                    client!.urlProtocolDidFinishLoading(self)
                }
                
                override func stopLoading() {
                }
                
            }
            
            setURLProtocol(InvalidUserResponseErrorURLProtocol.self)
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationUserLogin = expectation(description: "User Login")
            
            User.login(username: username, password: password) { user, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(error)
                XCTAssertNil(user)
                
                expectationUserLogin?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUserLogin = nil
            }
        }
    }
    
    func testExists() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            XCTAssertNotNil(user.username)
            
            if let username = user.username {
                weak var expectationUserExists = expectation(description: "User Exists")
                
                User.exists(username: username) { (exists, error) -> Void in
                    XCTAssertTrue(Thread.isMainThread)
                    XCTAssertNil(error)
                    XCTAssertTrue(exists)
                    
                    expectationUserExists?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
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
                
                weak var expectationUserExists = expectation(description: "User Exists")
                
                User.exists(username: username) { (exists, error) -> Void in
                    XCTAssertTrue(Thread.isMainThread)
                    XCTAssertNotNil(error)
                    XCTAssertFalse(exists)
                    
                    expectationUserExists?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationUserExists = nil
                }
            }
        }
    }
    
    func testDestroyTimeoutError() {
        signUp()
        
        setURLProtocol(TimeoutErrorURLProtocol.self)
        
        if let activeUser = client.activeUser {
            weak var expectationDestroy = expectation(description: "Destroy")
            
            activeUser.destroy { (error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(error)
                
                expectationDestroy?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDestroy = nil
            }
        }
    }
    
    func testSendEmailConfirmation() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            weak var expectationSave = expectation(description: "Save")
            
            user.email = "\(user.username!)@kinvey.com"
            
            user.save() { user, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSave = nil
            }
            
            class Mock204URLProtocol: URLProtocol {
                
                override class func canInit(with request: URLRequest) -> Bool {
                    return true
                }
                
                override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                    return request
                }
                
                fileprivate override func startLoading() {
                    let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: "HTTP/1.1", headerFields: [:])!
                    client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    client!.urlProtocol(self, didLoad: Data())
                    client!.urlProtocolDidFinishLoading(self)
                }
                
                fileprivate override func stopLoading() {
                }
                
            }
            
            setURLProtocol(Mock204URLProtocol.self)
            defer {
                setURLProtocol(nil)
            }

            weak var expectationSendEmailConfirmation = expectation(description: "Send Email Confirmation")
            
            user.sendEmailConfirmation { error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                
                expectationSendEmailConfirmation?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSendEmailConfirmation = nil
            }
        }
    }
    
    func testUserMetadata() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        class Mock200URLProtocol: URLProtocol {
            
            override class func canInit(with request: URLRequest) -> Bool {
                return true
            }
            
            override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                return request
            }
            
            fileprivate override func startLoading() {
                let request = self.request
                
                let userId = request.url?.lastPathComponent
                
                let cannedResponse = "{\"_id\": \"\(userId!)\", \"username\": \"test\", \"_acl\": {\"creator\": \"582b81b95c84a5525e9abcc9\"},\"email\": \"tejas@kinvey.com\",\"_kmd\": {\"lmt\": \"2016-11-15T21:44:37.302Z\",\"ect\": \"2016-11-15T21:44:25.756Z\",\"status\":{\"val\":\"disabled\",\"lastChange\": \"2016-11-16T15:08:52.225Z\"},\"passwordReset\":{\"status\":\"InProgress\",\"lastStateChangeAt\":\"2012-10-10T19:56:03.282Z\"},\"emailVerification\":{\"status\":\"confirmed\",\"lastStateChangeAt\":\"2012-10-10T19:56:03.282Z\",\"lastConfirmedAt\":\"2012-10-10T19:56:03.282Z\",\"emailAddress\":\"johndoe@kinvey.com\"}}}"

                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
                client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client!.urlProtocol(self, didLoad: cannedResponse.data(using: String.Encoding.utf8)!)
                client!.urlProtocolDidFinishLoading(self)
            }
            
            fileprivate override func stopLoading() {
            }
            
        }
        
        setURLProtocol(Mock200URLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationUserMetadata = expectation(description: "Email Confirmation Status")
        let user = Client.sharedClient.activeUser
        
        User.get(userId: (user?.userId)!) { newUser, error in
            XCTAssertNotNil(newUser)
            
            XCTAssertNotNil(newUser?.metadata)
            
            XCTAssertEqual(newUser?.metadata?.userStatus?.value, "disabled")
            XCTAssertNotNil(newUser?.metadata?.userStatus?.lastChange)

            XCTAssertEqual(newUser?.metadata?.passwordReset?.status, "InProgress")
            XCTAssertNotNil(newUser?.metadata?.passwordReset?.lastStateChangeAt)

            XCTAssertEqual(newUser?.metadata?.emailVerification?.status, "confirmed")
            XCTAssertNotNil(newUser?.metadata?.emailVerification?.lastStateChangeAt)
            XCTAssertNotNil(newUser?.metadata?.emailVerification?.lastConfirmedAt)
            XCTAssertEqual(newUser?.metadata?.emailVerification?.emailAddress, "johndoe@kinvey.com")

            expectationUserMetadata?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationUserMetadata = nil
        }
    
    }
    func testResetPasswordByEmail() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            user.email = "\(user.username!)@kinvey.com"
            
            weak var expectationSave = expectation(description: "Save")
            
            user.save() { user, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSave = nil
            }
            
            class Mock204URLProtocol: URLProtocol {
                
                override class func canInit(with request: URLRequest) -> Bool {
                    return true
                }
                
                override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                    return request
                }
                
                fileprivate override func startLoading() {
                    let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: "HTTP/1.1", headerFields: [:])!
                    client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    client!.urlProtocol(self, didLoad: Data())
                    client!.urlProtocolDidFinishLoading(self)
                }
                
                fileprivate override func stopLoading() {
                }
                
            }
            
            setURLProtocol(Mock204URLProtocol.self)
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationResetPassword = expectation(description: "Reset Password")
            
            user.resetPassword { error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                
                expectationResetPassword?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationResetPassword = nil
            }
        }
    }
    
    func testResetPasswordByUsername() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            weak var expectationResetPassword = expectation(description: "Reset Password")
            
            user.resetPassword { error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                
                expectationResetPassword?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationResetPassword = nil
            }
        }
    }
    
    func testResetPasswordNoEmailOrUsername() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            user.username = nil
            
            weak var expectationSave = expectation(description: "Save")
            
            user.save() { user, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSave = nil
            }
            
            weak var expectationResetPassword = expectation(description: "Reset Password")
            
            user.resetPassword { error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(error)
                
                expectationResetPassword?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationResetPassword = nil
            }
        }
    }
    
    func testResetPasswordTimeoutError() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            weak var expectationSave = expectation(description: "Save")
            
            user.save() { user, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSave = nil
            }
            
            setURLProtocol(TimeoutErrorURLProtocol.self)
            
            weak var expectationResetPassword = expectation(description: "Reset Password")
            
            user.resetPassword { error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(error)
                
                expectationResetPassword?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationResetPassword = nil
            }
        }
    }
    
    func testForgotUsername() {
        guard !useMockData else {
            return
        }
        
        weak var expectationForgotUsername = expectation(description: "Forgot Username")
        
        User.forgotUsername(email: "\(UUID().uuidString)@kinvey.com") { error in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(error)
            
            expectationForgotUsername?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationForgotUsername = nil
        }
    }
    
    func testForgotUsernameTimeoutError() {
        setURLProtocol(TimeoutErrorURLProtocol.self)
        
        weak var expectationForgotUsername = expectation(description: "Forgot Username")
        
        User.forgotUsername(email: "\(UUID().uuidString)@kinvey.com") { error in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(error)
            
            expectationForgotUsername?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationForgotUsername = nil
        }
    }
    
    func testFacebookLogin() {
        class FakeFacebookSocialLoginURLProtocol: URLProtocol {
            
            override class func canInit(with request: URLRequest) -> Bool {
                return true
            }
            
            override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                return request
            }
            
            override func startLoading() {
                let userId = "503bc9806065332d6f000005"
                let headers = [
                    "Location" : "https://baas.kinvey.com/user/:appKey/\(userId)",
                    "Content-Type" : "application/json"
                ]
                let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: "HTTP/1.1", headerFields: headers)!
                client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                
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
                ] as [String : Any]
                
                let data = try! JSONSerialization.data(withJSONObject: jsonResponse, options: [])
                client!.urlProtocol(self, didLoad: data)
                client!.urlProtocolDidFinishLoading(self)
            }
            
            override func stopLoading() {
            }
            
        }
        
        setURLProtocol(FakeFacebookSocialLoginURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFacebookLogin = expectation(description: "Facebook Login")
        
        let fakeFacebookData = [
            "access_token": "AAAD30ogoDZCYBAKS50rOwCxMR7tIX8F90YDyC3vp63j0IvyCU0MELE2QMLnsWXKo2LcRgwA51hFr1UUpqXkSHu4lCj4VZCIuGG7DHZAHuZArzjvzTZAwQ",
            "expires": "5105388"
        ]
        User.login(authSource: .facebook, fakeFacebookData) { user, error in
            XCTAssertNotNil(user)
            XCTAssertNil(error)
            
            expectationFacebookLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFacebookLogin = nil
        }
        
        client.activeUser = nil
    }
    
    func testMICLoginWKWebView() {
        guard !useMockData else {
            return
        }
        
        defer {
            if let user = client.activeUser {
                user.logout()
            }
        }
        
        tester().tapView(withAccessibilityIdentifier: "MIC Login")
        defer {
            tester().tapView(withAccessibilityLabel: "Back", traits: UIAccessibilityTraitButton)
        }
        tester().tapView(withAccessibilityIdentifier: "Login")
        
        tester().waitForAnimationsToFinish()
        tester().wait(forTimeInterval: 1)
        
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController,
            let micLoginViewController = navigationController.topViewController as? MICLoginViewController,
            let navigationController2 = navigationController.presentedViewController as? UINavigationController,
            let micViewController = navigationController2.topViewController as? Kinvey.MICLoginViewController
        {
            weak var expectationLogin: XCTestExpectation? = nil
            
            micLoginViewController.completionHandler = { (user, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationLogin?.fulfill()
            }
            
            let webView = micViewController.value(forKey: "webView") as? WKWebView
            XCTAssertNotNil(webView)
            if let webView = webView {
                var username: String? = nil
                webView.evaluateJavaScript("document.getElementById('ping-username').value", completionHandler: { (result, error) -> Void in
                    if let result = result as? String {
                        username = result
                    }
                })
                XCTAssertTrue(wait(toBeTrue: username == "", timeout: 10))
                
                tester().waitForAnimationsToFinish()
                tester().wait(forTimeInterval: 1)
                
                weak var expectationTypeUsername = expectation(description: "Type Username")
                weak var expectationTypePassword = expectation(description: "Type Password")
                
                webView.evaluateJavaScript("document.getElementById('ping-username').value = 'ivan'", completionHandler: { (result, error) -> Void in
                    expectationTypeUsername?.fulfill()
                })
                webView.evaluateJavaScript("document.getElementById('ping-password').value = 'Zse45rfv'", completionHandler: { (result, error) -> Void in
                    expectationTypePassword?.fulfill()
                })
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationTypeUsername = nil
                    expectationTypePassword = nil
                }
                
                weak var expectationSubmitForm = expectation(description: "Submit Form")
                
                webView.evaluateJavaScript("document.getElementById('userpass').submit()", completionHandler: { (result, error) -> Void in
                    expectationSubmitForm?.fulfill()
                })
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationSubmitForm = nil
                }
                
                XCTAssertTrue(wait(toBeTrue: self.client.activeUser != nil))
                
                do {
                    let store = DataStore<Person>.collection(.network)
                    
                    weak var expectationFind = expectation(description: "Find")
                    
                    store.find { persons, error in
                        XCTAssertTrue(Thread.isMainThread)
                        XCTAssertNil(error)
                        XCTAssertNotNil(persons)
                        
                        expectationFind?.fulfill()
                    }
                    
                    waitForExpectations(timeout: defaultTimeout) { error in
                        expectationFind = nil
                    }
                }
            }
        } else {
            XCTFail()
        }
    }
    
    func testMICLoginWKWebViewModal() {
        guard !useMockData else {
            return
        }
        
        defer {
            if let user = client.activeUser {
                user.logout()
            }
        }
        
        tester().tapView(withAccessibilityIdentifier: "MIC Login Modal")
        defer {
            if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController,
                let micLoginViewController = navigationController.presentedViewController as? MICLoginViewController
            {
                micLoginViewController.performSegue(withIdentifier: "back", sender: nil)
                tester().waitForAnimationsToFinish()
            }
        }
        tester().tapView(withAccessibilityIdentifier: "Login")
        
        tester().waitForAnimationsToFinish()
        tester().wait(forTimeInterval: 1)
        
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController,
            let micLoginViewController = navigationController.presentedViewController as? MICLoginViewController,
            let navigationController2 = micLoginViewController.presentedViewController as? UINavigationController,
            let micViewController = navigationController2.topViewController as? Kinvey.MICLoginViewController
        {
            weak var expectationLogin: XCTestExpectation? = nil
            
            micLoginViewController.completionHandler = { (user, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationLogin?.fulfill()
            }
            
            tester().waitForAnimationsToFinish()
            tester().wait(forTimeInterval: 1)
            
            let webView = micViewController.value(forKey: "webView") as? WKWebView
            XCTAssertNotNil(webView)
            if let webView = webView {
                var wait = true
                while wait {
                    weak var expectationWait = expectation(description: "Wait")
                    
                    webView.evaluateJavaScript("document.getElementById('ping-username').value", completionHandler: { (result, error) -> Void in
                        if let result = result , !(result is NSNull) {
                            wait = false
                        }
                        expectationWait?.fulfill()
                    })
                    
                    waitForExpectations(timeout: defaultTimeout) { error in
                        expectationWait = nil
                    }
                }
                
                tester().waitForAnimationsToFinish()
                tester().wait(forTimeInterval: 1)
                
                weak var expectationTypeUsername = expectation(description: "Type Username")
                weak var expectationTypePassword = expectation(description: "Type Password")
                
                webView.evaluateJavaScript("document.getElementById('ping-username').value = 'ivan'", completionHandler: { (result, error) -> Void in
                    expectationTypeUsername?.fulfill()
                })
                webView.evaluateJavaScript("document.getElementById('ping-password').value = 'Zse45rfv'", completionHandler: { (result, error) -> Void in
                    expectationTypePassword?.fulfill()
                })
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationTypeUsername = nil
                    expectationTypePassword = nil
                }
                
                weak var expectationSubmitForm = expectation(description: "Submit Form")
                
                webView.evaluateJavaScript("document.getElementById('userpass').submit()", completionHandler: { (result, error) -> Void in
                    expectationSubmitForm?.fulfill()
                })
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationSubmitForm = nil
                }
            }
        } else {
            XCTFail()
        }
    }
    
    func testMICLoginUIWebView() {
        guard !useMockData else {
            return
        }
        
        defer {
            if let user = client.activeUser {
                user.logout()
            }
        }
        
        tester().tapView(withAccessibilityIdentifier: "MIC Login")
        defer {
            tester().tapView(withAccessibilityLabel: "Back")
        }
        
        tester().setOn(true, forSwitchWithAccessibilityIdentifier: "Force UIWebView Value")
        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityIdentifier: "Login")
        
        tester().waitForAnimationsToFinish()
        tester().wait(forTimeInterval: 1)
        
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController,
            let micLoginViewController = navigationController.topViewController as? MICLoginViewController,
            let navigationController2 = navigationController.presentedViewController as? UINavigationController,
            let micViewController = navigationController2.topViewController as? Kinvey.MICLoginViewController
        {
            weak var expectationLogin: XCTestExpectation? = nil
            
            micLoginViewController.completionHandler = { (user, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                expectationLogin?.fulfill()
            }
            
            let webView = micViewController.value(forKey: "webView") as? UIWebView
            XCTAssertNotNil(webView)
            if let webView = webView {
                var result: String?
                while result == nil {
                    result = webView.stringByEvaluatingJavaScript(from: "document.getElementById('ping-username').value")
                }
                
                tester().waitForAnimationsToFinish()
                tester().wait(forTimeInterval: 1)
                
                webView.stringByEvaluatingJavaScript(from: "document.getElementById('ping-username').value = 'ivan'")
                webView.stringByEvaluatingJavaScript(from: "document.getElementById('ping-password').value = 'Zse45rfv'")
                webView.stringByEvaluatingJavaScript(from: "document.getElementById('userpass').submit()")
            }
        } else {
            XCTFail()
        }
    }
    
    func find() {
        XCTAssertNotNil(Kinvey.sharedClient.activeUser)
        
        if Kinvey.sharedClient.activeUser != nil {
            let store = DataStore<Person>.collection(.network)
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find() { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
    }
    
    func testMICLoginUIWebViewTimeoutError() {
        guard !useMockData else {
            return
        }
        
        defer {
            if let user = client.activeUser {
                user.logout()
            }
        }
        
        tester().tapView(withAccessibilityIdentifier: "MIC Login")
        defer {
            tester().tapView(withAccessibilityLabel: "Back")
        }
        
        tester().setOn(true, forSwitchWithAccessibilityIdentifier: "Force UIWebView Value")
        tester().waitForAnimationsToFinish()
        
        let registered = URLProtocol.registerClass(TimeoutErrorURLProtocol.self)
        defer {
            if registered {
                URLProtocol.unregisterClass(TimeoutErrorURLProtocol.self)
            }
        }
        
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController,
            let micLoginViewController = navigationController.topViewController as? MICLoginViewController
        {
            weak var expectationLogin = expectation(description: "Login")
            
            micLoginViewController.completionHandler = { (user, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(error)
                XCTAssertNil(user)
                
                expectationLogin?.fulfill()
            }
            
            tester().tapView(withAccessibilityIdentifier: "Login")
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationLogin = nil
            }
        } else {
            XCTFail()
        }
    }
    
    func testMICErrorMessage() {
        guard !useMockData else {
            return
        }
        
        defer {
            if let user = client.activeUser {
                user.logout()
            }
        }
        
        weak var expectationLogin = expectation(description: "Login")
        
        let redirectURI = URL(string: "throwAnError://")!
        User.presentMICViewController(redirectURI: redirectURI, timeout: 60, micUserInterface: .uiWebView) { (user, error) -> Void in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(error)
            XCTAssertNotNil(error as? Kinvey.Error)
            XCTAssertNil(user)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .unknownJsonError(_, _, let json):
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
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationLogin = nil
        }
    }
    
    func testMICLoginAutomatedAuthorizationGrantFlow() {
        if let user = client.activeUser {
            user.logout()
        }
        defer {
            if let user = client.activeUser {
                user.logout()
            }
        }
        
        class MICLoginAutomatedAuthorizationGrantFlowURLProtocol: URLProtocol {
            
            static let code = "7af647ad1414986bec71d7799ced85fd271050a8"
            static let tempLoginUri = "https://auth.kinvey.com/oauth/authenticate/b3ca941c1141468bb19d2f2c7409f7a6"
            lazy var code: String = MICLoginAutomatedAuthorizationGrantFlowURLProtocol.code
            lazy var tempLoginUri: String = MICLoginAutomatedAuthorizationGrantFlowURLProtocol.tempLoginUri
            static var count = 0
            
            override class func canInit(with request: URLRequest) -> Bool {
                return true
            }
            
            override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                return request
            }
            
            override func startLoading() {
                switch type(of: self).count {
                case 0:
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "temp_login_uri" : tempLoginUri
                    ]
                    let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 1:
                    XCTAssertEqual(request.url!.absoluteString, tempLoginUri)
                    let redirectRequest = URLRequest(url: URL(string: "micauthgrantflow://?code=\(code)")!)
                    let response = HTTPURLResponse(url: request.url!, statusCode: 302, httpVersion: "HTTP/1.1", headerFields: ["Location" : redirectRequest.url!.absoluteString])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    client?.urlProtocol(self, wasRedirectedTo: redirectRequest, redirectResponse: response)
                    let data = "Found. Redirecting to micauthgrantflow://?code=\(code)".data(using: String.Encoding.utf8)!
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 2:
                    switch Body.buildFormUrlEncoded(body: request.httpBodyString) {
                    case .formUrlEncoded(let params):
                        XCTAssertEqual(params, [
                            "client_id" : MockKinveyBackend.kid,
                            "code" : code,
                            "redirect_uri" : "micAuthGrantFlow%3A%2F%2F",
                            "grant_type" : "authorization_code"
                        ])
                    default:
                        XCTFail()
                    }
                    
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "access_token" : "7f3fe7847a7292994c87fa322405cb8e03b7bf9c",
                        "token_type" : "bearer",
                        "expires_in" : 3599,
                        "refresh_token" : "dc6118e98b8c004a6e2d3e2aa985f57e40a87a02"
                    ] as [String : Any]
                    let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 3:
                    let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "error" : "UserNotFound",
                        "description" : "This user does not exist for this app backend",
                        "debug" : ""
                    ]
                    let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 4:
                    let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "_socialIdentity" : [
                            "kinveyAuth": [
                                "access_token" : "a10a3743028e2e92b97037825b50a2666608b874",
                                "refresh_token" : "627b034f5ec409899252a8017cb710566dfd2620",
                                "id" : "custom",
                                "audience" : MockKinveyBackend.kid
                            ]
                        ],
                        "username" : "3b788b0c-cb99-4692-b3ae-a6b10b3d76f2",
                        "password" : "fa0f771f-6480-4f11-a11b-dc85cce52beb",
                        "_kmd" : [
                            "lmt" : "2016-09-01T01:48:01.177Z",
                            "ect" : "2016-09-01T01:48:01.177Z",
                            "authtoken" : "12ed2b41-a5a1-4f37-a640-3a9c62c3fefd.rUHKOlQuRb4pW4NjmCimJ64rd2BF3drXy1SjHtuVCoM="
                        ],
                        "_id" : "57c788d168d976c525ee4602",
                        "_acl" : [
                            "creator" : "57c788d168d976c525ee4602"
                        ]
                    ] as [String : Any]
                    let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 5:
                    let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "error" : "InvalidCredentials",
                        "description" : "Invalid credentials. Please retry your request with correct credentials",
                        "debug" : "Error encountered authenticating against kinveyAuth: {\"error\":\"server_error\",\"error_description\":\"Access Token not found\"}"
                    ]
                    let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 6:
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "access_token" : "7f3fe7847a7292994c87fa322405cb8e03b7bf9c",
                        "token_type" : "bearer",
                        "expires_in" : 3599,
                        "refresh_token" : "dc6118e98b8c004a6e2d3e2aa985f57e40a87a02"
                        ] as [String : Any]
                    let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 7:
                    let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "_socialIdentity" : [
                            "kinveyAuth": [
                                "access_token" : "a10a3743028e2e92b97037825b50a2666608b874",
                                "refresh_token" : "627b034f5ec409899252a8017cb710566dfd2620",
                                "id" : "custom",
                                "audience" : MockKinveyBackend.kid
                            ]
                        ],
                        "username" : "3b788b0c-cb99-4692-b3ae-a6b10b3d76f2",
                        "password" : "fa0f771f-6480-4f11-a11b-dc85cce52beb",
                        "_kmd" : [
                            "lmt" : "2016-09-01T01:48:01.177Z",
                            "ect" : "2016-09-01T01:48:01.177Z",
                            "authtoken" : "12ed2b41-a5a1-4f37-a640-3a9c62c3fefd.rUHKOlQuRb4pW4NjmCimJ64rd2BF3drXy1SjHtuVCoM="
                        ],
                        "_id" : "57c788d168d976c525ee4602",
                        "_acl" : [
                            "creator" : "57c788d168d976c525ee4602"
                        ]
                        ] as [String : Any]
                    let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 8:
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [[:]]
                    let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                default:
                    XCTFail()
                }
                type(of: self).count += 1
            }
            
            override func stopLoading() {
            }
        }
        
        setURLProtocol(MICLoginAutomatedAuthorizationGrantFlowURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        XCTAssertNil(client.activeUser)
        
        weak var expectationLogin = expectation(description: "Login")
        
        let redirectURI = URL(string: "micAuthGrantFlow://")!
        User.login(
            redirectURI: redirectURI,
            username: "custom",
            password: "1234"
        ) { user, error in
            XCTAssertNotNil(user)
            XCTAssertNil(error)
            
            expectationLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationLogin = nil
        }
        
        XCTAssertNotNil(client.activeUser)
        
        do {
            let store = DataStore<Person>.collection(.network)
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
    }
    
    func testMICLoginAutomatedAuthorizationGrantFlowRefreshTokenFails() {
        if let user = client.activeUser {
            user.logout()
        }
        defer {
            if let user = client.activeUser {
                user.logout()
            }
        }
        
        class MICLoginAutomatedAuthorizationGrantFlowURLProtocol: URLProtocol {
            
            static let code = "7af647ad1414986bec71d7799ced85fd271050a8"
            static let tempLoginUri = "https://auth.kinvey.com/oauth/authenticate/b3ca941c1141468bb19d2f2c7409f7a6"
            lazy var code: String = MICLoginAutomatedAuthorizationGrantFlowURLProtocol.code
            lazy var tempLoginUri: String = MICLoginAutomatedAuthorizationGrantFlowURLProtocol.tempLoginUri
            static var count = 0
            static var invalidCredentialsCount = 0
            
            override class func canInit(with request: URLRequest) -> Bool {
                return true
            }
            
            override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                return request
            }
            
            override func startLoading() {
                switch type(of: self).count {
                case 0:
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "temp_login_uri" : tempLoginUri
                    ]
                    let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 1:
                    XCTAssertEqual(request.url!.absoluteString, tempLoginUri)
                    let redirectRequest = URLRequest(url: URL(string: "micauthgrantflow://?code=\(code)")!)
                    let response = HTTPURLResponse(url: request.url!, statusCode: 302, httpVersion: "HTTP/1.1", headerFields: ["Location" : redirectRequest.url!.absoluteString])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    client?.urlProtocol(self, wasRedirectedTo: redirectRequest, redirectResponse: response)
                    let data = "Found. Redirecting to micauthgrantflow://?code=\(code)".data(using: String.Encoding.utf8)!
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 2:
                    switch Body.buildFormUrlEncoded(body: request.httpBodyString) {
                    case .formUrlEncoded(let params):
                        XCTAssertEqual(params, [
                            "client_id" : MockKinveyBackend.kid,
                            "code" : code,
                            "redirect_uri" : "micAuthGrantFlow%3A%2F%2F",
                            "grant_type" : "authorization_code"
                        ])
                    default:
                        XCTFail()
                    }
                    
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "access_token" : "7f3fe7847a7292994c87fa322405cb8e03b7bf9c",
                        "token_type" : "bearer",
                        "expires_in" : 3599,
                        "refresh_token" : "dc6118e98b8c004a6e2d3e2aa985f57e40a87a02"
                    ] as [String : Any]
                    let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 3:
                    let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "error" : "UserNotFound",
                        "description" : "This user does not exist for this app backend",
                        "debug" : ""
                    ]
                    let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 4:
                    let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "_socialIdentity" : [
                            "kinveyAuth": [
                                "access_token" : "a10a3743028e2e92b97037825b50a2666608b874",
                                "refresh_token" : "627b034f5ec409899252a8017cb710566dfd2620",
                                "id" : "custom",
                                "audience" : MockKinveyBackend.kid
                            ]
                        ],
                        "username" : "3b788b0c-cb99-4692-b3ae-a6b10b3d76f2",
                        "password" : "fa0f771f-6480-4f11-a11b-dc85cce52beb",
                        "_kmd" : [
                            "lmt" : "2016-09-01T01:48:01.177Z",
                            "ect" : "2016-09-01T01:48:01.177Z",
                            "authtoken" : "12ed2b41-a5a1-4f37-a640-3a9c62c3fefd.rUHKOlQuRb4pW4NjmCimJ64rd2BF3drXy1SjHtuVCoM="
                        ],
                        "_id" : "57c788d168d976c525ee4602",
                        "_acl" : [
                            "creator" : "57c788d168d976c525ee4602"
                        ]
                    ] as [String : Any]
                    let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                default:
                    type(of: self).invalidCredentialsCount += 1
                    XCTAssertLessThanOrEqual(type(of: self).invalidCredentialsCount, 2)
                    let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "error" : "InvalidCredentials",
                        "description" : "Invalid credentials. Please retry your request with correct credentials",
                        "debug" : "Error encountered authenticating against kinveyAuth: {\"error\":\"server_error\",\"error_description\":\"Access Token not found\"}"
                    ]
                    let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                }
                type(of: self).count += 1
            }
            
            override func stopLoading() {
            }
        }
        
        setURLProtocol(MICLoginAutomatedAuthorizationGrantFlowURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        XCTAssertNil(client.activeUser)
        
        weak var expectationLogin = expectation(description: "Login")
        
        let redirectURI = URL(string: "micAuthGrantFlow://")!
        User.login(
            redirectURI: redirectURI,
            username: "custom",
            password: "1234"
        ) { user, error in
            XCTAssertNotNil(user)
            XCTAssertNil(error)
            
            expectationLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationLogin = nil
        }
        
        XCTAssertNotNil(client.activeUser)
        
        do {
            let store = DataStore<Person>.collection(.network)
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find { persons, error in
                XCTAssertNil(persons)
                XCTAssertNotNil(error)
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
    }

}
