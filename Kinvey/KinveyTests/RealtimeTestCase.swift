//
//  RealtimeTests.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-05-12.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey
import PubNub
import ObjectMapper

class RealtimeTestCase: KinveyTestCase {
    
    func testRegisterForRealtime() {
        signUp()
        
        guard let user = Kinvey.sharedClient.activeUser else {
            XCTAssertNotNil(Kinvey.sharedClient.activeUser)
            return
        }
        
        XCTAssertNil(user.realtimeRouter)
        var registered = false
        
        do {
            if useMockData {
                mockResponse(json: [
                    "subscribeKey" : UUID().uuidString,
                    "publishKey" : UUID().uuidString,
                    "userChannelGroup" : UUID().uuidString
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationRegister = self.expectation(description: "Register")
            
            user.registerForRealtime() {
                switch $0 {
                case .success:
                    registered = true
                    XCTAssertNotNil(user.realtimeRouter)
                case .failure:
                    XCTFail()
                }
                
                expectationRegister?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationRegister = nil
            }
        }
        
        XCTAssertTrue(registered)
        
        if registered {
            if useMockData {
                mockResponse(statusCode: 204, data: Data())
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationUnregister = self.expectation(description: "Unregister")
            
            user.unregisterForRealtime() {
                switch $0 {
                case .success:
                    XCTAssertNil(user.realtimeRouter)
                case .failure:
                    XCTFail()
                }
                
                expectationUnregister?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationUnregister = nil
            }
        }
    }
    
    func testRegisterForRealtimeTimeout() {
        signUp()
        
        guard let user = Kinvey.sharedClient.activeUser else {
            XCTAssertNotNil(Kinvey.sharedClient.activeUser)
            return
        }
        
        XCTAssertNil(user.realtimeRouter)
        
        mockResponse(error: timeoutError)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRegister = self.expectation(description: "Register")
        
        user.registerForRealtime() {
            switch $0 {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertNil(user.realtimeRouter)
                XCTAssertTimeoutError(error)
            }
            
            expectationRegister?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationRegister = nil
        }
    }
    
    func testUnregisterForRealtimeTimeoutError() {
        signUp()
        
        guard let user = Kinvey.sharedClient.activeUser else {
            XCTAssertNotNil(Kinvey.sharedClient.activeUser)
            return
        }
        
        XCTAssertNil(user.realtimeRouter)
        var registered = false
        
        do {
            if useMockData {
                mockResponse(json: [
                    "subscribeKey" : UUID().uuidString,
                    "publishKey" : UUID().uuidString,
                    "userChannelGroup" : UUID().uuidString
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationRegister = self.expectation(description: "Register")
            
            user.registerForRealtime() {
                switch $0 {
                case .success:
                    registered = true
                    XCTAssertNotNil(user.realtimeRouter)
                case .failure:
                    XCTFail()
                }
                
                expectationRegister?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationRegister = nil
            }
        }
        
        XCTAssertTrue(registered)
        
        if registered {
            do {
                mockResponse(error: timeoutError)
                defer {
                    setURLProtocol(nil)
                }
                
                weak var expectationUnregister = self.expectation(description: "Unregister")
                
                user.unregisterForRealtime() {
                    switch $0 {
                    case .success:
                        XCTFail()
                    case .failure(let error):
                        XCTAssertNotNil(user.realtimeRouter)
                        XCTAssertTimeoutError(error)
                    }
                    
                    expectationUnregister?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { (error) in
                    expectationUnregister = nil
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
            
            weak var expectationUnregister = self.expectation(description: "Unregister")
            
            user.unregisterForRealtime() {
                switch $0 {
                case .success:
                    XCTAssertNil(user.realtimeRouter)
                case .failure:
                    XCTFail()
                }
                
                expectationUnregister?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationUnregister = nil
            }
        }
    }
    
    func testSubscribeDataStore() {
        signUp()
        
        guard let user = Kinvey.sharedClient.activeUser else {
            XCTAssertNotNil(Kinvey.sharedClient.activeUser)
            return
        }
        
        XCTAssertNil(user.realtimeRouter)
        var registered = false
        
        do {
            if useMockData {
                mockResponse(json: [
                    "subscribeKey" : UUID().uuidString,
                    "publishKey" : UUID().uuidString,
                    "userChannelGroup" : UUID().uuidString
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationRegister = self.expectation(description: "Register")
            
            user.registerForRealtime() {
                switch $0 {
                case .success:
                    registered = true
                    XCTAssertNotNil(user.realtimeRouter)
                    if self.useMockData {
                        let pubNubRealtimeRouter = user.realtimeRouter as! PubNubRealtimeRouter
                        user.realtimeRouter = PubNubRealtimeRouter(
                            user: pubNubRealtimeRouter.user,
                            subscribeKey: pubNubRealtimeRouter.subscribeKey,
                            publishKey: pubNubRealtimeRouter.publishKey,
                            userChannelGroup: pubNubRealtimeRouter.userChannelGroup,
                            pubNubType: MockPubNub.self
                        )
                    }
                case .failure:
                    XCTFail()
                }
                
                expectationRegister?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationRegister = nil
            }
        }
        
        if registered {
            let dataStoreSync = DataStore<Person>.collection(.sync)
            let dataStoreNetwork = DataStore<Person>.collection(.network)
            
            do {
                weak var expectationSave = self.expectation(description: "Save")
                weak var expectationMessage = self.expectation(description: "Message")
                weak var expectationError = self.expectation(description: "Error")
                weak var expectationStatusConnected = self.expectation(description: "Status Connected")
                weak var expectationStatusReconnected = self.expectation(description: "Status Reconnected")
                weak var expectationStatusUnexpectedDisconnected = self.expectation(description: "Status Unexpected Disconnected")
                
                let person = Person()
                person.name = UUID().uuidString
                
                if useMockData {
                    var count = 0
                    mockResponse { (request) -> HttpResponse in
                        defer {
                            count += 1
                        }
                        switch count {
                        case 0:
                            return HttpResponse(statusCode: 204, data: Data())
                        case 1:
                            var json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
                            json["_id"] = UUID().uuidString
                            if self.useMockData {
                                MockPubNub.default.publish(json, toChannel: "\(self.client.appKey!).c-\(Person.collectionName())")
                            }
                            return HttpResponse(json: json)
                        default:
                            Swift.fatalError()
                        }
                    }
                }
                defer {
                    if useMockData {
                        setURLProtocol(nil)
                    }
                }
                
                var subscribed = false
                
                dataStoreSync.subscribe(subscription: {
                    subscribed = true
                }, onNext: {
                    XCTAssertEqual($0.name, person.name)
                    
                    expectationMessage?.fulfill()
                }, onStatus: {
                    switch $0 {
                    case .connected:
                        expectationStatusConnected?.fulfill()
                    case .reconnected:
                        expectationStatusReconnected?.fulfill()
                    case .unexpectedDisconnect:
                        expectationStatusUnexpectedDisconnected?.fulfill()
                    default:
                        XCTFail()
                    }
                }, onError: {
                    XCTAssertEqual($0.localizedDescription, "Timeout")
                    
                    expectationError?.fulfill()
                })
                
                if useMockData {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        MockPubNub.default.status(category: .PNConnectedCategory)
                        MockPubNub.default.error(
                            channels: ["\(self.client.appKey!).c-\(Person.collectionName())"],
                            information: "Timeout",
                            category: .PNTimeoutCategory
                        )
                        MockPubNub.default.status(category: .PNUnexpectedDisconnectCategory)
                        MockPubNub.default.status(category: .PNReconnectedCategory)
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                    dataStoreNetwork.save(person, writePolicy: nil) { (result: Result<Person, Swift.Error>) in
                        switch result {
                        case .success:
                            break
                        case .failure:
                            XCTFail()
                        }
                        
                        expectationSave?.fulfill()
                    }
                }
                
                waitForExpectations(timeout: defaultTimeout) { (error) in
                    expectationMessage = nil
                    expectationSave = nil
                    expectationError = nil
                    expectationStatusConnected = nil
                    expectationStatusReconnected = nil
                    expectationStatusUnexpectedDisconnected = nil
                }
                
                XCTAssertTrue(subscribed)
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
                
                weak var expectationUnsubscribe = self.expectation(description: "Unsubscribe")
                
                dataStoreSync.unsubscribe() {
                    switch $0 {
                    case .success:
                        break
                    case .failure:
                        XCTFail()
                    }
                    
                    expectationUnsubscribe?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { (error) in
                    expectationUnsubscribe = nil
                }
            }
            
            do {
                if useMockData {
                    mockResponse(completionHandler: { (request) -> HttpResponse in
                        DispatchQueue.main.async {
                            MockPubNub.default.status(category: .PNDisconnectedCategory)
                        }
                        return HttpResponse(statusCode: 204, data: Data())
                    })
                }
                defer {
                    if useMockData {
                        setURLProtocol(nil)
                    }
                }
                
                weak var expectationUnregister = self.expectation(description: "Unregister")
                
                user.unregisterForRealtime() {
                    switch $0 {
                    case .success:
                        XCTAssertNil(user.realtimeRouter)
                    case .failure:
                        XCTFail()
                    }
                    
                    expectationUnregister?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { (error) in
                    expectationUnregister = nil
                }
            }
        }
    }
    
    func testSubscribeNoActiveUser() {
        let dataStore = DataStore<Person>.collection(.sync)
        
        weak var expectationSubscribe = self.expectation(description: "Subscribe")
        
        dataStore.subscribe(subscription: {
            XCTFail()
        }, onNext: { _ in
            XCTFail()
        }, onStatus: { _ in
        }, onError: { error in
            XCTAssertEqual(error.localizedDescription, "Active User not found")
            expectationSubscribe?.fulfill()
        })
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationSubscribe = nil
        }
    }
    
    func testSubscribeNotRegisterForRealtime() {
        signUp()
        
        let dataStore = DataStore<Person>.collection(.sync)
        
        weak var expectationSubscribe = self.expectation(description: "Subscribe")
        
        dataStore.subscribe(subscription: {
            XCTFail()
        }, onNext: { _ in
            XCTFail()
        }, onStatus: { _ in
        }, onError: { error in
            XCTAssertEqual(error.localizedDescription, "Active User not register for realtime")
            expectationSubscribe?.fulfill()
        })
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationSubscribe = nil
        }
    }
    
    func testSubscribeDataStoreTimeoutError() {
        signUp()
        
        guard let user = Kinvey.sharedClient.activeUser else {
            XCTAssertNotNil(Kinvey.sharedClient.activeUser)
            return
        }
        
        XCTAssertNil(user.realtimeRouter)
        var registered = false
        
        do {
            if useMockData {
                mockResponse(json: [
                    "subscribeKey" : UUID().uuidString,
                    "publishKey" : UUID().uuidString,
                    "userChannelGroup" : UUID().uuidString
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationRegister = self.expectation(description: "Register")
            
            user.registerForRealtime() {
                switch $0 {
                case .success:
                    registered = true
                    XCTAssertNotNil(user.realtimeRouter)
                    if self.useMockData {
                        let pubNubRealtimeRouter = user.realtimeRouter as! PubNubRealtimeRouter
                        user.realtimeRouter = PubNubRealtimeRouter(
                            user: pubNubRealtimeRouter.user,
                            subscribeKey: pubNubRealtimeRouter.subscribeKey,
                            publishKey: pubNubRealtimeRouter.publishKey,
                            userChannelGroup: pubNubRealtimeRouter.userChannelGroup,
                            pubNubType: MockPubNub.self
                        )
                    }
                case .failure:
                    XCTFail()
                }
                
                expectationRegister?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationRegister = nil
            }
        }
        
        if registered {
            let dataStore = DataStore<Person>.collection(.sync)
            
            do {
                weak var expectationSubscribe = self.expectation(description: "Subscribe")
                
                mockResponse(error: timeoutError)
                defer {
                    setURLProtocol(nil)
                }
                
                dataStore.subscribe(subscription: {
                    XCTFail()
                }, onNext: { _ in
                    XCTFail()
                }, onStatus: { _ in
                }, onError: { error in
                    XCTAssertTimeoutError(error)
                    expectationSubscribe?.fulfill()
                })
                
                waitForExpectations(timeout: defaultTimeout) { (error) in
                    expectationSubscribe = nil
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
                
                weak var expectationUnregister = self.expectation(description: "Unregister")
                
                user.unregisterForRealtime() {
                    switch $0 {
                    case .success:
                        XCTAssertNil(user.realtimeRouter)
                    case .failure:
                        XCTFail()
                    }
                    
                    expectationUnregister?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { (error) in
                    expectationUnregister = nil
                }
            }
        }
    }
    
    func testUnSubscribeDataStoreTimeoutError() {
        signUp()
        
        guard let user = Kinvey.sharedClient.activeUser else {
            XCTAssertNotNil(Kinvey.sharedClient.activeUser)
            return
        }
        
        XCTAssertNil(user.realtimeRouter)
        var registered = false
        
        do {
            if useMockData {
                mockResponse(json: [
                    "subscribeKey" : UUID().uuidString,
                    "publishKey" : UUID().uuidString,
                    "userChannelGroup" : UUID().uuidString
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationRegister = self.expectation(description: "Register")
            
            user.registerForRealtime() {
                switch $0 {
                case .success:
                    registered = true
                    XCTAssertNotNil(user.realtimeRouter)
                    if self.useMockData {
                        let pubNubRealtimeRouter = user.realtimeRouter as! PubNubRealtimeRouter
                        user.realtimeRouter = PubNubRealtimeRouter(
                            user: pubNubRealtimeRouter.user,
                            subscribeKey: pubNubRealtimeRouter.subscribeKey,
                            publishKey: pubNubRealtimeRouter.publishKey,
                            userChannelGroup: pubNubRealtimeRouter.userChannelGroup,
                            pubNubType: MockPubNub.self
                        )
                    }
                case .failure:
                    XCTFail()
                }
                
                expectationRegister?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationRegister = nil
            }
        }
        
        if registered {
            let dataStore = DataStore<Person>.collection(.sync)
            
            do {
                if useMockData {
                    mockResponse(statusCode: 204, data: Data())
                }
                defer {
                    if useMockData {
                        setURLProtocol(nil)
                    }
                }
                
                weak var expectationSubscribe = self.expectation(description: "Subscribe")
                
                dataStore.subscribe(subscription: {
                    expectationSubscribe?.fulfill()
                }, onNext: { _ in
                    XCTFail()
                }, onStatus: { _ in
                }, onError: { _ in
                    XCTFail()
                })
                
                waitForExpectations(timeout: defaultTimeout) { (error) in
                    expectationSubscribe = nil
                }
            }
            
            do {
                mockResponse(error: timeoutError)
                defer {
                    setURLProtocol(nil)
                }
                
                weak var expectationUnsubscribe = self.expectation(description: "Unsubscribe")
                
                dataStore.unsubscribe() {
                    switch $0 {
                    case .success:
                        XCTFail()
                    case .failure(let error):
                        XCTAssertTimeoutError(error)
                    }
                    expectationUnsubscribe?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { (error) in
                    expectationUnsubscribe = nil
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
                
                weak var expectationUnregister = self.expectation(description: "Unregister")
                
                user.unregisterForRealtime() {
                    switch $0 {
                    case .success:
                        XCTAssertNil(user.realtimeRouter)
                    case .failure:
                        XCTFail()
                    }
                    
                    expectationUnregister?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout) { (error) in
                    expectationUnregister = nil
                }
            }
        }
    }
    
    func testUnSubscribeNoActiveUser() {
        let dataStore = DataStore<Person>.collection(.sync)
        
        weak var expectationSubscribe = self.expectation(description: "Subscribe")
        
        dataStore.unsubscribe() {
            switch $0 {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error.localizedDescription, "Active User not found")
            }
            expectationSubscribe?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationSubscribe = nil
        }
    }
    
    func testUnSubscribeNotRegisterForRealtime() {
        signUp()
        
        let dataStore = DataStore<Person>.collection(.sync)
        
        weak var expectationSubscribe = self.expectation(description: "Subscribe")
        
        dataStore.unsubscribe() {
            switch $0 {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error.localizedDescription, "Active User not register for realtime")
            }
            expectationSubscribe?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationSubscribe = nil
        }
    }
    
    var tearDownHandler: (() -> Void)? = nil
    
    override func tearDown() {
        super.tearDown()
        tearDownHandler?()
    }
    
    func testStream() {
        let deleteUserDuringTearDown = self.deleteUserDuringTearDown
        let realtimeTestUserId = UUID().uuidString
        self.deleteUserDuringTearDown = false
        tearDownHandler = {
            if !self.useMockData {
                self.deleteUserDuringTearDown = deleteUserDuringTearDown
            }
            self.tearDownHandler = nil
        }
        
        login(username: "realtime-test", password: "realtime-test", mockHandler: { (request) -> HttpResponse in
            return HttpResponse(json: [
                "_id" : UUID().uuidString,
                "username" : "realtime-test",
                "_kmd": [
                    "lmt" : Date().toString(),
                    "ect" : Date().toString(),
                    "authtoken" : UUID().uuidString
                ],
                "_acl" : [
                    "creator" : UUID().uuidString
                ]
            ])
        })
        
        XCTAssertNotNil(client.activeUser)
        
        guard let user = client.activeUser else {
            return
        }
        
        var registered = false
        
        do {
            if useMockData {
                mockResponse(json: [
                    "subscribeKey" : UUID().uuidString,
                    "publishKey" : UUID().uuidString,
                    "userChannelGroup" : UUID().uuidString
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationRegister = self.expectation(description: "Register")
            
            user.registerForRealtime() {
                switch $0 {
                case .success:
                    registered = true
                    XCTAssertNotNil(user.realtimeRouter)
                    if self.useMockData {
                        let pubNubRealtimeRouter = user.realtimeRouter as! PubNubRealtimeRouter
                        user.realtimeRouter = PubNubRealtimeRouter(
                            user: pubNubRealtimeRouter.user,
                            subscribeKey: pubNubRealtimeRouter.subscribeKey,
                            publishKey: pubNubRealtimeRouter.publishKey,
                            userChannelGroup: pubNubRealtimeRouter.userChannelGroup,
                            pubNubType: MockPubNub.self
                        )
                    }
                case .failure:
                    XCTFail()
                }
                
                expectationRegister?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationRegister = nil
            }
        }
        
        XCTAssertTrue(registered)
        
        guard registered else {
            return
        }
        
        var usersArray: [User]? = nil
        let stream = LiveStream<SongRecommendation>(name: "SongRecommendation")
        
        do {
            if useMockData {
                mockResponse(json: [
                    [
                        "_id" : UUID().uuidString,
                        "username" : UUID().uuidString,
                        "_kmd" : [
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
                        ],
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ]
                    ],
                    [
                        "_id" : UUID().uuidString,
                        "username" : UUID().uuidString,
                        "_kmd" : [
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
                        ],
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ]
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationLookup = self.expectation(description: "Lookup")
            
            let query = Query(format: "_id != %@", user.userId)
            query.limit = 2
            user.find(query: query, client: client) {
                switch $0 {
                case .success(let users):
                    usersArray = users
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationLookup?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout * 3) { (error) in
                expectationLookup = nil
            }
        }
        
        XCTAssertNotNil(usersArray)
        
        guard let users = usersArray else {
            return
        }
        
        var granted = false
        
        do {
            XCTAssertEqual(users.count, 2)
            if let first = users.first, let last = users.last, first.userId != last.userId {
                var acl = LiveStreamAcl()
                acl.publishers.append(user.userId)
                
                if useMockData {
                    mockResponse { (request) -> HttpResponse in
                        var json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
                        json["_id"] = UUID().uuidString
                        return HttpResponse(json: json)
                    }
                }
                defer {
                    if useMockData {
                        setURLProtocol(nil)
                    }
                }
                
                weak var expectationGrantAccess = self.expectation(description: "Grant Access")
                
                stream.grantStreamAccess(userId: last.userId, acl: acl) {
                    switch $0 {
                    case .success:
                        granted = true
                    case .failure(let error):
                        XCTFail()
                    }
                    
                    expectationGrantAccess?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout * 3) { (error) in
                    expectationGrantAccess = nil
                }
            }
            
            do {
                if useMockData {
                    mockResponse(json: [
                        "_id" : UUID().uuidString,
                        "publish" : [
                            UUID().uuidString
                        ],
                        "subscribe" : [
                            user.userId
                        ],
                        "groups" : [
                            "publish" : [],
                            "subscribe" : []
                        ]
                    ])
                }
                defer {
                    if useMockData {
                        setURLProtocol(nil)
                    }
                }
                
                weak var expectationGetAccess = self.expectation(description: "Get Access")
                
                stream.streamAccess(userId: user.userId) {
                    switch $0 {
                    case .success(let acl):
                        XCTAssertEqual(acl.subscribers.first, user.userId)
                    case .failure(let error):
                        XCTFail()
                    }
                    
                    expectationGetAccess?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout * 3) { (error) in
                    expectationGetAccess = nil
                }
            }
        }
        
        XCTAssertTrue(granted)
        
        guard granted else {
            return
        }
        
        do {
            if useMockData {
                mockResponse(json: [
                    "substreamChannelName" : "\(client.appKey!).s-SongRecommendation.u-\(UUID().uuidString)"
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            let first = users.first!
            let last = users.last!
            
            weak var expectationSend = self.expectation(description: "Send")
            
            let songrec1 = SongRecommendation(name: "Imagine", artist: "John Lennon", rating: 100)
            stream.send(userId: last.userId, message: songrec1) {
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail()
                }
                expectationSend?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout * 3) { (error) in
                expectationSend = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse(completionHandler: { (request) -> HttpResponse in
                    DispatchQueue.main.async {
                        MockPubNub.default.status(category: .PNDisconnectedCategory)
                    }
                    return HttpResponse(statusCode: 204, data: Data())
                })
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationUnregister = self.expectation(description: "Unregister")
            
            user.unregisterForRealtime() {
                switch $0 {
                case .success:
                    XCTAssertNil(user.realtimeRouter)
                case .failure:
                    XCTFail()
                }
                
                expectationUnregister?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationUnregister = nil
            }
        }
    }
    
    func testStreamPublisherNotAllowed() {
        let deleteUserDuringTearDown = self.deleteUserDuringTearDown
        let realtimeTestUserId = UUID().uuidString
        self.deleteUserDuringTearDown = false
        tearDownHandler = {
            if !self.useMockData {
                self.deleteUserDuringTearDown = deleteUserDuringTearDown
            }
            self.tearDownHandler = nil
        }
        
        login(username: "realtime-test", password: "realtime-test", mockHandler: { (request) -> HttpResponse in
            return HttpResponse(json: [
                "_id" : UUID().uuidString,
                "username" : "realtime-test",
                "_kmd": [
                    "lmt" : Date().toString(),
                    "ect" : Date().toString(),
                    "authtoken" : UUID().uuidString
                ],
                "_acl" : [
                    "creator" : UUID().uuidString
                ]
            ])
        })
        
        XCTAssertNotNil(client.activeUser)
        
        guard let user = client.activeUser else {
            return
        }
        
        var registered = false
        
        do {
            if useMockData {
                mockResponse(json: [
                    "subscribeKey" : UUID().uuidString,
                    "publishKey" : UUID().uuidString,
                    "userChannelGroup" : UUID().uuidString
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationRegister = self.expectation(description: "Register")
            
            user.registerForRealtime() {
                switch $0 {
                case .success:
                    registered = true
                    XCTAssertNotNil(user.realtimeRouter)
                    if self.useMockData {
                        let pubNubRealtimeRouter = user.realtimeRouter as! PubNubRealtimeRouter
                        user.realtimeRouter = PubNubRealtimeRouter(
                            user: pubNubRealtimeRouter.user,
                            subscribeKey: pubNubRealtimeRouter.subscribeKey,
                            publishKey: pubNubRealtimeRouter.publishKey,
                            userChannelGroup: pubNubRealtimeRouter.userChannelGroup,
                            pubNubType: MockPubNub.self
                        )
                    }
                case .failure:
                    XCTFail()
                }
                
                expectationRegister?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationRegister = nil
            }
        }
        
        XCTAssertTrue(registered)
        
        guard registered else {
            return
        }
        
        var usersArray: [User]? = nil
        let stream = LiveStream<SongRecommendation>(name: "SongRecommendation")
        
        do {
            if useMockData {
                mockResponse(json: [
                    [
                        "_id" : UUID().uuidString,
                        "username" : UUID().uuidString,
                        "_kmd" : [
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
                        ],
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ]
                    ],
                    [
                        "_id" : UUID().uuidString,
                        "username" : UUID().uuidString,
                        "_kmd" : [
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
                        ],
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ]
                    ]
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationLookup = self.expectation(description: "Lookup")
            
            let query = Query(format: "_id != %@", user.userId)
            query.limit = 2
            user.find(query: query, client: client) {
                switch $0 {
                case .success(let users):
                    usersArray = users
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationLookup?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout * 3) { (error) in
                expectationLookup = nil
            }
        }
        
        XCTAssertNotNil(usersArray)
        
        guard let users = usersArray else {
            return
        }
        
        do {
            if useMockData {
                mockResponse(statusCode: 401, json: [
                    "error" : "InsufficientCredentials",
                    "description" : "The credentials used to authenticate this request are not authorized to run this operation. Please retry your request with appropriate credentials",
                    "debug" : "You do not have access to publish to this substream"
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            let last = users.last!
            
            weak var expectationSend = self.expectation(description: "Send")
            
            let songrec1 = SongRecommendation(name: "Imagine", artist: "John Lennon", rating: 100)
            stream.send(userId: last.userId, message: songrec1) {
                switch $0 {
                case .success:
                    XCTFail()
                case .failure(let error):
                    XCTAssertNotNil(error as? Kinvey.Error)
                    if let error = error as? Kinvey.Error {
                        switch error {
                        case .unauthorized(let httpResponse, let data, let error, let debug, let description):
                            XCTAssertEqual(httpResponse?.statusCode, 401)
                            XCTAssertGreaterThan(data?.count ?? 0, 0)
                            XCTAssertEqual(error, "InsufficientCredentials")
                            XCTAssertEqual(debug, "You do not have access to publish to this substream")
                            XCTAssertEqual(description, "The credentials used to authenticate this request are not authorized to run this operation. Please retry your request with appropriate credentials")
                        default:
                            XCTFail()
                        }
                    }
                }
                expectationSend?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout * 3) { (error) in
                expectationSend = nil
            }
        }
    }
    
    func testStream1MinuteTTL() {
        let deleteUserDuringTearDown = self.deleteUserDuringTearDown
        let realtimeTestUserId = UUID().uuidString
        self.deleteUserDuringTearDown = false
        tearDownHandler = {
            if !self.useMockData {
                self.deleteUserDuringTearDown = deleteUserDuringTearDown
            }
            self.tearDownHandler = nil
        }
        
        login(username: "realtime-test", password: "realtime-test", mockHandler: { (request) -> HttpResponse in
            return HttpResponse(json: [
                "_id" : UUID().uuidString,
                "username" : "realtime-test",
                "_kmd": [
                    "lmt" : Date().toString(),
                    "ect" : Date().toString(),
                    "authtoken" : UUID().uuidString
                ],
                "_acl" : [
                    "creator" : UUID().uuidString
                ]
                ])
        })
        
        XCTAssertNotNil(client.activeUser)
        
        guard let user = client.activeUser else {
            return
        }
        
        var registered = false
        
        do {
            if useMockData {
                mockResponse(json: [
                    "subscribeKey" : UUID().uuidString,
                    "publishKey" : UUID().uuidString,
                    "userChannelGroup" : UUID().uuidString
                    ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationRegister = self.expectation(description: "Register")
            
            user.registerForRealtime() {
                switch $0 {
                case .success:
                    registered = true
                    XCTAssertNotNil(user.realtimeRouter)
                    if self.useMockData {
                        let pubNubRealtimeRouter = user.realtimeRouter as! PubNubRealtimeRouter
                        user.realtimeRouter = PubNubRealtimeRouter(
                            user: pubNubRealtimeRouter.user,
                            subscribeKey: pubNubRealtimeRouter.subscribeKey,
                            publishKey: pubNubRealtimeRouter.publishKey,
                            userChannelGroup: pubNubRealtimeRouter.userChannelGroup,
                            pubNubType: MockPubNub.self
                        )
                    }
                case .failure:
                    XCTFail()
                }
                
                expectationRegister?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationRegister = nil
            }
        }
        
        XCTAssertTrue(registered)
        
        guard registered else {
            return
        }
        
        var usersArray: [User]? = nil
        let stream = LiveStream<SongRecommendation>(name: "SongRecommendation1MinuteTTL")
        
        do {
            if useMockData {
                mockResponse(json: [
                    [
                        "_id" : UUID().uuidString,
                        "username" : UUID().uuidString,
                        "_kmd" : [
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
                        ],
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ]
                    ],
                    [
                        "_id" : UUID().uuidString,
                        "username" : UUID().uuidString,
                        "_kmd" : [
                            "lmt" : Date().toString(),
                            "ect" : Date().toString()
                        ],
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ]
                    ]
                    ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationLookup = self.expectation(description: "Lookup")
            
            let query = Query(format: "_id != %@", user.userId)
            query.limit = 2
            user.find(query: query, client: client) {
                switch $0 {
                case .success(let users):
                    usersArray = users
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationLookup?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout * 3) { (error) in
                expectationLookup = nil
            }
        }
        
        XCTAssertNotNil(usersArray)
        
        guard let users = usersArray else {
            return
        }
        
        var granted = false
        
        do {
            XCTAssertEqual(users.count, 2)
            if let first = users.first, let last = users.last, first.userId != last.userId {
                var acl = LiveStreamAcl()
                acl.publishers.append(user.userId)
                acl.subscribers.append(user.userId)
                
                acl.publishers.append(first.userId)
                acl.subscribers.append(last.userId)
                
                if useMockData {
                    mockResponse { (request) -> HttpResponse in
                        var json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
                        json["_id"] = UUID().uuidString
                        return HttpResponse(json: json)
                    }
                }
                defer {
                    if useMockData {
                        setURLProtocol(nil)
                    }
                }
                
                weak var expectationGrantAccess = self.expectation(description: "Grant Access")
                
                stream.grantStreamAccess(userId: last.userId, acl: acl) {
                    switch $0 {
                    case .success:
                        granted = true
                    case .failure(let error):
                        XCTFail()
                    }
                    
                    expectationGrantAccess?.fulfill()
                }
                
                waitForExpectations(timeout: defaultTimeout * 3) { (error) in
                    expectationGrantAccess = nil
                }
            }
        }
        
        XCTAssertTrue(granted)
        
        guard granted else {
            return
        }
        
        do {
            if useMockData {
                mockResponse(json: [
                    "substreamChannelName" : "\(client.appKey!).s-SongRecommendation.u-\(UUID().uuidString)"
                    ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            let first = users.first!
            let last = users.last!
            
            weak var expectationSend = self.expectation(description: "Send")
            
            let songrec1 = SongRecommendation(name: "Imagine", artist: "John Lennon", rating: 100)
            stream.send(userId: last.userId, message: songrec1) {
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail()
                }
                expectationSend?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout * 3) { (error) in
                expectationSend = nil
            }
        }
        
        if !useMockData {
            Thread.sleep(forTimeInterval: 60)
        }
        
        do {
            if useMockData {
                mockResponse(json: [
                    "substreamChannelName" : "\(client.appKey!).s-SongRecommendation.u-\(UUID().uuidString)"
                    ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            let first = users.first!
            let last = users.last!
            
            weak var expectationSend = self.expectation(description: "Send")
            
            let songrec1 = SongRecommendation(name: "Imagine", artist: "John Lennon", rating: 100)
            stream.send(userId: last.userId, message: songrec1) {
                switch $0 {
                case .success:
                    break
                case .failure(let error):
                    XCTFail()
                }
                expectationSend?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout * 3) { (error) in
                expectationSend = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse(completionHandler: { (request) -> HttpResponse in
                    DispatchQueue.main.async {
                        MockPubNub.default.status(category: .PNDisconnectedCategory)
                    }
                    return HttpResponse(statusCode: 204, data: Data())
                })
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationUnregister = self.expectation(description: "Unregister")
            
            user.unregisterForRealtime() {
                switch $0 {
                case .success:
                    XCTAssertNil(user.realtimeRouter)
                case .failure:
                    XCTFail()
                }
                
                expectationUnregister?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationUnregister = nil
            }
        }
    }
    
}

final class MockPubNub: PubNubType {
    
    static let `default` = MockPubNub()
    
    private var listeners = [PNObjectEventListener]()
    private var pubNub: PubNub!
    
    class func clientWithConfiguration(_ configuration: PNConfiguration) -> MockPubNub {
        MockPubNub.default.pubNub = PubNub.clientWithConfiguration(configuration)
        return MockPubNub.default
    }
    
    func addListener(_ listener: PNObjectEventListener) {
        listeners.append(listener)
    }
    
    func subscribeToChannelGroups(_ groups: [String], withPresence shouldObservePresence: Bool) {
    }
    
    func status(category: PNStatusCategory) {
        let status = MockStatus(category: category)
        for listener in listeners {
            listener.client!(pubNub, didReceive: status)
        }
    }
    
    func error(channels: [String], information: String, category: PNStatusCategory = .PNUnknownCategory) {
        let errorData = MockErrorData(channels: channels, information: information)
        let errorStatus = MockErrorStatus(errorData: errorData)
        for listener in listeners {
            listener.client!(pubNub, didReceive: errorStatus)
        }
    }
    
    func publish(_ message: Any, toChannel channel: String, withCompletion block: PNPublishCompletionBlock? = nil) {
        let messageData = MockMessageData(channel: channel, message: message)
        let messageResult = MockMessageResult(messageData: messageData)
        for listener in listeners {
            listener.client!(pubNub, didReceiveMessage: messageResult)
        }
        
        if let block = block {
            let publishData = MockPublishData()
            let publishStatus = MockPublishStatus(data: publishData)
            block(publishStatus)
        }
    }
    
}

class MockMessageResult: PNMessageResult {
    
    private let mockMessageData: MockMessageData
    
    init(messageData: MockMessageData) {
        mockMessageData = messageData
    }
    
    override var data: PNMessageData {
        return mockMessageData
    }
    
}

class MockMessageData: PNMessageData {
    
    private let mockChannel: String
    private let mockMessage: Any?
    
    init(channel: String, message: Any?) {
        mockChannel = channel
        mockMessage = message
    }
    
    override var channel: String {
        return mockChannel
    }
    
    override var message: Any? {
        return mockMessage
    }
    
}

class MockStatus: PNStatus {
    
    private let mockCategory: PNStatusCategory
    
    init(category: PNStatusCategory) {
        mockCategory = category
    }
    
    override var category: PNStatusCategory {
        return mockCategory
    }
    
}

class MockErrorStatus: PNErrorStatus {
    
    private let mockErrorData: PNErrorData
    
    init(errorData: PNErrorData) {
        mockErrorData = errorData
    }
    
    override var isError: Bool {
        return true
    }
    
    override var errorData: PNErrorData {
        return mockErrorData
    }
    
}

class MockErrorData: PNErrorData {
    
    private let mockChannels: [String]
    private let mockInformation: String
    
    init(channels: [String], information: String) {
        mockChannels = channels
        mockInformation = information
    }
    
    override var channels: [String] {
        return mockChannels
    }
    
    override var information: String {
        return mockInformation
    }
    
}

class MockPublishStatus: PNPublishStatus {
    
    private let mockData: PNPublishData
    
    init(data: PNPublishData) {
        mockData = data
    }
    
    override var data: PNPublishData {
        return mockData
    }
    
}

class MockPublishData: PNPublishData {
    
}
