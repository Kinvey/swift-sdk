//
//  UserTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
import WebKit
@testable import Kinvey
import ObjectMapper
import SafariServices
import Nimble

// swiftlint:disable nesting

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
        XCTAssertNil(client.activeUser)
        
        let username = UUID().uuidString
        let password = UUID().uuidString
        signUp(username: username, password: password)
        
        XCTAssertNotNil(client.activeUser)
        XCTAssertEqual(client.activeUser?.username, username)
    }
    
    func testSignUpAndDestroy() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        if let user = client.activeUser {
            weak var expectationDestroyUser = expectation(description: "Destroy User")
            
            user.destroy() {
                XCTAssertTrue(Thread.isMainThread)
                
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationDestroyUser?.fulfill()
            }
            
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
            
            user.destroy(hard: true, completionHandler: {
                XCTAssertTrue(Thread.isMainThread)
                
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
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
            
            User.get(userId: userId) { (user, error) in
                XCTAssertNil(user)
                XCTAssertNotNil(error)
                expectationFindDestroyedUser?.fulfill()
            }
            
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
            
            User.destroy(userId: user.userId, options: try! Options(client: client)) {
                XCTAssertTrue(Thread.isMainThread)
                
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationDestroyUser?.fulfill()
            }
            
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
            
            User.destroy(userId: user.userId, hard: true, options: try! Options(client: client)) {
                XCTAssertTrue(Thread.isMainThread)
                
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationDestroyUser?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDestroyUser = nil
            }
            
            XCTAssertNil(client.activeUser)
        }
    }
    
    func testSignUpAndDestroyNotHardClassFunc() {
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
            
            User.destroy(userId: user.userId, hard: false, options: try! Options(client: client)) {
                XCTAssertTrue(Thread.isMainThread)
                
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationDestroyUser?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDestroyUser = nil
            }
            
            XCTAssertNil(client.activeUser)
        }
    }
    
    func testSignUpAndDestroyHardClassFuncTimeout() {
        signUp()
        
        if let user = client.activeUser {
            if useMockData {
                setURLProtocol(TimeoutErrorURLProtocol.self)
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationDestroyUser = expectation(description: "Destroy User")
            
            User.destroy(userId: user.userId, hard: true, options: try! Options(client: client)) {
                XCTAssertTrue(Thread.isMainThread)
                
                switch $0 {
                case .success:
                    XCTFail("A failure result is expected")
                case .failure:
                    break
                }
                
                expectationDestroyUser?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDestroyUser = nil
            }
            
            XCTAssertNotNil(client.activeUser)
        }
    }
    
    func testSignUpAndDestroyClientClassFunc() {
        guard !useMockData else {
            return
        }
        
        signUp()
        
        if let user = client.activeUser {
            weak var expectationDestroyUser = expectation(description: "Destroy User")
            
            User.destroy(userId: user.userId, options: try! Options(client: client)) {
                XCTAssertTrue(Thread.isMainThread)
                
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationDestroyUser?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDestroyUser = nil
            }
            
            XCTAssertNil(client.activeUser)
        }
    }
    
    func testUserDeserialize() {
        let userId = UUID().uuidString
        let username = "test"
        let json: JsonDictionary = [
            "_id" : userId,
            "username" : username,
            "_kmd": [
                "lmt" : Date().toISO8601(),
                "ect" : Date().toISO8601(),
                "authtoken" : UUID().uuidString
            ],
            "_acl" : [
                "creator" : UUID().uuidString
            ]
        ]
        
        let user = try? client.jsonParser.parseUser(User.self, from: json)
        
        XCTAssertNotNil(user)
        
        if let user = user {
            XCTAssertEqual(user.userId, userId)
            XCTAssertEqual(user.username, username)
            
            XCTAssertNotNil(user.metadata)
            
            if let metadata = user.metadata {
                XCTAssertNotNil(metadata.lmt)
                XCTAssertNotNil(metadata.ect)
                XCTAssertNotNil(metadata.authtoken)
            }
        }
    }
    
    func testChangePassword() {
        signUp()
        
        XCTAssertNotNil(Kinvey.sharedClient.activeUser)
        
        guard let user = Kinvey.sharedClient.activeUser else {
            return
        }
        
        let store = try! DataStore<Person>.collection(.network)
        
        do {
            if useMockData {
                mockResponse(json: [
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Test"
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success(let results):
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        do {
            if useMockData {
                var json = try! client.jsonParser.toJSON(user)
                if var kmd = json["_kmd"] as? JsonDictionary {
                    kmd["authtoken"] = UUID().uuidString
                    json["_kmd"] = kmd
                }
                mockResponse(json: json)
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationChangePassword = expectation(description: "Change Password")
            
            let previousAuthtoken = user.metadata?.authtoken
            XCTAssertNotNil(previousAuthtoken)
            
            user.changePassword(newPassword: "test") { user, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(user)
                XCTAssertNil(error)
                
                XCTAssertNotNil(user?.metadata?.authtoken)
                XCTAssertNotEqual(previousAuthtoken, user?.metadata?.authtoken)
                XCTAssertEqual(Kinvey.sharedClient.activeUser?.metadata?.authtoken, user?.metadata?.authtoken)
                
                expectationChangePassword?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationChangePassword = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse(json: [
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Test"
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find() {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success(let results):
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
    }
    
    func testChangePasswordTimeoutError() {
        signUp()
        
        XCTAssertNotNil(Kinvey.sharedClient.activeUser)
        
        guard let user = Kinvey.sharedClient.activeUser else {
            return
        }
        
        let store = try! DataStore<Person>.collection(.network)
        
        do {
            if useMockData {
                mockResponse(json: [
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Test"
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success(let results):
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse(error: timeoutError)
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationChangePassword = expectation(description: "Change Password")
            
            let previousAuthtoken = user.metadata?.authtoken
            XCTAssertNotNil(previousAuthtoken)
            
            user.changePassword(newPassword: "test") { user, error in
                XCTAssertMainThread()
                XCTAssertNil(user)
                XCTAssertNotNil(error)
                XCTAssertTimeoutError(error)
                expectationChangePassword?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationChangePassword = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse(error: timeoutError)
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationChangePassword = expectation(description: "Change Password")
            
            let previousAuthtoken = user.metadata?.authtoken
            XCTAssertNotNil(previousAuthtoken)
            
            user.changePassword(newPassword: "test") {
                XCTAssertMainThread()
                switch $0 {
                case .success(let user):
                    XCTFail("A failure result is expected")
                case .failure(let error):
                    XCTAssertTimeoutError(error)
                }
                
                expectationChangePassword?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationChangePassword = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse(json: [
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Test"
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
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
                mockResponse(json: try! client.jsonParser.toJSON(user))
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationUserExists = expectation(description: "User Exists")
            
            User.get(userId: user.userId, options: nil) {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success(let user):
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
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
            
            User.get(userId: user.userId) { (user, error) -> Void in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(error)
                XCTAssertNil(user)
                
                expectationUserExists?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUserExists = nil
            }
        }
    }
    
    func testFindTimeoutError() {
        signUp()
        
        if let user = client.activeUser {
            setURLProtocol(TimeoutErrorURLProtocol.self)
            
            weak var expectationUserFind = expectation(description: "User Find")
            
            user.find(query: Query(), options: nil) {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success:
                    XCTFail("A failure result is expected")
                case .failure(let error):
                    XCTAssertTimeoutError(error)
                }
                
                expectationUserFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUserFind = nil
            }
        }
    }
    
    func testRefresh() {
        signUp(mustIncludeSocialIdentity: true)
        
        XCTAssertNotNil(client.activeUser)
        XCTAssertNotNil(client.activeUser?.socialIdentity?.kinvey?["refresh_token"])
        XCTAssertNotNil(client.keychain.user?.socialIdentity?.kinvey?["refresh_token"])
        XCTAssertEqual(client.activeUser?.socialIdentity?.kinvey?["refresh_token"] as? String, client.keychain.user?.socialIdentity?.kinvey?["refresh_token"] as? String)
        XCTAssertNotNil(client.activeUser?.socialIdentity?.kinvey?["refresh_token"] as? String)
        guard let refreshToken = client.activeUser?.socialIdentity?.kinvey?["refresh_token"] as? String else {
            return
        }
        
        XCTAssertNotNil(client.activeUser)
        guard let user = client.activeUser else {
            return
        }
        
        XCTContext.runActivity(named: "User Refresh") { activity in
            XCTAssertNil(user.email)
            
            if useMockData {
                mockResponse { request in
                    XCTAssertEqual(request.url!.path, "/user/\(self.client.appKey!)/_me")
                    let json = try! self.client.jsonParser.toJSON(user)
                    return HttpResponse(json: json)
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationRefresh = expectation(description: "Refresh")
            
            user.refresh() { result in
                XCTAssertTrue(Thread.isMainThread)
                
                switch result {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationRefresh?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRefresh = nil
            }
            
            XCTAssertNotNil(client.activeUser?.socialIdentity?.kinvey?["refresh_token"])
            XCTAssertNotNil(client.keychain.user?.socialIdentity?.kinvey?["refresh_token"])
            XCTAssertEqual(client.activeUser?.socialIdentity?.kinvey?["refresh_token"] as? String, client.keychain.user?.socialIdentity?.kinvey?["refresh_token"] as? String)
        }
        
        XCTContext.runActivity(named: "DataStore Find") { activity in
            if useMockData {
                mockResponse(json: [])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            let dataStore = try! DataStore<Person>.collection(.network)
            
            weak var expectationFind = expectation(description: "Find")
            
            dataStore.find(
                options: try! Options(
                    client: client
                )
            ) {
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
    }
    
    func testRefreshUserRefreshTokenChanged() {
        signUp(mustIncludeSocialIdentity: true)
        
        XCTAssertNotNil(client.activeUser)
        XCTAssertNotNil(client.activeUser?.socialIdentity?.kinvey?["refresh_token"])
        XCTAssertNotNil(client.keychain.user?.socialIdentity?.kinvey?["refresh_token"])
        XCTAssertEqual(client.activeUser?.socialIdentity?.kinvey?["refresh_token"] as? String, client.keychain.user?.socialIdentity?.kinvey?["refresh_token"] as? String)
        XCTAssertNotNil(client.activeUser?.metadata?.authtoken as? String)
        guard let authtoken = client.activeUser?.metadata?.authtoken as? String else {
            return
        }
        XCTAssertNotNil(client.activeUser?.socialIdentity?.kinvey?["access_token"] as? String)
        guard let accessToken = client.activeUser?.socialIdentity?.kinvey?["access_token"] as? String else {
            return
        }
        XCTAssertNotNil(client.activeUser?.socialIdentity?.kinvey?["refresh_token"] as? String)
        guard let refreshToken = client.activeUser?.socialIdentity?.kinvey?["refresh_token"] as? String else {
            return
        }
        XCTAssertNotNil(client.activeUser)
        guard let user = client.activeUser else {
            return
        }
        
        XCTContext.runActivity(named: "User Refresh") { activity in
            XCTAssertNil(user.email)
            
            if useMockData {
                mockResponse { request in
                    XCTAssertEqual(request.url!.path, "/user/\(self.client.appKey!)/_me")
                    var json = try! self.client.jsonParser.toJSON(user)
                    let _socialIdentity = json["_socialIdentity"] as? JsonDictionary
                    XCTAssertNotNil(_socialIdentity)
                    XCTAssertNotNil(_socialIdentity)
                    guard var socialIdentity = _socialIdentity else {
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    let _kinveyAuth = socialIdentity["kinveyAuth"] as? JsonDictionary
                    XCTAssertNotNil(_kinveyAuth)
                    guard var kinveyAuth = _kinveyAuth else {
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    kinveyAuth["access_token"] = UUID().uuidString
                    kinveyAuth["refresh_token"] = UUID().uuidString
                    socialIdentity["kinveyAuth"] = kinveyAuth
                    json["_socialIdentity"] = socialIdentity
                    
                    let _kmd = json["_kmd"] as? JsonDictionary
                    XCTAssertNotNil(_kmd)
                    guard var kmd = _kmd else {
                        return HttpResponse(statusCode: 404, data: Data())
                    }
                    kmd["authtoken"] = UUID().uuidString
                    json["_kmd"] = kmd
                    
                    return HttpResponse(json: json)
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationRefresh = expectation(description: "Refresh")
            
            user.refresh() { result in
                XCTAssertTrue(Thread.isMainThread)
                
                switch result {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationRefresh?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRefresh = nil
            }
            
            XCTAssertNotNil(client.activeUser?.socialIdentity?.kinvey?["refresh_token"])
            XCTAssertNotNil(client.keychain.user?.socialIdentity?.kinvey?["refresh_token"])
            XCTAssertEqual(client.activeUser?.socialIdentity?.kinvey?["refresh_token"] as? String, client.keychain.user?.socialIdentity?.kinvey?["refresh_token"] as? String)
            let newAuthtoken = client.activeUser?.metadata?.authtoken as? String
            XCTAssertEqual(newAuthtoken, authtoken)
            let newAccessToken = client.activeUser?.socialIdentity?.kinvey?["access_token"] as? String
            XCTAssertEqual(newAccessToken, accessToken)
            let newRefreshToken = client.activeUser?.socialIdentity?.kinvey?["refresh_token"] as? String
            XCTAssertEqual(newRefreshToken, refreshToken)
        }
        
        XCTContext.runActivity(named: "DataStore Find") { activity in
            if useMockData {
                mockResponse(json: [])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            let dataStore = try! DataStore<Person>.collection(.network)
            
            weak var expectationFind = expectation(description: "Find")
            
            dataStore.find(
                options: try! Options(
                    client: client
                )
            ) {
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
    }
    
    func testRefreshTimeoutError() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            XCTAssertNil(user.email)
            
            if useMockData {
                mockResponse(error: timeoutError)
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationRefresh = expectation(description: "Refresh")
            
            user.refresh() { result in
                XCTAssertTrue(Thread.isMainThread)
                
                switch result {
                case .success:
                    XCTFail("A failure result is expected")
                case .failure:
                    break
                }
                
                expectationRefresh?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRefresh = nil
            }
        }
    }
    
    func testLookup() {
        let username = UUID().uuidString
        let password = UUID().uuidString
        let email = "\(username)@kinvey.com"
        signUp(username: username, password: password)
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            do {
                if useMockData {
                    mockResponse(completionHandler: { (request) -> HttpResponse in
                        let json = try! JSONSerialization.jsonObject(with: request)
                        return HttpResponse(json: json as! JsonDictionary)
                    })
                }
                defer {
                    if useMockData { setURLProtocol(nil) }
                }
                
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
                if useMockData {
                    mockResponse(json: [
                        [
                            "_id" : user.userId,
                            "email" : user.email!,
                            "username" : user.username!
                        ]
                    ])
                }
                defer {
                    if useMockData { setURLProtocol(nil) }
                }
                
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
    
    func testLookupTimeoutError() {
        let username = UUID().uuidString
        let password = UUID().uuidString
        let email = "\(username)@kinvey.com"
        signUp(username: username, password: password)
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            do {
                if useMockData {
                    mockResponse(completionHandler: { (request) -> HttpResponse in
                        let json = try! JSONSerialization.jsonObject(with: request)
                        return HttpResponse(json: json as! JsonDictionary)
                    })
                }
                defer {
                    if useMockData { setURLProtocol(nil) }
                }
                
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
                if useMockData {
                    mockResponse(error: timeoutError)
                }
                defer {
                    if useMockData { setURLProtocol(nil) }
                }
                
                weak var expectationUserLookup = expectation(description: "User Lookup")
                
                let userQuery = UserQuery {
                    $0.username = username
                }
                
                user.lookup(userQuery) { users, error in
                    XCTAssertTrue(Thread.isMainThread)
                    XCTAssertNil(users)
                    XCTAssertNotNil(error)
                    
                    XCTAssertTimeoutError(error)
                    
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
        XCTAssertTrue(Keychain(appKey: client.appKey!, client: client).user is MyUser)
        
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
        client.userType = MyUser.self
        
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        XCTAssertTrue(client.activeUser is MyUser)
        
        if let user = client.activeUser as? MyUser {
            setURLProtocol(TimeoutErrorURLProtocol.self)
            defer {
                setURLProtocol(nil)
            }
            
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
    
    class MyCodableUser: User, Codable {
        
        @objc dynamic var foo: String?
        var nonObjCProperty: String?
        
        enum MyCodableUserCodingKeys: String, CodingKey {
            case foo
            case nonObjCProperty
        }
        
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            let container = try decoder.container(keyedBy: MyCodableUserCodingKeys.self)
            foo = try container.decodeIfPresent(String.self, forKey: .foo)
        }
        
        override func encode(to encoder: Encoder) throws {
            try super.encode(to: encoder)
            var container = encoder.container(keyedBy: MyCodableUserCodingKeys.self)
            try container.encodeIfPresent(foo, forKey: .foo)
        }
        
        init() {
            super.init()
        }
        
        required init?(map: Map) {
            super.init(map: map)
        }
        
        override func mapping(map: Map) {
            super.mapping(map: map)
            
            foo <- (MyCodableUserCodingKeys.foo.rawValue, map[MyCodableUserCodingKeys.foo])
            nonObjCProperty <- (MyCodableUserCodingKeys.nonObjCProperty.rawValue, map[MyCodableUserCodingKeys.nonObjCProperty])
        }
        
    }
    
    func testSaveCustomCodableUser() {
        client.userType = MyCodableUser.self
        defer {
            client.userType = User.self
        }
        
        XCTContext.runActivity(named: "Sign Up") { activity in
            let user = MyCodableUser()
            user.foo = "bar"
            signUp(user: user, mustIncludeSocialIdentity: true)
            
            XCTAssertNotNil(client.activeUser)
            XCTAssertTrue(client.activeUser is MyCodableUser)
            XCTAssertTrue(Keychain(appKey: client.appKey!, client: client).user is MyCodableUser)
        }
        
        guard let user = client.activeUser as? MyCodableUser else {
            return
        }
        
        XCTAssertNotNil(user.socialIdentity?.kinvey)
        let kinveyCount = user.socialIdentity?.kinvey?.count
        XCTAssertGreaterThan(kinveyCount ?? 0, 0)
        
        if useMockData {
            mockResponse(completionHandler: { (request) -> HttpResponse in
                let json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
                XCTAssertEqual(json["foo"] as? String, "bar")
                let socialIdentity = json["_socialIdentity"] as? [String : Any]
                XCTAssertNotNil(socialIdentity)
                if let socialIdentity = socialIdentity {
                    let kinvey = socialIdentity["kinveyAuth"] as? [String : Any]
                    XCTAssertNotNil(kinvey)
                    XCTAssertEqual(kinvey?.count, kinveyCount)
                }
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
            XCTAssertTrue(user is MyCodableUser)
            
            XCTAssertNotNil(self.client.activeUser)
            XCTAssertTrue(self.client.activeUser is MyCodableUser)
            
            if let myUser = user as? MyCodableUser {
                XCTAssertEqual(myUser.foo, "bar")
            }
            
            expectationUserSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationUserSave = nil
        }
    }
    
    func testRefreshCustomCodableUser() {
        client.userType = MyCodableUser.self
        defer {
            client.userType = User.self
        }
        
        signUp(mustIncludeSocialIdentity: false)
        
        XCTAssertNotNil(client.activeUser)
        XCTAssertNotNil(client.activeUser as? MyCodableUser)
        guard let user = client.activeUser as? MyCodableUser else {
            return
        }
        
        XCTContext.runActivity(named: "User Refresh") { activity in
            XCTAssertNil(user.email)
            XCTAssertNil(user.foo)
            
            if useMockData {
                mockResponse { request in
                    XCTAssertEqual(request.url!.path, "/user/\(self.client.appKey!)/_me")
                    let originalJson = try! self.client.jsonParser.toJSON(user)
                    let updatedUser = MyCodableUser(JSON: originalJson)!
                    updatedUser.email = "test@test.com"
                    updatedUser.foo = "bar"
                    let updatedJson = try! self.client.jsonParser.toJSON(updatedUser)
                    return HttpResponse(json: updatedJson)
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationRefresh = expectation(description: "Refresh")
            
            user.refresh() { result in
                XCTAssertTrue(Thread.isMainThread)
                
                switch result {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationRefresh?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRefresh = nil
            }
            
            XCTAssertEqual(user.email, "test@test.com")
            XCTAssertEqual(user.foo, "bar")
        }
    }
    
    func testUserQueryMapping() {
        XCTAssertNotNil(UserQuery(JSON: [:]))
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
                
                activeUser.destroy {
                    XCTAssertTrue(Thread.isMainThread)
                    
                    switch $0 {
                    case .success:
                        break
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
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
                
                activeUser.destroy {
                    XCTAssertTrue(Thread.isMainThread)
                    
                    switch $0 {
                    case .success:
                        break
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
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
                    let data = try! JSONSerialization.data(withJSONObject: ["userId":"123"])
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
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            XCTAssertNotNil(user.username)
            
            if let username = user.username {
                if useMockData {
                    mockResponse(json: ["usernameExists" : true])
                }
                defer {
                    if useMockData { setURLProtocol(nil) }
                }
                
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
                defer {
                    setURLProtocol(nil)
                }
                
                do {
                    weak var expectationUserExists = expectation(description: "User Exists")
                    
                    User.exists(username: username) { exists, error in
                        XCTAssertTrue(Thread.isMainThread)
                        XCTAssertFalse(exists)
                        XCTAssertTimeoutError(error)
                        
                        expectationUserExists?.fulfill()
                    }
                    
                    waitForExpectations(timeout: defaultTimeout) { error in
                        expectationUserExists = nil
                    }
                }
                
                do {
                    weak var expectationUserExists = expectation(description: "User Exists")
                    
                    User.exists(username: username, options: nil) {
                        XCTAssertTrue(Thread.isMainThread)
                        switch $0 {
                        case .success(let exists):
                            XCTAssertFalse(exists)
                            XCTFail("A failure result is expected")
                        case .failure(let error):
                            XCTAssertTimeoutError(error)
                        }
                        
                        expectationUserExists?.fulfill()
                    }
                    
                    waitForExpectations(timeout: defaultTimeout) { error in
                        expectationUserExists = nil
                    }
                }
            }
        }
    }
    
    func testDestroyTimeoutError() {
        signUp()
        
        setURLProtocol(TimeoutErrorURLProtocol.self)
        
        if let activeUser = client.activeUser {
            weak var expectationDestroy = expectation(description: "Destroy")
            
            activeUser.destroy {
                XCTAssertTrue(Thread.isMainThread)
                
                switch $0 {
                case .success:
                    XCTFail("A failure result is expected")
                case .failure:
                    break
                }
                
                expectationDestroy?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDestroy = nil
            }
        }
    }
    
    func testSendEmailConfirmation() {
        signUp(username: UUID().uuidString)
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            do {
                var json = try! client.jsonParser.toJSON(user)
                json["email"] = "victor@kinvey.com"
                mockResponse(json: json)
                defer {
                    setURLProtocol(nil)
                }
                
                weak var expectationSave = expectation(description: "Save")
                
                user.email = "victor@kinvey.com"
                user.save() { user, error in
                    XCTAssertTrue(Thread.isMainThread)
                    XCTAssertNotNil(user)
                    XCTAssertNil(error)
                    
                    expectationSave?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationSave = nil
                }
            }
            
            do {
                mockResponse(statusCode: 204, data: Data())
                defer {
                    setURLProtocol(nil)
                }
                
                weak var expectationSendEmailConfirmation = expectation(description: "Send Email Confirmation")
                
                user.sendEmailConfirmation {
                    XCTAssertTrue(Thread.isMainThread)
                    
                    switch $0 {
                    case .success:
                        break
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationSendEmailConfirmation?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationSendEmailConfirmation = nil
                }
            }
        }
    }
    
    func testSendEmailConfirmationDeprecated() {
        signUp(username: UUID().uuidString)
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            do {
                var json = try! client.jsonParser.toJSON(user)
                json["email"] = "victor@kinvey.com"
                mockResponse(json: json)
                defer {
                    setURLProtocol(nil)
                }
                
                weak var expectationSave = expectation(description: "Save")
                
                user.email = "victor@kinvey.com"
                user.save() { user, error in
                    XCTAssertTrue(Thread.isMainThread)
                    XCTAssertNotNil(user)
                    XCTAssertNil(error)
                    
                    expectationSave?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationSave = nil
                }
            }
            
            do {
                mockResponse(statusCode: 204, data: Data())
                defer {
                    setURLProtocol(nil)
                }
                
                weak var expectationSendEmailConfirmation = expectation(description: "Send Email Confirmation")
                
                User.sendEmailConfirmation(forUsername: user.username!, client: client) {
                    XCTAssertTrue(Thread.isMainThread)
                    
                    switch $0 {
                    case .success:
                        break
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationSendEmailConfirmation?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationSendEmailConfirmation = nil
                }
            }
        }
    }
    
    func testSendEmailConfirmationWithoutEmail() {
        signUp(username: UUID().uuidString)
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            mockResponse(statusCode: 204, data: Data())
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationSendEmailConfirmation = expectation(description: "Send Email Confirmation")
            
            user.sendEmailConfirmation {
                XCTAssertTrue(Thread.isMainThread)
                
                switch $0 {
                case .success:
                    XCTFail("A failure result is expected")
                case .failure(let error):
                    XCTAssertTrue(error is Kinvey.Error)
                    if let error = error as? Kinvey.Error {
                        XCTAssertEqual(error.description, "Email is required to send the email confirmation")
                        switch error {
                        case .invalidOperation(let description):
                            XCTAssertEqual(description, "Email is required to send the email confirmation")
                        default:
                            XCTFail(error.localizedDescription)
                        }
                    }
                }
                
                expectationSendEmailConfirmation?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationSendEmailConfirmation = nil
            }
        }
    }
    
    func testSendEmailConfirmationTimeoutError() {
        signUp(username: UUID().uuidString)
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            do {
                var json = try! client.jsonParser.toJSON(user)
                json["email"] = "victor@kinvey.com"
                mockResponse(json: json)
                defer {
                    setURLProtocol(nil)
                }
                
                weak var expectationSave = expectation(description: "Save")
                
                user.email = "victor@kinvey.com"
                user.save() { user, error in
                    XCTAssertTrue(Thread.isMainThread)
                    XCTAssertNotNil(user)
                    XCTAssertNil(error)
                    
                    expectationSave?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationSave = nil
                }
            }
            
            do {
                mockResponse(error: timeoutError)
                defer {
                    setURLProtocol(nil)
                }
                
                weak var expectationSendEmailConfirmation = expectation(description: "Send Email Confirmation")
                
                user.sendEmailConfirmation {
                    XCTAssertTrue(Thread.isMainThread)
                    
                    switch $0 {
                    case .success:
                        XCTFail("A failure result is expected")
                    case .failure(let error):
                        let error = error as NSError
                        XCTAssertEqual(error.domain, NSURLErrorDomain)
                        XCTAssertEqual(error.code, NSURLErrorTimedOut)
                    }
                    
                    expectationSendEmailConfirmation?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationSendEmailConfirmation = nil
                }
            }
        }
    }
    
    func testUserMetadata() {
        signUp()
        
        if useMockData {
            mockResponse(completionHandler: { (request) -> HttpResponse in
                let userId = request.url?.lastPathComponent
                
                return HttpResponse(json: [
                    "_id" : userId!,
                    "username" : "test",
                    "_acl": [
                        "creator" : "582b81b95c84a5525e9abcc9"
                    ],
                    "email" : "tejas@kinvey.com",
                    "_kmd" : [
                        "lmt" : "2016-11-15T21:44:37.302Z",
                        "ect" : "2016-11-15T21:44:25.756Z",
                        "status" : [
                            "val" : "disabled",
                            "lastChange" : "2016-11-16T15:08:52.225Z"
                        ],
                        "passwordReset" : [
                            "status" : "InProgress",
                            "lastStateChangeAt" : "2012-10-10T19:56:03.282Z"
                        ],
                        "emailVerification" : [
                            "status" : "confirmed",
                            "lastStateChangeAt" : "2012-10-10T19:56:03.282Z",
                            "lastConfirmedAt" : "2012-10-10T19:56:03.282Z",
                            "emailAddress" : "johndoe@kinvey.com"
                        ]
                    ]
                ])
            })
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationUserMetadata = expectation(description: "Email Confirmation Status")
        let user = Client.sharedClient.activeUser
        
        XCTAssertNotNil(user?.userId)
        guard let userId = user?.userId else {
            return
        }
        
        User.get(userId: userId) { newUser, error in
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
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            do {
                if useMockData {
                    var json = try! client.jsonParser.toJSON(user)
                    if var kmd = json["_kmd"] as? JsonDictionary {
                        kmd["authtoken"] = UUID().uuidString
                        json["_kmd"] = kmd
                    }
                    mockResponse(json: json)
                }
                defer {
                    if useMockData {
                        setURLProtocol(nil)
                    }
                }
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
            }
            
            if useMockData {
                mockResponse(statusCode: 204, data: Data())
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationResetPassword = expectation(description: "Reset Password")
            
            user.resetPassword {
                XCTAssertTrue(Thread.isMainThread)
                
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationResetPassword?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationResetPassword = nil
            }
        }
    }
    
    func testResetPasswordByUsername() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            if useMockData {
                mockResponse(statusCode: 204, data: Data())
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationResetPassword = expectation(description: "Reset Password")
            
            user.resetPassword {
                XCTAssertTrue(Thread.isMainThread)
                
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationResetPassword?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationResetPassword = nil
            }
        }
    }
    
    func testResetPasswordByUsernameClassFunc() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            if useMockData {
                mockResponse(statusCode: 204, data: Data())
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationResetPassword = expectation(description: "Reset Password")
            
            User.resetPassword(usernameOrEmail: user.username!, options: nil) {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationResetPassword?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationResetPassword = nil
            }
        }
    }
    
    func testResetPasswordByUsernameClassFuncTimeoutError() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            if useMockData {
                mockResponse(error: timeoutError)
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationResetPassword = expectation(description: "Reset Password")
            
            User.resetPassword(usernameOrEmail: user.username!, client: sharedClient) {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success:
                    XCTFail("A failure result is expected")
                case .failure(let error):
                    XCTAssertTimeoutError(error)
                }
                
                expectationResetPassword?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationResetPassword = nil
            }
        }
    }
    
    func testResetPasswordByEmailClassFunc() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            if useMockData {
                mockResponse(statusCode: 204, data: Data())
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            user.email = "me@kinvey.com"
            
            weak var expectationResetPassword = expectation(description: "Reset Password")
            
            User.resetPassword(usernameOrEmail: user.email!, options: nil) {
                XCTAssertTrue(Thread.isMainThread)
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationResetPassword?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationResetPassword = nil
            }
        }
    }
    
    func testResetPasswordNoEmailOrUsername() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            do {
                user.username = nil
                
                if useMockData {
                    mockResponse(json: try! client.jsonParser.toJSON(user))
                }
                defer {
                    if useMockData {
                        setURLProtocol(nil)
                    }
                }
                
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
            }
            
            do {
                if useMockData {
                    mockResponse(statusCode: 204, data: Data())
                }
                defer {
                    if useMockData {
                        setURLProtocol(nil)
                    }
                }
                
                weak var expectationResetPassword = expectation(description: "Reset Password")
                
                user.resetPassword {
                    XCTAssertTrue(Thread.isMainThread)
                    
                    switch $0 {
                    case .success:
                        XCTFail("A failure result is expected")
                    case .failure:
                        break
                    }
                    
                    expectationResetPassword?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationResetPassword = nil
                }
            }
        }
    }
    
    func testResetPasswordTimeoutError() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            setURLProtocol(TimeoutErrorURLProtocol.self)
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationResetPassword = expectation(description: "Reset Password")
            
            user.resetPassword {
                XCTAssertTrue(Thread.isMainThread)
                
                switch $0 {
                case .success:
                    XCTFail("A failure result is expected")
                case .failure:
                    break
                }
                
                expectationResetPassword?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationResetPassword = nil
            }
        }
    }
    
    func testForgotUsername() {
        signUp()
        
        XCTAssertNotNil(Kinvey.sharedClient.activeUser)
        
        if let user = Kinvey.sharedClient.activeUser {
            user.email = "\(UUID().uuidString)@kinvey.com"
            
            do {
                if useMockData {
                    mockResponse(json: try! client.jsonParser.toJSON(user))
                }
                defer {
                    if useMockData { setURLProtocol(nil) }
                }
                
                weak var expectationSave = expectation(description: "Save")
                
                user.save() { user, error in
                    XCTAssertTrue(Thread.isMainThread)
                    XCTAssertNotNil(user)
                    XCTAssertNil(error)
                    
                    expectationSave?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationSave = nil
                }
            }
            
            do {
                if useMockData {
                    mockResponse(statusCode: 204, data: Data())
                }
                defer {
                    if useMockData { setURLProtocol(nil) }
                }
                
                weak var expectationForgotUsername = expectation(description: "Forgot Username")
                
                User.forgotUsername(email: user.email!, client: client) {
                    XCTAssertTrue(Thread.isMainThread)
                    
                    switch $0 {
                    case .success:
                        break
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationForgotUsername?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationForgotUsername = nil
                }
            }
        }
    }
    
    func testForgotUsernameTimeoutError() {
        setURLProtocol(TimeoutErrorURLProtocol.self)
        
        weak var expectationForgotUsername = expectation(description: "Forgot Username")
        
        User.forgotUsername(email: "\(UUID().uuidString)@kinvey.com", options: nil) {
            XCTAssertTrue(Thread.isMainThread)
            
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure:
                break
            }
            
            expectationForgotUsername?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationForgotUsername = nil
        }
    }
    
    func testFacebookLogin() {
        mockResponse { (request) -> HttpResponse in
            let userId = "503bc9806065332d6f000005"
            let jsonResponse: [String : Any] = [
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
            return HttpResponse(statusCode: 201, headerFields: ["Location" : "https://baas.kinvey.com/user/:appKey/\(userId)"], json: jsonResponse)
        }
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFacebookLogin = expectation(description: "Facebook Login")
        
        let fakeFacebookData = [
            "access_token": "AAAD30ogoDZCYBAKS50rOwCxMR7tIX8F90YDyC3vp63j0IvyCU0MELE2QMLnsWXKo2LcRgwA51hFr1UUpqXkSHu4lCj4VZCIuGG7DHZAHuZArzjvzTZAwQ",
            "expires": "5105388"
        ]
        User.login(authSource: .facebook, fakeFacebookData) {
            switch $0 {
            case .success(let user):
                XCTAssertNotNil(user.socialIdentity)
                XCTAssertNotNil(user.socialIdentity?.facebook)
                XCTAssertEqual(user.socialIdentity?.facebook?["id"] as? String, "100004289534145")
                XCTAssertEqual(user.socialIdentity?.facebook?["name"] as? String, "Kois Steel")
                XCTAssertEqual(user.socialIdentity?.facebook?["gender"] as? String, "female")
                XCTAssertEqual(user.socialIdentity?.facebook?["email"] as? String, "kois.steel@testFB.net")
                XCTAssertEqual(user.socialIdentity?.facebook?["birthday"] as? String, "2012/08/20")
                XCTAssertEqual(user.socialIdentity?.facebook?["location"] as? String, "Cambridge, USA")
                
                let user = Keychain(appKey: Kinvey.sharedClient.appKey!, client: Kinvey.sharedClient).user
                XCTAssertNotNil(user)
                if let user = user {
                    XCTAssertNotNil(user.socialIdentity)
                    XCTAssertNotNil(user.socialIdentity?.facebook)
                    XCTAssertEqual(user.socialIdentity?.facebook?["id"] as? String, "100004289534145")
                    XCTAssertEqual(user.socialIdentity?.facebook?["name"] as? String, "Kois Steel")
                    XCTAssertEqual(user.socialIdentity?.facebook?["gender"] as? String, "female")
                    XCTAssertEqual(user.socialIdentity?.facebook?["email"] as? String, "kois.steel@testFB.net")
                    XCTAssertEqual(user.socialIdentity?.facebook?["birthday"] as? String, "2012/08/20")
                    XCTAssertEqual(user.socialIdentity?.facebook?["location"] as? String, "Cambridge, USA")
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationFacebookLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFacebookLogin = nil
        }
        
        client.activeUser = nil
    }
    
    func testFacebookLoginDeprecated() {
        mockResponse { (request) -> HttpResponse in
            let userId = "503bc9806065332d6f000005"
            let jsonResponse: [String : Any] = [
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
            return HttpResponse(statusCode: 201, headerFields: ["Location" : "https://baas.kinvey.com/user/:appKey/\(userId)"], json: jsonResponse)
        }
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
            if let user = user {
                XCTAssertNotNil(user.socialIdentity)
                XCTAssertNotNil(user.socialIdentity?.facebook)
                XCTAssertEqual(user.socialIdentity?.facebook?["id"] as? String, "100004289534145")
                XCTAssertEqual(user.socialIdentity?.facebook?["name"] as? String, "Kois Steel")
                XCTAssertEqual(user.socialIdentity?.facebook?["gender"] as? String, "female")
                XCTAssertEqual(user.socialIdentity?.facebook?["email"] as? String, "kois.steel@testFB.net")
                XCTAssertEqual(user.socialIdentity?.facebook?["birthday"] as? String, "2012/08/20")
                XCTAssertEqual(user.socialIdentity?.facebook?["location"] as? String, "Cambridge, USA")
                
                let user = Keychain(appKey: Kinvey.sharedClient.appKey!, client: Kinvey.sharedClient).user
                XCTAssertNotNil(user)
                if let user = user {
                    XCTAssertNotNil(user.socialIdentity)
                    XCTAssertNotNil(user.socialIdentity?.facebook)
                    XCTAssertEqual(user.socialIdentity?.facebook?["id"] as? String, "100004289534145")
                    XCTAssertEqual(user.socialIdentity?.facebook?["name"] as? String, "Kois Steel")
                    XCTAssertEqual(user.socialIdentity?.facebook?["gender"] as? String, "female")
                    XCTAssertEqual(user.socialIdentity?.facebook?["email"] as? String, "kois.steel@testFB.net")
                    XCTAssertEqual(user.socialIdentity?.facebook?["birthday"] as? String, "2012/08/20")
                    XCTAssertEqual(user.socialIdentity?.facebook?["location"] as? String, "Cambridge, USA")
                }
            }
            
            expectationFacebookLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFacebookLogin = nil
        }
        
        client.activeUser = nil
    }
    
    func testFacebookLoginTimeout() {
        setURLProtocol(TimeoutErrorURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFacebookLogin = expectation(description: "Facebook Login")
        
        let fakeFacebookData = [
            "access_token": "AAAD30ogoDZCYBAKS50rOwCxMR7tIX8F90YDyC3vp63j0IvyCU0MELE2QMLnsWXKo2LcRgwA51hFr1UUpqXkSHu4lCj4VZCIuGG7DHZAHuZArzjvzTZAwQ",
            "expires": "5105388"
        ]
        User.login(authSource: .facebook, fakeFacebookData) { user, error in
            XCTAssertNil(user)
            XCTAssertNotNil(error)
            
            if let error = error {
                let error = error as NSError
                XCTAssertEqual(error.domain, NSURLErrorDomain)
                XCTAssertEqual(error.code, NSURLErrorTimedOut)
            }
            
            expectationFacebookLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFacebookLogin = nil
        }
        
        client.activeUser = nil
    }
    
    func testFacebookLoginCreateTimeout() {
        var count = 0
        mockResponse { (request) -> HttpResponse in
            defer {
                count += 1
            }
            switch count {
            case 0:
                return HttpResponse(statusCode: 404, data: Data())
            case 1:
                return HttpResponse(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil))
            default:
                Swift.fatalError()
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFacebookLogin = expectation(description: "Facebook Login")
        
        let fakeFacebookData = [
            "access_token": "AAAD30ogoDZCYBAKS50rOwCxMR7tIX8F90YDyC3vp63j0IvyCU0MELE2QMLnsWXKo2LcRgwA51hFr1UUpqXkSHu4lCj4VZCIuGG7DHZAHuZArzjvzTZAwQ",
            "expires": "5105388"
        ]
        User.login(authSource: .facebook, fakeFacebookData) { user, error in
            XCTAssertNil(user)
            XCTAssertNotNil(error)
            
            if let error = error {
                let error = error as NSError
                XCTAssertEqual(error.domain, NSURLErrorDomain)
                XCTAssertEqual(error.code, NSURLErrorTimedOut)
            }
            
            expectationFacebookLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFacebookLogin = nil
        }
        
        client.activeUser = nil
    }
    
    func testFacebookLoginWithoutClientInitialization() {
        setURLProtocol(TimeoutErrorURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        let client = Client()
        
        weak var expectationFacebookLogin = expectation(description: "Facebook Login")
        
        let fakeFacebookData = [
            "access_token": "AAAD30ogoDZCYBAKS50rOwCxMR7tIX8F90YDyC3vp63j0IvyCU0MELE2QMLnsWXKo2LcRgwA51hFr1UUpqXkSHu4lCj4VZCIuGG7DHZAHuZArzjvzTZAwQ",
            "expires": "5105388"
        ]
        User.login(authSource: .facebook, fakeFacebookData, client: client) { user, error in
            XCTAssertNil(user)
            XCTAssertNotNil(error)
            
            if let error = error {
                XCTAssertTrue(error is Kinvey.Error)
                
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .clientNotInitialized:
                        break
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            
            expectationFacebookLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFacebookLogin = nil
        }
        
        client.activeUser = nil
    }
    
    func testLoginWithUsernameAndPasswordTimeout() {
        setURLProtocol(TimeoutErrorURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationLogin = expectation(description: "Login")
        
        User.login(
            username: UUID().uuidString,
            password: UUID().uuidString
        ) { user, error in
            XCTAssertNil(user)
            XCTAssertNotNil(error)
            
            if let error = error {
                let error = error as NSError
                XCTAssertEqual(error.domain, NSURLErrorDomain)
                XCTAssertEqual(error.code, NSURLErrorTimedOut)
            }
            
            expectationLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationLogin = nil
        }
        
        client.activeUser = nil
    }
    
    func testLoginWithUsernameAndPasswordWithoutClientInitialization() {
        setURLProtocol(TimeoutErrorURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        let client = Client()
        
        weak var expectationLogin = expectation(description: "Login")
        
        User.login(
            username: UUID().uuidString,
            password: UUID().uuidString,
            client: client
        ) { user, error in
            XCTAssertNil(user)
            XCTAssertNotNil(error)
            
            if let error = error {
                XCTAssertTrue(error is Kinvey.Error)
                
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .clientNotInitialized:
                        break
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            
            expectationLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationLogin = nil
        }
        
        client.activeUser = nil
    }
    
    func find() {
        XCTAssertNotNil(Kinvey.sharedClient.activeUser)
        
        if Kinvey.sharedClient.activeUser != nil {
            let store = try! DataStore<Person>.collection(.network)
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find {
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
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
            static let refreshToken = "dc6118e98b8c004a6e2d3e2aa985f57e40a87a02"
            lazy var code: String = MICLoginAutomatedAuthorizationGrantFlowURLProtocol.code
            lazy var tempLoginUri: String = MICLoginAutomatedAuthorizationGrantFlowURLProtocol.tempLoginUri
            lazy var refreshToken: String = MICLoginAutomatedAuthorizationGrantFlowURLProtocol.refreshToken
            static var count = 0
            
            override class func canInit(with request: URLRequest) -> Bool {
                while MockURLProtocol.running {
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                }
                return true
            }
            
            override class func canInit(with request: URLSessionTask) -> Bool {
                while MockURLProtocol.running {
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                }
                return true
            }
            
            override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                while MockURLProtocol.running {
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                }
                return request
            }
            
            override func startLoading() {
                while MockURLProtocol.running {
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                }
                MockURLProtocol.running = true
                switch type(of: self).count {
                case 0:
                    XCTAssertEqual(request.url!, URL(string: "https://auth.kinvey.com/v3/oauth/auth"))
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "temp_login_uri" : tempLoginUri
                    ]
                    let data = try! JSONSerialization.data(withJSONObject: json)
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
                    XCTAssertEqual(request.url!, URL(string: "https://auth.kinvey.com/v3/oauth/token"))
                    XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], Kinvey.sharedClient.authorizationHeader)
                    switch Body.buildFormUrlEncoded(body: request.httpBodyString) {
                    case .formUrlEncoded(let params):
                        XCTAssertEqual(params, [
                            "client_id" : MockKinveyBackend.kid,
                            "code" : code,
                            "redirect_uri" : "micAuthGrantFlow%3A%2F%2F",
                            "grant_type" : "authorization_code"
                        ])
                    default:
                        XCTFail("A form URL encoded is expected")
                    }
                    
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "access_token" : "7f3fe7847a7292994c87fa322405cb8e03b7bf9c",
                        "token_type" : "bearer",
                        "expires_in" : 3599,
                        "refresh_token" : refreshToken
                    ] as [String : Any]
                    let data = try! JSONSerialization.data(withJSONObject: json)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 3:
                    XCTAssertEqual(request.url!, URL(string: "https://baas.kinvey.com/user/_kid_/login"))
                    let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "error" : "UserNotFound",
                        "description" : "This user does not exist for this app backend",
                        "debug" : ""
                    ]
                    let data = try! JSONSerialization.data(withJSONObject: json)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 4:
                    XCTAssertEqual(request.url!, URL(string: "https://baas.kinvey.com/user/_kid_"))
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
                    let data = try! JSONSerialization.data(withJSONObject: json)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 5:
                    XCTAssertEqual(request.url!, URL(string: "https://baas.kinvey.com/appdata/_kid_/Person/"))
                    let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "error" : "InvalidCredentials",
                        "description" : "Invalid credentials. Please retry your request with correct credentials",
                        "debug" : "Error encountered authenticating against kinveyAuth: {\"error\":\"server_error\",\"error_description\":\"Access Token not found\"}"
                    ]
                    let data = try! JSONSerialization.data(withJSONObject: json)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 6:
                    XCTAssertEqual(request.url!, URL(string: "https://auth.kinvey.com/v3/oauth/token"))
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "access_token" : "7f3fe7847a7292994c87fa322405cb8e03b7bf9c",
                        "token_type" : "bearer",
                        "expires_in" : 3599,
                        "refresh_token" : "dc6118e98b8c004a6e2d3e2aa985f57e40a87a02"
                    ] as [String : Any]
                    let data = try! JSONSerialization.data(withJSONObject: json)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 7:
                    XCTAssertEqual(request.url!, URL(string: "https://baas.kinvey.com/user/_kid_/login"))
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
                    let data = try! JSONSerialization.data(withJSONObject: json)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 8:
                    XCTAssertEqual(request.url!, URL(string: "https://baas.kinvey.com/appdata/_kid_/Person/"))
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [[String : Any]]()
                    let data = try! JSONSerialization.data(withJSONObject: json)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                default:
                    XCTFail("Mock request not handled. Request: \(request)")
                }
                type(of: self).count += 1
            }
            
            override func stopLoading() {
                MockURLProtocol.running = false
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
        
        guard let user = client.activeUser else {
            return
        }
        
        XCTAssertEqual(user.refreshToken, MICLoginAutomatedAuthorizationGrantFlowURLProtocol.refreshToken)
        
        do {
            let store = try! DataStore<Person>.collection(.network)
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find {
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
    }
    
    func testMICLoginAutomatedAuthorizationGrantFlowWithAuthServiceID() {
        if let user = client.activeUser {
            user.logout()
        }
        defer {
            if let user = client.activeUser {
                user.logout()
            }
        }
        
        class MICLoginAutomatedAuthorizationGrantFlowURLProtocol: URLProtocol {
        
            static let authServiceId = UUID().uuidString
            static let code = "7af647ad1414986bec71d7799ced85fd271050a8"
            static let tempLoginUri = "https://auth.kinvey.com/oauth/authenticate/b3ca941c1141468bb19d2f2c7409f7a6"
            lazy var code: String = MICLoginAutomatedAuthorizationGrantFlowURLProtocol.code
            lazy var tempLoginUri: String = MICLoginAutomatedAuthorizationGrantFlowURLProtocol.tempLoginUri
            static var count = 0
            
            override class func canInit(with request: URLRequest) -> Bool {
                while MockURLProtocol.running {
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                }
                return true
            }
            
            override class func canInit(with task: URLSessionTask) -> Bool {
                while MockURLProtocol.running {
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                }
                return true
            }
            
            override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                while MockURLProtocol.running {
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                }
                return request
            }
            
            override func startLoading() {
                while MockURLProtocol.running {
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                }
                MockURLProtocol.running = true
                switch type(of: self).count {
                case 0:
                    XCTAssertEqual(request.url, URL(string: "https://auth.kinvey.com/v3/oauth/auth"))
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "temp_login_uri" : tempLoginUri
                    ]
                    let data = try! JSONSerialization.data(withJSONObject: json)
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
                    XCTAssertEqual(request.url, URL(string: "https://auth.kinvey.com/v3/oauth/token"))
                    XCTAssertNotEqual(request.allHTTPHeaderFields?["Authorization"], Kinvey.sharedClient.authorizationHeader)
                    let token = "\(Kinvey.sharedClient.appKey!).\(MICLoginAutomatedAuthorizationGrantFlowURLProtocol.authServiceId):\(Kinvey.sharedClient.appSecret!)".data(using: String.Encoding.utf8)?.base64EncodedString()
                    XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Basic \(token!)")
                    switch Body.buildFormUrlEncoded(body: request.httpBodyString) {
                    case .formUrlEncoded(let params):
                        XCTAssertEqual(params, [
                            "client_id" : "\(MockKinveyBackend.kid).\(MICLoginAutomatedAuthorizationGrantFlowURLProtocol.authServiceId)",
                            "code" : code,
                            "redirect_uri" : "micAuthGrantFlow%3A%2F%2F",
                            "grant_type" : "authorization_code"
                        ])
                    default:
                        XCTFail("Mock request not handled. Request: \(request)")
                    }
                    
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "access_token" : "7f3fe7847a7292994c87fa322405cb8e03b7bf9c",
                        "token_type" : "bearer",
                        "expires_in" : 3599,
                        "refresh_token" : "dc6118e98b8c004a6e2d3e2aa985f57e40a87a02"
                    ] as [String : Any]
                    let data = try! JSONSerialization.data(withJSONObject: json)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 3:
                    XCTAssertEqual(request.url, URL(string: "https://baas.kinvey.com/user/_kid_/login"))
                    let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "error" : "UserNotFound",
                        "description" : "This user does not exist for this app backend",
                        "debug" : ""
                    ]
                    let data = try! JSONSerialization.data(withJSONObject: json)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 4:
                    XCTAssertEqual(request.url, URL(string: "https://baas.kinvey.com/user/_kid_"))
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
                    let data = try! JSONSerialization.data(withJSONObject: json)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 5:
                    XCTAssertEqual(request.url, URL(string: "https://baas.kinvey.com/appdata/_kid_/Person/"))
                    let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "error" : "InvalidCredentials",
                        "description" : "Invalid credentials. Please retry your request with correct credentials",
                        "debug" : "Error encountered authenticating against kinveyAuth: {\"error\":\"server_error\",\"error_description\":\"Access Token not found\"}"
                    ]
                    let data = try! JSONSerialization.data(withJSONObject: json)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 6:
                    XCTAssertEqual(request.url, URL(string: "https://auth.kinvey.com/v3/oauth/token"))
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "access_token" : "7f3fe7847a7292994c87fa322405cb8e03b7bf9c",
                        "token_type" : "bearer",
                        "expires_in" : 3599,
                        "refresh_token" : "dc6118e98b8c004a6e2d3e2aa985f57e40a87a02"
                    ] as [String : Any]
                    let data = try! JSONSerialization.data(withJSONObject: json)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 7:
                    XCTAssertEqual(request.url, URL(string: "https://baas.kinvey.com/user/_kid_/login"))
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
                    let data = try! JSONSerialization.data(withJSONObject: json)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case 8:
                    XCTAssertEqual(request.url, URL(string: "https://baas.kinvey.com/appdata/_kid_/Person/"))
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [[String : Any]]()
                    let data = try! JSONSerialization.data(withJSONObject: json)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                default:
                    XCTFail("Mock request not handled. Request: \(request)")
                }
                type(of: self).count += 1
            }
            
            override func stopLoading() {
                MockURLProtocol.running = false
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
            password: "1234",
            authServiceId: MICLoginAutomatedAuthorizationGrantFlowURLProtocol.authServiceId
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
            let store = try! DataStore<Person>.collection(.network)
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find {
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
    }
    
    func testMICRefreshTokenMultipleCalls() {
        signUp(mustIncludeSocialIdentity: true)
        
        XCTAssertNotNil(Kinvey.sharedClient.activeUser)
        guard let user = Kinvey.sharedClient.activeUser else {
            return
        }
        
        XCTAssertNotNil(user.metadata?.authtoken)
        guard let authtoken = user.metadata?.authtoken else {
            return
        }
        
        XCTAssertNotNil(user.authorizationHeader)
        guard let authorizationHeader = user.authorizationHeader else {
            return
        }
        
        let newAuthToken = UUID().uuidString
        let newRefreshToken = UUID().uuidString
        
        var requests = [String]()
        mockResponse { request in
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            requests.append(urlComponents.path)
            let authorization = request.allHTTPHeaderFields!["Authorization"]!
            if authorization == authorizationHeader {
                return HttpResponse(
                    statusCode: 401,
                    json: [:]
                )
            }
            switch urlComponents.path {
            case "/user/_kid_/id1":
                return HttpResponse(json: [
                    "_id" : "id1",
                    "username" : "user1"
                ])
            case "/user/_kid_/id2":
                return HttpResponse(json: [
                    "_id" : "id2",
                    "username" : "user2"
                ])
            case "/user/_kid_/id3":
                return HttpResponse(json: [
                    "_id" : "id3",
                    "username" : "user3"
                ])
            case "/v3/oauth/token":
                return HttpResponse(json: [
                    "access_token" : UUID().uuidString,
                    "token_type" : "Bearer",
                    "expires_in" : 3599,
                    "refresh_token" : newRefreshToken
                ])
            case "/user/_kid_/login":
                let userId = user.userId
                let user = [
                    "_socialIdentity" : [
                        "kinveyAuth" : [
                            "id" : "custom",
                            "access_token" : UUID().uuidString,
                            "refresh_token" : UUID().uuidString
                        ]
                    ],
                    "password" : UUID().uuidString,
                    "username" : UUID().uuidString,
                    "_kmd" : [
                        "lmt" : Date().toISO8601(),
                        "ect" : Date().toISO8601(),
                        "authtoken" : newAuthToken
                    ],
                    "_id" : userId,
                    "_acl" : [
                        "creator" : UUID().uuidString
                    ]
                ] as [String : Any]
                MockKinveyBackend.user[userId] = user
                return HttpResponse(statusCode: 201, json: user)
            default:
                XCTFail(urlComponents.path)
                return HttpResponse(
                    statusCode: 404,
                    json: [:]
                )
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        weak var user1Expectation = expectation(description: "User 1")
        
        User.get(userId: "id1", options: nil) {
            switch $0 {
            case .success(let user):
                XCTAssertEqual(user.username, "user1")
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            user1Expectation?.fulfill()
        }
        
        weak var user2Expectation = expectation(description: "User 2")
        
        User.get(userId: "id2", options: nil) {
            switch $0 {
            case .success(let user):
                XCTAssertEqual(user.username, "user2")
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            user2Expectation?.fulfill()
        }
        
        weak var user3Expectation = expectation(description: "User 3")
        
        User.get(userId: "id3", options: nil) {
            switch $0 {
            case .success(let user):
                XCTAssertEqual(user.username, "user3")
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            user3Expectation?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout * 3) { (error) in
            XCTAssertNil(error)
            if let error = error {
                XCTFail(error.localizedDescription)
            }
        }
        
        XCTAssertEqual(requests.count, 8)
        if let request = requests.first {
            XCTAssertTrue(request.starts(with: "/user/_kid_/id"))
        }
        XCTAssertEqual(requests.filter { $0 == "/v3/oauth/token" }.count, 1)
        XCTAssertEqual(requests.filter { $0 == "/user/_kid_/login" }.count, 1)
        if requests.count > 5 {
            XCTAssertTrue(requests[5].starts(with: "/user/_kid_/id"))
        }
        if requests.count > 6 {
            XCTAssertTrue(requests[6].starts(with: "/user/_kid_/id"))
        }
        if requests.count > 7 {
            XCTAssertTrue(requests[7].starts(with: "/user/_kid_/id"))
        }
        
        XCTAssertNotNil(Kinvey.sharedClient.activeUser)
        guard let user2 = Kinvey.sharedClient.activeUser else {
            return
        }
        
        XCTAssertEqual(newAuthToken, user2.metadata?.authtoken)
        XCTAssertEqual(newRefreshToken, user2.refreshToken)
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
                    let data = try! JSONSerialization.data(withJSONObject: json)
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
                        XCTFail("Mock request not handled. Request: \(request)")
                    }
                    
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "access_token" : "7f3fe7847a7292994c87fa322405cb8e03b7bf9c",
                        "token_type" : "bearer",
                        "expires_in" : 3599,
                        "refresh_token" : "dc6118e98b8c004a6e2d3e2aa985f57e40a87a02"
                    ] as [String : Any]
                    let data = try! JSONSerialization.data(withJSONObject: json)
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
                    let data = try! JSONSerialization.data(withJSONObject: json)
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
                    let data = try! JSONSerialization.data(withJSONObject: json)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                default:
                    type(of: self).invalidCredentialsCount += 1
                    XCTAssertLessThanOrEqual(type(of: self).invalidCredentialsCount, 4)
                    let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    let json = [
                        "error" : "InvalidCredentials",
                        "description" : "Invalid credentials. Please retry your request with correct credentials",
                        "debug" : "Error encountered authenticating against kinveyAuth: {\"error\":\"server_error\",\"error_description\":\"Access Token not found\"}"
                    ]
                    let data = try! JSONSerialization.data(withJSONObject: json)
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
            let store = try! DataStore<Person>.collection(.network)
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find {
                switch $0 {
                case .success:
                    XCTFail("A failure result is expected")
                case .failure:
                    break
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
    }
    
    func testMICLoginResourceOwnerCredentialGrant() {
        if useMockData {
            let accessToken = UUID().uuidString
            let refreshToken = UUID().uuidString
            mockResponse { (request) -> HttpResponse in
                switch request.url!.path {
                case "/v3/oauth/token":
                    return HttpResponse(json: [
                        "access_token" : accessToken,
                        "token_type" : "Bearer",
                        "expires_in" : 3599,
                        "refresh_token" : refreshToken
                        ])
                case "/user/_kid_/login":
                    let userId = UUID().uuidString
                    let user = [
                        "_socialIdentity" : [
                            "kinveyAuth" : [
                                "id" : "custom",
                                "access_token" : accessToken,
                                "refresh_token" : refreshToken
                            ]
                        ],
                        "password" : UUID().uuidString,
                        "username" : UUID().uuidString,
                        "_kmd" : [
                            "lmt" : Date().toISO8601(),
                            "ect" : Date().toISO8601(),
                            "authtoken" : UUID().uuidString
                        ],
                        "_id" : userId,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ]
                    ] as [String : Any]
                    MockKinveyBackend.user[userId] = user
                    return HttpResponse(statusCode: 201, json: user)
                case "/appdata/_kid_/Person":
                    return HttpResponse(json: [
                        [
                            "_id": UUID().uuidString,
                            "name": "Test",
                            "age": 18,
                            "_acl": [
                                "creator": UUID().uuidString
                            ],
                            "_kmd": [
                                "lmt": Date().toISO8601(),
                                "ect": Date().toISO8601()
                            ]
                        ]
                    ])
                default:
                    XCTFail(request.url!.path)
                    return HttpResponse(statusCode: 404, data: Data())
                }
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationLogin = expectation(description: "Login")
        
        User.login(
            username: "custom",
            password: "1234",
            provider: .mic
        ) {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationLogin = nil
        }
        
        XCTAssertNotNil(Kinvey.sharedClient.activeUser)
        
        do {
            let store = try! DataStore<Person>.collection(.network)
            
            weak var expectationFind = expectation(description: "Find")
            
            store.find(options: nil) { (result: Result<AnyRandomAccessCollection<Person>, Swift.Error>) in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
    }
    
    func testClientNotInitialized() {
        let client = Client()
        
        weak var expectationSignUp = expectation(description: "Sign Up")
        
        User.signup(client: client) { (result: Result<User, Swift.Error>) in
            XCTAssertTrue(Thread.isMainThread)
            
            switch result {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTrue(error is Kinvey.Error)
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .clientNotInitialized:
                        XCTAssertEqual(error.description, "Client is not initialized. Please call the initialize() method to initialize the client and try again.")
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            
            expectationSignUp?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationSignUp = nil
        }
    }
    
    func testMICParseCode() {
        let redirectURI = URL(string: "myCustomURIScheme://")!
        let url = URL(string: "myCustomURIScheme://?code_not_present=1234")!
        switch MIC.parseCode(redirectURI: redirectURI, url: url) {
        case .success(let code):
            XCTFail(code)
        case .failure(let error):
            XCTAssertNil(error)
        }
    }
    
    func testMICLoginTimeout() {
        setURLProtocol(TimeoutErrorURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationLogin = expectation(description: "Login")
        
        MIC.login(
            redirectURI: URL(string: "myCustomURIScheme://")!,
            code: "1234",
            options: try! Options(
                authServiceId: nil
            )
        ) { result in
            XCTAssertTrue(Thread.isMainThread)
            
            switch result {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                let error = error as NSError
                XCTAssertEqual(error.domain, NSURLErrorDomain)
                XCTAssertEqual(error.code, NSURLErrorTimedOut)
            }
            
            expectationLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationLogin = nil
        }
    }
    
    func testMICLoginTimeoutDuringLoginCall() {
        var count = 0
        mockResponse { (request) -> HttpResponse in
            defer {
                count += 1
            }
            switch count {
            case 0:
                return HttpResponse(
                    statusCode: 200,
                    json: [
                        "_socialIdentity" : [
                            "kinveyAuth" : [
                                "access_token" : UUID().uuidString,
                                "token_type" : "Bearer",
                                "expires_in" : 59,
                                "refresh_token" : UUID().uuidString
                            ]
                        ]
                    ]
                )
            case 1:
                return HttpResponse(error: timeoutError)
            default:
                XCTFail("Mock request not handled. Request: \(request)")
                return HttpResponse(statusCode: 200, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationLogin = expectation(description: "Login")
        
        MIC.login(
            redirectURI: URL(string: "myCustomURIScheme://")!,
            code: "1234",
            options: try! Options(
                authServiceId: nil
            )
        ) { result in
            XCTAssertTrue(Thread.isMainThread)
            
            switch result {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                let error = error as NSError
                XCTAssertEqual(error.domain, NSURLErrorDomain)
                XCTAssertEqual(error.code, NSURLErrorTimedOut)
            }
            
            expectationLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationLogin = nil
        }
    }
    
    func testMICLoginUsernamePasswordTimeout() {
        setURLProtocol(TimeoutErrorURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationLogin = expectation(description: "Login")
        
        MIC.login(
            redirectURI: URL(string: "myCustomURIScheme://")!,
            username: UUID().uuidString,
            password: UUID().uuidString,
            options: try! Options(
                authServiceId: nil
            )
        ) { result in
            XCTAssertTrue(Thread.isMainThread)
            
            switch result {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                let error = error as NSError
                XCTAssertEqual(error.domain, NSURLErrorDomain)
                XCTAssertEqual(error.code, NSURLErrorTimedOut)
            }
            
            expectationLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationLogin = nil
        }
    }
    
    func testUserLoginUsernamePasswordTimeout() {
        setURLProtocol(TimeoutErrorURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationLogin = expectation(description: "Login")
        
        User.login(redirectURI: URL(string: "myCustomURIScheme://")!, username: UUID().uuidString, password: UUID().uuidString) { user, error in
            XCTAssertTrue(Thread.isMainThread)
            
            XCTAssertNil(user)
            XCTAssertNotNil(error)
            XCTAssertTimeoutError(error)
            
            expectationLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationLogin = nil
        }
    }
    
    func testMICLoginUsernamePasswordTimeoutDuringTempLoginURI() {
        var count = 0
        mockResponse { (request) -> HttpResponse in
            defer {
                count += 1
            }
            switch count {
            case 0:
                return HttpResponse(
                    statusCode: 200,
                    json: [
                        "temp_login_uri" : "https://auth.kinvey.com/oauth/authenticate/\(UUID().uuidString)"
                    ]
                )
            case 1:
                return HttpResponse(error: timeoutError)
            default:
                XCTFail("Mock request not handled. Request: \(request)")
                return HttpResponse(statusCode: 200, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationLogin = expectation(description: "Login")
        
        MIC.login(
            redirectURI: URL(string: "myCustomURIScheme://")!,
            username: UUID().uuidString,
            password: UUID().uuidString,
            options: try! Options(
                authServiceId: nil
            )
        ) { result in
            XCTAssertTrue(Thread.isMainThread)
            
            switch result {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                let error = error as NSError
                XCTAssertEqual(error.domain, NSURLErrorDomain)
                XCTAssertEqual(error.code, NSURLErrorTimedOut)
            }
            
            expectationLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationLogin = nil
        }
    }
    
    func testMICLoginUsernamePasswordTimeoutDuringLoginCall() {
        var count = 0
        mockResponse { (request) -> HttpResponse in
            defer {
                count += 1
            }
            switch count {
            case 0:
                return HttpResponse(
                    statusCode: 200,
                    json: [
                        "temp_login_uri" : "https://auth.kinvey.com/oauth/authenticate/\(UUID().uuidString)"
                    ]
                )
            case 1:
                return HttpResponse(
                    statusCode: 302,
                    headerFields: ["Location" : "myCustomURIScheme://?code=1234"],
                    data: Data()
                )
            case 2:
                return HttpResponse(error: timeoutError)
            default:
                XCTFail("Mock request not handled. Request: \(request)")
                return HttpResponse(statusCode: 200, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationLogin = expectation(description: "Login")
        
        MIC.login(
            redirectURI: URL(string: "myCustomURIScheme://")!,
            username: UUID().uuidString,
            password: UUID().uuidString,
            options: try! Options(
                authServiceId: nil
            )
        ) { result in
            XCTAssertTrue(Thread.isMainThread)
            
            switch result {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                let error = error as NSError
                XCTAssertEqual(error.domain, NSURLErrorDomain)
                XCTAssertEqual(error.code, NSURLErrorTimedOut)
            }
            
            expectationLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationLogin = nil
        }
    }
    
    func testMICLoginUsernamePasswordRedirectError() {
        var count = 0
        let errorCode = "server_error"
        let errorDescription = "server_error_description"
        mockResponse { (request) -> HttpResponse in
            defer {
                count += 1
            }
            switch count {
            case 0:
                return HttpResponse(
                    statusCode: 200,
                    json: [
                        "temp_login_uri" : "https://auth.kinvey.com/oauth/authenticate/\(UUID().uuidString)"
                    ]
                )
            case 1:
                return HttpResponse(
                    statusCode: 302,
                    headerFields: ["Location" : "myCustomURIScheme://?error=\(errorCode)&error_description=\(errorDescription)"],
                    data: Data()
                )
            default:
                XCTFail("Mock request not handled. Request: \(request)")
                return HttpResponse(statusCode: 200, data: Data())
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationLogin = expectation(description: "Login")
        
        MIC.login(
            redirectURI: URL(string: "myCustomURIScheme://")!,
            username: UUID().uuidString,
            password: UUID().uuidString,
            options: try! Options(
                authServiceId: nil
            )
        ) { result in
            XCTAssertTrue(Thread.isMainThread)
            
            switch result {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTrue(error is Kinvey.Error)
                XCTAssertNotNil(error as? Kinvey.Error)
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .micAuth(let code, let description):
                        XCTAssertEqual(errorCode, code)
                        XCTAssertEqual(errorDescription, description)
                    default:
                        XCTFail(error.description)
                    }
                }
            }
            
            expectationLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationLogin = nil
        }
    }
    
    func testUserWithoutUserID() {
        XCTAssertNil(try? client.jsonParser.parseUser(User.self, from: ["username" : "Test"]))
    }

}

#if !os(macOS)

import KinveyApp
    
typealias MICLoginViewController = KinveyApp.MICLoginViewController
    
extension UserTests {
    
    func testMICLoginSafari() {
        XCTAssertNil(Kinvey.sharedClient.activeUser)
        
        tester().tapView(withAccessibilityIdentifier: "MIC Login")
        
        defer {
            if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
                if let safariVC = navigationController.presentedViewController as? SFSafariViewController {
                    weak var expectationDismiss = expectation(description: "Dismiss")
                    
                    safariVC.dismiss(animated: true) {
                        expectationDismiss?.fulfill()
                    }
                    
                    waitForExpectations(timeout: defaultTimeout) { (error) in
                        expectationDismiss = nil
                    }
                }
                
                navigationController.popViewController(animated: true)
                tester().waitForAnimationsToFinish()
            }
        }
        
        tester().setOn(true, forSwitchWithAccessibilityIdentifier: "SafariViewController")
        
        tester().waitForAnimationsToFinish()
        
        tester().tapView(withAccessibilityIdentifier: "Login")
        
        tester().waitForAnimationsToFinish()
        tester().wait(forTimeInterval: 1)
        
        let userId = UUID().uuidString
        let user = try? client.jsonParser.parseUser(
            User.self,
            from: [
                "_id" : userId,
                "username" : UUID().uuidString,
                "_kmd" : [
                    "lmt" : Date().toISO8601(),
                    "ect" : Date().toISO8601(),
                    "authtoken" : UUID().uuidString
                ],
                "_acl" : [
                    "creator" : UUID().uuidString
                ]
            ]
        )
        XCTAssertNotNil(user)
        
        NotificationCenter.default.post(
            name: User.MICSafariViewControllerSuccessNotificationName,
            object: user
        )
        
        tester().waitForAnimationsToFinish()
        tester().wait(forTimeInterval: 1)
        
        let view = tester().waitForView(withAccessibilityIdentifier: "User ID Value") as? UILabel
        XCTAssertNotNil(view)
        if let view = view {
            XCTAssertNotNil(view.text)
            if let text = view.text {
                XCTAssertEqual(text, userId)
            }
        }
    }
    
    func testMICLoginSafariTimeoutError() {
        XCTAssertNil(Kinvey.sharedClient.activeUser)
        
        tester().tapView(withAccessibilityIdentifier: "MIC Login")
        
        defer {
            if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
                if let safariVC = navigationController.presentedViewController as? SFSafariViewController {
                    weak var expectationDismiss = expectation(description: "Dismiss")
                    
                    safariVC.dismiss(animated: true) {
                        expectationDismiss?.fulfill()
                    }
                    
                    waitForExpectations(timeout: defaultTimeout) { (error) in
                        expectationDismiss = nil
                    }
                }
                
                navigationController.popViewController(animated: true)
                tester().waitForAnimationsToFinish()
            }
        }
        
        tester().setOn(true, forSwitchWithAccessibilityIdentifier: "SafariViewController")
        
        tester().waitForAnimationsToFinish()
        
        tester().tapView(withAccessibilityIdentifier: "Login")
        
        tester().waitForAnimationsToFinish()
        tester().wait(forTimeInterval: 1)
        
        NotificationCenter.default.post(
            name: User.MICSafariViewControllerFailureNotificationName,
            object: timeoutError
        )
        
        tester().waitForAnimationsToFinish()
        tester().wait(forTimeInterval: 1)
        
        let view = tester().waitForView(withAccessibilityIdentifier: "User ID Value") as? UILabel
        XCTAssertNotNil(view)
        if let view = view {
            XCTAssertNotNil(view.text)
            if let text = view.text {
                XCTAssertEqual(text.trimmingCharacters(in: .whitespacesAndNewlines), "")
            }
        }
    }
    
    func testMICLoginSafariModalTimeoutError() {
        XCTAssertNil(Kinvey.sharedClient.activeUser)
        
        tester().tapView(withAccessibilityIdentifier: "MIC Login Modal")
        
        defer {
            if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
                if let safariVC = navigationController.presentedViewController as? SFSafariViewController {
                    weak var expectationDismiss = expectation(description: "Dismiss")
                    
                    safariVC.dismiss(animated: true) {
                        expectationDismiss?.fulfill()
                    }
                    
                    waitForExpectations(timeout: defaultTimeout) { (error) in
                        expectationDismiss = nil
                    }
                }
                
                tester().tapView(withAccessibilityIdentifier: "Dismiss")
                tester().waitForAnimationsToFinish()
            }
        }
        
        tester().setOn(true, forSwitchWithAccessibilityIdentifier: "SafariViewController")
        
        tester().waitForAnimationsToFinish()
        
        tester().tapView(withAccessibilityIdentifier: "Login")
        
        tester().waitForAnimationsToFinish()
        tester().wait(forTimeInterval: 1)
        
        NotificationCenter.default.post(
            name: User.MICSafariViewControllerFailureNotificationName,
            object: timeoutError
        )
        
        tester().waitForAnimationsToFinish()
        tester().wait(forTimeInterval: 1)
        
        let view = tester().waitForView(withAccessibilityIdentifier: "User ID Value") as? UILabel
        XCTAssertNotNil(view)
        if let view = view {
            XCTAssertNotNil(view.text)
            if let text = view.text {
                XCTAssertEqual(text.trimmingCharacters(in: .whitespacesAndNewlines), "")
            }
        }
    }
    
    func testMICLoginSafariSuccessWrongNotificationObject() {
        XCTAssertNil(Kinvey.sharedClient.activeUser)
        
        tester().tapView(withAccessibilityIdentifier: "MIC Login")
        
        defer {
            if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
                if let safariVC = navigationController.presentedViewController as? SFSafariViewController {
                    weak var expectationDismiss = expectation(description: "Dismiss")
                    
                    safariVC.dismiss(animated: true) {
                        expectationDismiss?.fulfill()
                    }
                    
                    waitForExpectations(timeout: defaultTimeout) { (error) in
                        expectationDismiss = nil
                    }
                }
                
                navigationController.popViewController(animated: true)
                tester().waitForAnimationsToFinish()
            }
        }
        
        tester().setOn(true, forSwitchWithAccessibilityIdentifier: "SafariViewController")
        
        tester().waitForAnimationsToFinish()
        
        tester().tapView(withAccessibilityIdentifier: "Login")
        
        tester().waitForAnimationsToFinish()
        tester().wait(forTimeInterval: 1)
        
        NotificationCenter.default.post(
            name: User.MICSafariViewControllerSuccessNotificationName,
            object: timeoutError
        )
        
        tester().waitForAnimationsToFinish()
        tester().wait(forTimeInterval: 1)
        
        let view = tester().waitForView(withAccessibilityIdentifier: "User ID Value") as? UILabel
        XCTAssertNotNil(view)
        if let view = view {
            XCTAssertNotNil(view.text)
            if let text = view.text {
                XCTAssertEqual(text.trimmingCharacters(in: .whitespacesAndNewlines), "")
            }
        }
    }
    
    func testMICLoginSafariFailureWrongNotificationObject() {
        XCTAssertNil(Kinvey.sharedClient.activeUser)
        
        tester().tapView(withAccessibilityIdentifier: "MIC Login")
        
        defer {
            if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
                if let safariVC = navigationController.presentedViewController as? SFSafariViewController {
                    weak var expectationDismiss = expectation(description: "Dismiss")
                    
                    safariVC.dismiss(animated: true) {
                        expectationDismiss?.fulfill()
                    }
                    
                    waitForExpectations(timeout: defaultTimeout) { (error) in
                        expectationDismiss = nil
                    }
                }
                
                navigationController.popViewController(animated: true)
                tester().waitForAnimationsToFinish()
            }
        }
        
        tester().setOn(true, forSwitchWithAccessibilityIdentifier: "SafariViewController")
        
        tester().waitForAnimationsToFinish()
        
        tester().tapView(withAccessibilityIdentifier: "Login")
        
        tester().waitForAnimationsToFinish()
        tester().wait(forTimeInterval: 1)
        
        let userId = UUID().uuidString
        let user = try? client.jsonParser.parseUser(
            User.self,
            from: [
                "_id" : userId,
                "username" : UUID().uuidString,
                "_kmd" : [
                    "lmt" : Date().toISO8601(),
                    "ect" : Date().toISO8601(),
                    "authtoken" : UUID().uuidString
                ],
                "_acl" : [
                    "creator" : UUID().uuidString
                ]
            ]
        )
        XCTAssertNotNil(user)
        
        NotificationCenter.default.post(
            name: User.MICSafariViewControllerFailureNotificationName,
            object: user
        )
        
        tester().waitForAnimationsToFinish()
        tester().wait(forTimeInterval: 1)
        
        let view = tester().waitForView(withAccessibilityIdentifier: "User ID Value") as? UILabel
        XCTAssertNotNil(view)
        if let view = view {
            XCTAssertNotNil(view.text)
            if let text = view.text {
                XCTAssertEqual(text.trimmingCharacters(in: .whitespacesAndNewlines), "")
            }
        }
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
            tester().tapView(withAccessibilityLabel: "Back", traits: UIAccessibilityTraits.button)
        }
        tester().tapView(withAccessibilityIdentifier: "Login")
        
        tester().waitForAnimationsToFinish()
        tester().wait(forTimeInterval: 1)
        
        guard let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController,
            let micLoginViewController = navigationController.topViewController as? MICLoginViewController,
            let navigationController2 = navigationController.presentedViewController as? UINavigationController,
            let micViewController = navigationController2.topViewController as? Kinvey.MICLoginViewController
        else {
            XCTFail("Kinvey.MICLoginViewController was not found")
            return
        }
        
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
                let store = try! DataStore<Person>.collection(.network)
                
                weak var expectationFind = expectation(description: "Find")
                
                store.find {
                    XCTAssertTrue(Thread.isMainThread)
                    switch $0 {
                    case .success:
                        break
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationFind?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { error in
                    expectationFind = nil
                }
            }
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
        
        guard let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController,
            let micLoginViewController = navigationController.presentedViewController as? MICLoginViewController,
            let navigationController2 = micLoginViewController.presentedViewController as? UINavigationController,
            let micViewController = navigationController2.topViewController as? Kinvey.MICLoginViewController
        else {
            XCTFail("Kinvey.MICLoginViewController was not found")
            return
        }
        
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
                    if let result = result, !(result is NSNull) {
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
        
        guard let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController,
            let micLoginViewController = navigationController.topViewController as? MICLoginViewController,
            let navigationController2 = navigationController.presentedViewController as? UINavigationController,
            let micViewController = navigationController2.topViewController as? Kinvey.MICLoginViewController
        else {
            XCTFail("Kinvey.MICLoginViewController was not found")
            return
        }
        
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
        
        guard let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController,
            let micLoginViewController = navigationController.topViewController as? MICLoginViewController
        else {
            XCTFail("MICLoginViewController not found")
            return
        }
        
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
    }
    
    func testMICErrorMessageUIWebView() {
        let responseBody = [
            "error" : "invalid_client",
            "error_description" : "Client authentication failed.",
            "debug" : "Client Verification Failed: redirect uri not valid"
        ]
        if useMockData {
            mockResponse(json: responseBody)
        }
        defer {
            if useMockData { setURLProtocol(nil) }
        }
        
        weak var expectationLogin = expectation(description: "Login")
        
        let redirectURI = URL(string: "throwAnError://")!
        
        User.presentMICViewController(redirectURI: redirectURI, micUserInterface: .uiWebView, options: try! Options(timeout: 60)) {
            XCTAssertTrue(Thread.isMainThread)
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertNotNil(error as? Kinvey.Error)
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .unknownJsonError(_, _, let json):
                        XCTAssertEqual(json.count, responseBody.count)
                        XCTAssertEqual(json["error"] as? String, responseBody["error"])
                        XCTAssertEqual(json["error_description"] as? String, responseBody["error_description"])
                        XCTAssertEqual(json["debug"] as? String, responseBody["debug"])
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            
            expectationLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationLogin = nil
        }
    }
    
    func testMICErrorMessageWKWebView() {
        let responseBody = [
            "error" : "invalid_client",
            "error_description" : "Client authentication failed.",
            "debug" : "Client Verification Failed: Error: Invalid Client"
        ]
        if useMockData {
            mockResponse(json: responseBody)
        }
        defer {
            if useMockData { setURLProtocol(nil) }
        }
        
        weak var expectationLogin = expectation(description: "Login")
        
        let redirectURI = URL(string: "throwAnError://")!
        User.presentMICViewController(redirectURI: redirectURI, micUserInterface: .wkWebView, options: try! Options(timeout: 60)) {
            XCTAssertTrue(Thread.isMainThread)
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertNotNil(error as? Kinvey.Error)
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .unknownJsonError(_, _, let json):
                        XCTAssertEqual(json.count, responseBody.count)
                        XCTAssertEqual(json["error"] as? String, responseBody["error"])
                        XCTAssertEqual(json["error_description"] as? String, responseBody["error_description"])
                        XCTAssertEqual(json["debug"] as? String, responseBody["debug"])
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            
            expectationLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationLogin = nil
        }
    }
    
    func testMICClientNotInitialized() {
        let client = Client()
        
        weak var expectationLogin = expectation(description: "Login")
        
        let redirectURI = URL(string: "throwAnError://")!
        User.presentMICViewController(redirectURI: redirectURI, client: client) { user, error in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(error)
            XCTAssertNotNil(error as? Kinvey.Error)
            XCTAssertNil(user)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .clientNotInitialized:
                    break
                default:
                    XCTFail(error.localizedDescription)
                }
            }
            
            expectationLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationLogin = nil
        }
    }
    
    func testUserMICLoginTimeoutError() {
        mockResponse(error: timeoutError)
        
        expectation(forNotification: User.MICSafariViewControllerFailureNotificationName, object: nil) { (notification) -> Bool in
            XCTAssertNotNil(notification.object)
            XCTAssertTrue(notification.object is Swift.Error)
            if let error = notification.object as? Swift.Error {
                XCTAssertTimeoutError(error)
            }
            return true
        }
        
        let result = User.login(
            redirectURI: URL(string: "myCustomURIScheme://")!,
            micURL: URL(string: "myCustomURIScheme://?code=1234")!,
            options: try! Options(client: client)
        )
        XCTAssertTrue(result)
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
        }
    }
    
    func testUserMICLoginWrongCode() {
        let result = User.login(
            redirectURI: URL(string: "myCustomURIScheme://")!,
            micURL: URL(string: "myCustomURIScheme://?no_code=1234")!,
            options: try! Options(client: client)
        )
        XCTAssertFalse(result)
    }
    
    func testUserMICLogin() {
        var count = 0
        mockResponse { (request) -> HttpResponse in
            defer {
                count += 1
            }
            switch count {
            case 0:
                return HttpResponse(
                    statusCode: 200,
                    json: [
                        "_socialIdentity" : [
                            "kinveyAuth" : [
                                "access_token" : UUID().uuidString,
                                "token_type" : "Bearer",
                                "expires_in" : 59,
                                "refresh_token" : UUID().uuidString
                            ]
                        ]
                    ]
                )
            case 1:
                return HttpResponse(json: [
                    "_id" : UUID().uuidString,
                    "username" : "test",
                    "_kmd" : [
                        "lmt" : Date().toISO8601(),
                        "ect" : Date().toISO8601(),
                        "authtoken" : UUID().uuidString
                    ],
                    "_acl" : [
                        "creator" : UUID().uuidString
                    ]
                ])
            default:
                Swift.fatalError()
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        expectation(forNotification: User.MICSafariViewControllerSuccessNotificationName, object: nil) { (notification) -> Bool in
            XCTAssertNotNil(notification.object)
            XCTAssertTrue(notification.object is User)
            if let user = notification.object as? User {
                XCTAssertEqual(user.username, "test")
                MockKinveyBackend.user[user.userId] = try! self.client.jsonParser.toJSON(user)
            }
            return true
        }
        
        let result = User.login(
            redirectURI: URL(string: "myCustomURIScheme://")!,
            micURL: URL(string: "myCustomURIScheme://?code=1234")!,
            options: try! Options(client: client)
        )
        XCTAssertTrue(result)
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
        }
    }
    
    func testUserMICLoginInstanceId() {
        weak var expectationInitialize = self.expectation(description: "Initialize")
        
        let appKey = UUID().uuidString
        let client = Client(appKey: appKey, appSecret: UUID().uuidString, instanceId: "my-instance-id") { result in
            expectationInitialize?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationInitialize = nil
        }
        
        var count = 0
        mockResponse(client: client) { (request) -> HttpResponse in
            defer {
                count += 1
            }
            switch count {
            case 0:
                XCTAssertEqual(request.url?.host, "my-instance-id-auth.kinvey.com")
                XCTAssertEqual(request.url?.path, "/\(client.micApiVersion!.rawValue)/oauth/token")
                return HttpResponse(
                    statusCode: 200,
                    json: [
                        "_socialIdentity" : [
                            "kinveyAuth" : [
                                "access_token" : UUID().uuidString,
                                "token_type" : "Bearer",
                                "expires_in" : 59,
                                "refresh_token" : UUID().uuidString
                            ]
                        ]
                    ]
                )
            case 1:
                XCTAssertEqual(request.url?.host, "my-instance-id-baas.kinvey.com")
                XCTAssertEqual(request.url?.path, "/user/\(appKey)/login")
                return HttpResponse(json: [
                    "_id" : UUID().uuidString,
                    "username" : "test",
                    "_kmd" : [
                        "lmt" : Date().toISO8601(),
                        "ect" : Date().toISO8601(),
                        "authtoken" : UUID().uuidString
                    ],
                    "_acl" : [
                        "creator" : UUID().uuidString
                    ]
                ])
            default:
                Swift.fatalError()
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        expectation(forNotification: User.MICSafariViewControllerSuccessNotificationName, object: nil) { (notification) -> Bool in
            XCTAssertNotNil(notification.object)
            XCTAssertTrue(notification.object is User)
            if let user = notification.object as? User {
                XCTAssertEqual(user.username, "test")
                MockKinveyBackend.user[user.userId] = try! client.jsonParser.toJSON(user)
            }
            return true
        }
        
        let result = User.login(
            redirectURI: URL(string: "myCustomURIScheme://")!,
            micURL: URL(string: "myCustomURIScheme://?code=1234")!,
            options: try! Options(client: client)
        )
        XCTAssertTrue(result)
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
        }
    }
    
    func testUserMicViewControllerCoding() {
        expect { () -> Void in
            Kinvey.MICLoginViewController(coder: NSKeyedArchiver())
        }.to(raiseException())
    }
    
    func testMICTimeoutAction() {
        var runLoop: CFRunLoop?
        mockResponse { (request) -> HttpResponse in
            runLoop = CFRunLoopGetCurrent()
            CFRunLoopRun()
            DispatchQueue.main.async {
                runLoop = nil
            }
            return HttpResponse(error: timeoutError)
        }
        defer {
            if let runLoop = runLoop {
                CFRunLoopStop(runLoop)
            }
            setURLProtocol(nil)
        }

        weak var expectationLogin = expectation(description: "Login")

        let redirectURI = URL(string: "throwAnError://")!
        User.presentMICViewController(
            redirectURI: redirectURI,
            micUserInterface: .uiWebView,
            options: try! Options(timeout: 3)
        ) {
            XCTAssertTrue(Thread.isMainThread)
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTrue(error is Kinvey.Error)
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .requestTimeout:
                        XCTAssertEqual(error.description, "Request Timeout")
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }

            expectationLogin?.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout) { error in
            expectationLogin = nil
        }
    }
    
    func testMICCancelUserAction() {
        var runLoop: CFRunLoop?
        defer {
            if let runLoop = runLoop {
                CFRunLoopStop(runLoop)
            }
        }
        mockResponse { (request) -> HttpResponse in
            runLoop = CFRunLoopGetCurrent()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 10))
            DispatchQueue.main.async {
                runLoop = nil
                guard let keyWindow = UIApplication.shared.keyWindow,
                    let navigationController = keyWindow.rootViewController as? UINavigationController,
                    let navigationController2 = navigationController.topViewController?.presentedViewController as? UINavigationController,
                    let micLoginViewController = navigationController2.topViewController as? Kinvey.MICLoginViewController,
                    let closeButton = micLoginViewController.navigationItem.leftBarButtonItem
                else {
                    XCTFail("Kinvey.MICLoginViewController close button not found")
                    return
                }
                closeButton.target!.performSelector(onMainThread: closeButton.action!, with: self, waitUntilDone: true)
            }
            return HttpResponse(error: timeoutError)
        }
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationLogin = expectation(description: "Login")
        
        let redirectURI = URL(string: "throwAnError://")!
        User.presentMICViewController(
            redirectURI: redirectURI,
            micUserInterface: .uiWebView,
            options: try! Options(timeout: 60)
        ) {
            XCTAssertTrue(Thread.isMainThread)
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTrue(error is Kinvey.Error)
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .requestCancelled:
                        break
                    default:
                        XCTFail(error.localizedDescription)
                    }
                }
            }
            
            expectationLogin?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationLogin = nil
        }
    }
    
    func testLogout() {
        signUp()
        
        guard let user = Kinvey.sharedClient.activeUser else {
            Swift.fatalError()
        }
        
        if useMockData {
            mockResponse(statusCode: 204, data: Data())
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationLogout = expectation(description: "Logout")
        
        user.logout {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationLogout?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationLogout = nil
        }
    }
    
    func testLogoutTimeoutError() {
        signUp()
        
        guard let user = Kinvey.sharedClient.activeUser else {
            XCTAssertNotNil(Kinvey.sharedClient.activeUser)
            return
        }
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationLogout = expectation(description: "Logout")
        
        user.logout {
            XCTAssertNil(Kinvey.sharedClient.activeUser)
            
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertTimeoutError(error)
            }
            
            expectationLogout?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationLogout = nil
        }
    }
    
    func testLogoutServerError() {
        signUp()
        
        guard let user = Kinvey.sharedClient.activeUser else {
            XCTAssertNotNil(Kinvey.sharedClient.activeUser)
            return
        }
        
        mockResponse(statusCode: 500, data: "Server Error".data(using: .utf8))
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationLogout = expectation(description: "Logout")
        
        user.logout {
            XCTAssertNil(Kinvey.sharedClient.activeUser)
            
            switch $0 {
            case .success:
                XCTFail("A failure result is expected")
            case .failure(let error):
                XCTAssertNotNil(error as? Kinvey.Error)
            }
            
            expectationLogout?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationLogout = nil
        }
    }
    
    func userLockDown(mustIncludeSocialIdentity: Bool) {
        signUp(mustIncludeSocialIdentity: mustIncludeSocialIdentity)
        
        XCTAssertNotNil(Kinvey.sharedClient.activeUser)
        
        let store = try! DataStore<Person>.collection(.sync)
        
        do {
            mockResponse(json: [
                [
                    "_id": UUID().uuidString,
                    "name": "Victor",
                    "age": 0,
                    "_acl": [
                        "creator": client.activeUser?.userId
                    ],
                    "_kmd": [
                        "lmt": Date().toISO8601(),
                        "ect": Date().toISO8601()
                    ]
                ]
            ])
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationLogout = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success(let count, let results):
                    XCTAssertEqual(count, 0)
                    XCTAssertEqual(results.count, 1)
                case .failure(let errors):
                    XCTFail(errors.first!.localizedDescription)
                }
                expectationLogout?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationLogout = nil
            }
        }
        
        XCTAssertNotNil(Kinvey.sharedClient.activeUser)
        XCTAssertEqual(try? store.count().waitForResult().value(), 1)
        
        do {
            mockResponse(
                statusCode: 401,
                json: [
                    "error" : "InvalidCredentials",
                    "description" : "Invalid credentials. Please retry your request with correct credentials",
                    "debug" : "Authorization token invalid or expired"
                ]
            )
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationLogout = expectation(description: "Sync")
            
            store.sync(options: nil) { (result: Result<(UInt, AnyRandomAccessCollection<Person>), [Swift.Error]>) in
                switch result {
                case .success:
                    XCTFail("A failure result is expected")
                case .failure(let errors):
                    XCTAssertEqual(errors.count, 1)
                    XCTAssertNotNil(errors.first as? Kinvey.Error)
                    if let error = errors.first as? Kinvey.Error {
                        switch error {
                        case .invalidCredentials(let httpRequest, let data, let debug, let description):
                            XCTAssertEqual(httpRequest?.statusCode, 401)
                            XCTAssertNotNil(data)
                            if let data = data {
                                XCTAssertGreaterThan(data.count, 0)
                            }
                            XCTAssertEqual(debug, "Authorization token invalid or expired")
                            XCTAssertEqual(description, "Invalid credentials. Please retry your request with correct credentials")
                        default:
                            XCTFail(error.description)
                        }
                    }
                }
                expectationLogout?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationLogout = nil
            }
        }
        
        XCTAssertNil(Kinvey.sharedClient.activeUser)
        XCTAssertEqual(try? store.count().waitForResult().value(), 0)
    }
    
    func testUserLockDown() {
        userLockDown(mustIncludeSocialIdentity: false)
    }
    
    func testUserLockDownWithRefreshToken() {
        userLockDown(mustIncludeSocialIdentity: true)
    }
    
    func testUserHashable() {
        let userId = UUID().uuidString
        let user1 = User(userId: userId)
        let user2 = User(userId: userId)
        let user3 = User(userId: UUID().uuidString)
        XCTAssertEqual(user1.hash, user2.hash)
        XCTAssertEqual(user1.hashValue, user2.hashValue)
        XCTAssertNotEqual(user1.hash, user3.hash)
        XCTAssertNotEqual(user2.hash, user3.hash)
        XCTAssertNotEqual(user1.hashValue, user3.hashValue)
        XCTAssertNotEqual(user2.hashValue, user3.hashValue)
    }
    
    func testUserEquatable() {
        let userId = UUID().uuidString
        let user1 = User(userId: userId)
        let user2 = User(userId: userId)
        let user3 = User(userId: UUID().uuidString)
        let set = Set<User>([user1])
        XCTAssertEqual(user1, user2)
        XCTAssertNotEqual(user1, user3)
        XCTAssertNotEqual(user2, user3)
        XCTAssertTrue(user1 == user2)
        XCTAssertFalse(user1 == user3)
        XCTAssertFalse(user2 == user3)
        XCTAssertTrue(user1.isEqual(user2))
        XCTAssertFalse(user1.isEqual(user3))
        XCTAssertFalse(user2.isEqual(user3))
        XCTAssertFalse(user2.isEqual(nil))
        XCTAssertTrue(set.contains(user2))
        XCTAssertFalse(set.contains(user3))
    }
    
    func testMappingWithoutUserId() {
        var user: User? = nil
        
        let map = Map(mappingType: .fromJSON, JSON: ["user" : [:]])
        user <- map["user"]
        XCTAssertNil(user)
    }
    
}

#endif

// swiftlint:enable nesting
