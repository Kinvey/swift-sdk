//
//  KinveyMacAppTests.swift
//  KinveyMacAppTests
//
//  Created by Victor Hugo on 2017-05-31.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
import KinveyMacApp
@testable import Kinvey

class RealtimeMacAppTests: KinveyTestCase {
    
    func testListen() {
        let senderUsername = UUID().uuidString
        let senderPassword = UUID().uuidString
        signUp(username: senderUsername, password: senderPassword)
        
        XCTAssertNotNil(client.activeUser)
        
        guard let sender = client.activeUser else {
            return
        }
        
        sender.logout()
        
        XCTAssertNil(client.activeUser)
        
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
        
        defer {
            user.logout()
            
            if !useMockData {
                login(username: senderUsername, password: senderPassword)
            }
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
        
        let stream = LiveStream<SongRecommendation>(name: "SongRecommendation")
        
        var granted = false
        
        do {
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
            
            var acl = LiveStreamAcl()
            acl.publishers.append(sender.userId)
            acl.subscribers.append(user.userId)
            
            weak var expectationGrantAccess = self.expectation(description: "Grant Access")
            
            stream.grantStreamAccess(userId: user.userId, acl: acl) {
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
        
        XCTAssertTrue(granted)
        
        guard granted else {
            return
        }
        
        do {
            let songName = "Imagine"
            let songArtist = "John Lennon"
            let songRating = 100
            
            if useMockData {
                mockResponse { (request) -> HttpResponse in
                    let substreamChannelName = "\(self.client.appKey!).s-SongRecommendation.u-\(UUID().uuidString)"
                    let songRecommendation = SongRecommendation(name: songName, artist: songArtist, rating: songRating)
                    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .seconds(1)) {
                        MockPubNub.default.publish(songRecommendation.toJSON(), toChannel: substreamChannelName)
                    }
                    return HttpResponse(json: [
                        "substreamChannelName" : substreamChannelName
                    ])
                }
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationListen = self.expectation(description: "Listen")
            
            stream.listen(onNext: { (songRecommendation) in
                XCTAssertEqual(songRecommendation.name, songName)
                XCTAssertEqual(songRecommendation.artist, songArtist)
                XCTAssertEqual(songRecommendation.rating, songRating)
                
                expectationListen?.fulfill()
            }, onStatus: { (realtimeStatus) in
            }, onError: { (error) in
                XCTFail()
            })
            
            if !useMockData {
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .seconds(3)) {
                    let process = Process()
                    let currentDirectoryUrl = URL(fileURLWithPath: ProcessInfo.processInfo.arguments.first!)
                        .deletingLastPathComponent()
                        .deletingLastPathComponent()
                        .deletingLastPathComponent()
                        .deletingLastPathComponent()
                        .deletingLastPathComponent()
                        .deletingLastPathComponent()
                        .deletingLastPathComponent()
                        .deletingLastPathComponent()
                        .appendingPathComponent("Products")
                        .appendingPathComponent("Debug")
                    process.currentDirectoryPath = currentDirectoryUrl.path
                    process.launchPath = currentDirectoryUrl
                        .appendingPathComponent("Realtime Sender.app")
                        .appendingPathComponent("Contents")
                        .appendingPathComponent("MacOS")
                        .appendingPathComponent("Realtime Sender")
                        .path
                    process.arguments = [
                        "-appKey", self.client.appKey!,
                        "-appSecret", self.client.appSecret!,
                        "-hostUrl", self.client.apiHostName.absoluteString,
                        "-username", senderUsername,
                        "-password", senderPassword,
                        "-receiverId", user.userId,
                        "-songName", songName,
                        "-songArtist", songArtist,
                        "-songRating", "\(songRating)"
                    ]
                    
                    let standardOutput = Pipe()
                    let standardError = Pipe()
                    
                    process.standardOutput = standardOutput
                    process.standardError = standardError
                    
                    process.launch()
                    process.waitUntilExit()
                    
                    print(String(data: standardOutput.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!)
                    print(String(data: standardError.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!)
                }
            }
            
            waitForExpectations(timeout: defaultTimeout * 3) { (error) in
                expectationListen = nil
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
