//
//  DateTestCase.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-04-24.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class DateTestCase: KinveyTestCase {
    
    func testDateFormatWithMillis() {
        XCTAssertEqual("2017-03-30T12:30:00.733Z".toDate(), Date(timeIntervalSince1970: 1490877000.733))
    }
    
    func testDateFormatWithoutMillis() {
        XCTAssertEqual("2017-03-30T12:30:00Z".toDate(), Date(timeIntervalSince1970: 1490877000))
    }
    
    func testDateFormatNotSupported() {
        XCTAssertNil("2017-03-30 12:30:00".toDate())
    }
    
    func testTTLSeconds() {
        let (time, unit) = 10.seconds
        XCTAssertEqual(unit.toTimeInterval(time), TimeInterval(10))
    }
    
    func testTTLMinutes() {
        let (time, unit) = 10.minutes
        XCTAssertEqual(unit.toTimeInterval(time), TimeInterval(10 * 60))
    }
    
    func testTTLHours() {
        let (time, unit) = 10.hours
        XCTAssertEqual(unit.toTimeInterval(time), TimeInterval(10 * 60 * 60))
    }
    
    func testTTLDays() {
        let (time, unit) = 10.days
        XCTAssertEqual(unit.toTimeInterval(time), TimeInterval(10 * 60 * 60 * 24))
    }
    
    func testTTLWeeks() {
        let (time, unit) = 10.weeks
        XCTAssertEqual(unit.toTimeInterval(time), TimeInterval(10 * 60 * 60 * 24 * 7))
    }
    
    func testDateTransform() {
        let transform = AnyTransform(KinveyDateTransform())
        
        let date = Date()
        let dateString = date.toString()
        
        XCTAssertEqual(date.timeIntervalSinceReferenceDate, (transform.transformFromJSON(dateString) as! Date).timeIntervalSinceReferenceDate, accuracy: 0.0009)
        XCTAssertEqual(dateString, transform.transformToJSON(date) as? String)
    }
    
    func testQueryDate() {
        signUp()
        
        let store = DataStore<Event>.collection(.network)
        
        let publishDate = Date()
        
        client.logNetworkEnabled = true
        let nEvents = 4
        
        var mockObjects = [JsonDictionary]()
        
        for _ in 1...nEvents {
            if useMockData {
                let json: JsonDictionary = [
                    "date" : publishDate.toString(),
                    "_acl" : [
                        "creator" : client.activeUser!.userId
                    ],
                    "_kmd" : [
                        "lmt" : Date().toString(),
                        "ect" : Date().toString()
                    ],
                    "_id" : UUID().uuidString
                ]
                mockObjects.append(json)
                mockResponse(json: json)
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationSave = self.expectation(description: "Save")
            
            let event = Event()
            event.publishDate = publishDate
            store.save(event) { event, error in
                XCTAssertNotNil(event)
                XCTAssertNil(error)
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationSave = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse(json: mockObjects)
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationFind = self.expectation(description: "Find")
            
            let query = Query(format: "acl.creator == %@ AND publishDate >= %@", Kinvey.sharedClient.activeUser!.userId, Date(timeIntervalSinceNow: -60))
            store.find(query) { events, error in
                XCTAssertNotNil(events)
                XCTAssertNil(error)
                
                XCTAssertEqual(events?.count, nEvents)
                if let events = events {
                    for event in events {
                        XCTAssertNotNil(event.publishDate)
                        if let date = event.publishDate {
                            XCTAssertEqual(date.timeIntervalSinceReferenceDate, publishDate.timeIntervalSinceReferenceDate, accuracy: 0.0009)
                        }
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationFind = nil
            }
        }
    }
    
}
