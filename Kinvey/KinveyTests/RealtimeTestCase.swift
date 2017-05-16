//
//  RealmtimeTests.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-05-12.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey
import PubNub

class RealmtimeTestCase: KinveyTestCase {
    
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
                
                dataStoreSync.subscribe(subscription: {
                    switch $0 {
                    case .success:
                        break
                    case .failure:
                        XCTFail()
                    }
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
                    dataStoreNetwork.save(person) { (result: Result<Person, Swift.Error>) in
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
            switch $0 {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error.localizedDescription, "Active User not found")
            }
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
    
    func testSubscribeNotRegisterForRealmtime() {
        signUp()
        
        let dataStore = DataStore<Person>.collection(.sync)
        
        weak var expectationSubscribe = self.expectation(description: "Subscribe")
        
        dataStore.subscribe(subscription: {
            switch $0 {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error.localizedDescription, "Active User not register for realtime")
            }
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
                    switch $0 {
                    case .success:
                        XCTFail()
                    case .failure(let error):
                        XCTAssertTimeoutError(error)
                    }
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
                    switch $0 {
                    case .success:
                        break
                    case .failure:
                        XCTFail()
                    }
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
    
    func testUnSubscribeNotRegisterForRealmtime() {
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
