//
//  CustomEndpointTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-30.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
import ObjectMapper
import Kinvey

class CustomEndpointTests: KinveyTestCase {
    
    func testCustomEndpoint() {
        signUp()
        
        let params: [String : Any] = [
            "stringParam" : "Test",
            "numberParam" : 1,
            "booleanParam" : true,
            "queryParam" : Query(format: "age >= %@", 21)
        ]
        
        if useMockData {
            mockResponse(json: [
                "queryParam" : [
                    "age" : [
                        "$gte" : 21
                    ]
                ],
                "stringParam" : "Test",
                "numberParam" : 1,
                "booleanParam" : true
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        struct EchoType: Mappable {
            
            var query: [String : Any]?
            var string: String?
            var number: Int?
            var boolean: Bool?
            
            public init?(map: Map) {
            }
            
            public mutating func mapping(map: Map) {
                query <- map["queryParam"]
                string <- map["stringParam"]
                number <- map["numberParam"]
                boolean <- map["booleanParam"]
            }
            
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: CustomEndpoint.Params(params)) { (response: EchoType?, error) in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            
            if let response = response {
                XCTAssertEqual(response.string, "Test")
                XCTAssertEqual(response.number, 1)
                XCTAssertEqual(response.boolean, true)
                
                XCTAssertNotNil(response.query)
                if let queryParam = response.query {
                    XCTAssertNotNil(queryParam["age"] as? JsonDictionary)
                    if let age = queryParam["age"] as? JsonDictionary {
                        XCTAssertNotNil(age["$gte"] as? Int)
                        if let age = age["$gte"] as? Int {
                            XCTAssertEqual(age, 21)
                        }
                    }
                }
            }
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func testCustomEndpointNilParam() {
        signUp()
        
        if useMockData {
            mockResponse(json: [:])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        let params: JsonDictionary? = nil
        CustomEndpoint.execute("echo", params: params) { (response: JsonDictionary?, error) in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            
            if let response = response {
                XCTAssertEqual(response.count, 0)
            }
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func testCustomEndpointArrayNilParam() {
        signUp()
        
        if useMockData {
            mockResponse(json: [:])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        let params: JsonDictionary? = nil
        CustomEndpoint.execute("echo", params: params) { (response: [JsonDictionary]?, error) in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func testCustomEndpointStaticMappable() {
        signUp()
        
        let params: [String : Any] = [
            "stringParam" : "Test",
            "numberParam" : 1,
            "booleanParam" : true,
            "queryParam" : Query(format: "age >= %@", 21)
        ]
        
        if useMockData {
            mockResponse(json: [
                "queryParam" : [
                    "age" : [
                        "$gte" : 21
                    ]
                ],
                "stringParam" : "Test",
                "numberParam" : 1,
                "booleanParam" : true
                ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        struct EchoType: StaticMappable {
            
            var query: [String : Any]?
            var string: String?
            var number: Int?
            var boolean: Bool?
            
            public static func objectForMapping(map: Map) -> BaseMappable? {
                return EchoType()
            }
            
            public mutating func mapping(map: Map) {
                query <- map["queryParam"]
                string <- map["stringParam"]
                number <- map["numberParam"]
                boolean <- map["booleanParam"]
            }
            
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: CustomEndpoint.Params(params)) { (response: EchoType?, error) in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            
            if let response = response {
                XCTAssertEqual(response.string, "Test")
                XCTAssertEqual(response.number, 1)
                XCTAssertEqual(response.boolean, true)
                
                XCTAssertNotNil(response.query)
                if let queryParam = response.query {
                    XCTAssertNotNil(queryParam["age"] as? JsonDictionary)
                    if let age = queryParam["age"] as? JsonDictionary {
                        XCTAssertNotNil(age["$gte"] as? Int)
                        if let age = age["$gte"] as? Int {
                            XCTAssertEqual(age, 21)
                        }
                    }
                }
            }
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func testCustomEndpointJsonArray() {
        signUp()
        
        let params: [String : Any] = [
            "stringParam" : "Test",
            "numberParam" : 1,
            "booleanParam" : true,
            "queryParam" : Query(format: "age >= %@", 21)
        ]
        
        if useMockData {
            mockResponse(json: [
                [
                    "queryParam" : [
                        "age" : [
                            "$gte" : 21
                        ]
                    ],
                    "stringParam" : "Test 1",
                    "numberParam" : 1,
                    "booleanParam" : true
                ],
                [
                    "queryParam" : [
                        "age" : [
                            "$gte" : 22
                        ]
                    ],
                    "stringParam" : "Test 2",
                    "numberParam" : 0,
                    "booleanParam" : false
                ]
                ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        struct EchoType: Mappable {
            
            var query: [String : Any]?
            var string: String?
            var number: Int?
            var boolean: Bool?
            
            public init?(map: Map) {
            }
            
            public mutating func mapping(map: Map) {
                query <- map["queryParam"]
                string <- map["stringParam"]
                number <- map["numberParam"]
                boolean <- map["booleanParam"]
            }
            
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: params) { (response: [JsonDictionary]?, error) in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            
            if let response = response {
                XCTAssertEqual(response.count, 2)
                
                if let response = response.first {
                    XCTAssertEqual(response["stringParam"] as? String, "Test 1")
                    XCTAssertEqual(response["numberParam"] as? Int, 1)
                    XCTAssertEqual(response["booleanParam"] as? Bool, true)
                    
                    XCTAssertNotNil(response["queryParam"] as? JsonDictionary)
                    if let queryParam = response["queryParam"] as? JsonDictionary {
                        XCTAssertNotNil(queryParam["age"] as? JsonDictionary)
                        if let age = queryParam["age"] as? JsonDictionary {
                            XCTAssertNotNil(age["$gte"] as? Int)
                            if let age = age["$gte"] as? Int {
                                XCTAssertEqual(age, 21)
                            }
                        }
                    }
                }
                
                if let response = response.last {
                    XCTAssertEqual(response["stringParam"] as? String, "Test 2")
                    XCTAssertEqual(response["numberParam"] as? Int, 0)
                    XCTAssertEqual(response["booleanParam"] as? Bool, false)
                    
                    XCTAssertNotNil(response["queryParam"] as? JsonDictionary)
                    if let queryParam = response["queryParam"] as? JsonDictionary {
                        XCTAssertNotNil(queryParam["age"] as? JsonDictionary)
                        if let age = queryParam["age"] as? JsonDictionary {
                            XCTAssertNotNil(age["$gte"] as? Int)
                            if let age = age["$gte"] as? Int {
                                XCTAssertEqual(age, 22)
                            }
                        }
                    }
                }
            }
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func testCustomEndpointArray() {
        signUp()
        
        let params: [String : Any] = [
            "stringParam" : "Test",
            "numberParam" : 1,
            "booleanParam" : true,
            "queryParam" : Query(format: "age >= %@", 21)
        ]
        
        if useMockData {
            mockResponse(json: [
                [
                    "queryParam" : [
                        "age" : [
                            "$gte" : 21
                        ]
                    ],
                    "stringParam" : "Test 1",
                    "numberParam" : 1,
                    "booleanParam" : true
                ],
                [
                    "queryParam" : [
                        "age" : [
                            "$gte" : 22
                        ]
                    ],
                    "stringParam" : "Test 2",
                    "numberParam" : 0,
                    "booleanParam" : false
                ]
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        struct EchoType: Mappable {
            
            var query: [String : Any]?
            var string: String?
            var number: Int?
            var boolean: Bool?
            
            public init?(map: Map) {
            }
            
            public mutating func mapping(map: Map) {
                query <- map["queryParam"]
                string <- map["stringParam"]
                number <- map["numberParam"]
                boolean <- map["booleanParam"]
            }
            
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: CustomEndpoint.Params(params)) { (response: [EchoType]?, error) in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            
            if let response = response {
                XCTAssertEqual(response.count, 2)
                
                if let response = response.first {
                    XCTAssertEqual(response.string, "Test 1")
                    XCTAssertEqual(response.number, 1)
                    XCTAssertEqual(response.boolean, true)
                    
                    XCTAssertNotNil(response.query)
                    if let queryParam = response.query {
                        XCTAssertNotNil(queryParam["age"] as? JsonDictionary)
                        if let age = queryParam["age"] as? JsonDictionary {
                            XCTAssertNotNil(age["$gte"] as? Int)
                            if let age = age["$gte"] as? Int {
                                XCTAssertEqual(age, 21)
                            }
                        }
                    }
                }
                
                if let response = response.last {
                    XCTAssertEqual(response.string, "Test 2")
                    XCTAssertEqual(response.number, 0)
                    XCTAssertEqual(response.boolean, false)
                    
                    XCTAssertNotNil(response.query)
                    if let queryParam = response.query {
                        XCTAssertNotNil(queryParam["age"] as? JsonDictionary)
                        if let age = queryParam["age"] as? JsonDictionary {
                            XCTAssertNotNil(age["$gte"] as? Int)
                            if let age = age["$gte"] as? Int {
                                XCTAssertEqual(age, 22)
                            }
                        }
                    }
                }
            }
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func testCustomEndpointArrayStaticMappable() {
        signUp()
        
        let params: [String : Any] = [
            "stringParam" : "Test",
            "numberParam" : 1,
            "booleanParam" : true,
            "queryParam" : Query(format: "age >= %@", 21)
        ]
        
        if useMockData {
            mockResponse(json: [
                [
                    "queryParam" : [
                        "age" : [
                            "$gte" : 21
                        ]
                    ],
                    "stringParam" : "Test 1",
                    "numberParam" : 1,
                    "booleanParam" : true
                ],
                [
                    "queryParam" : [
                        "age" : [
                            "$gte" : 22
                        ]
                    ],
                    "stringParam" : "Test 2",
                    "numberParam" : 0,
                    "booleanParam" : false
                ]
                ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        struct EchoType: StaticMappable {
            
            var query: [String : Any]?
            var string: String?
            var number: Int?
            var boolean: Bool?
            
            public static func objectForMapping(map: Map) -> BaseMappable? {
                return EchoType()
            }
            
            public mutating func mapping(map: Map) {
                query <- map["queryParam"]
                string <- map["stringParam"]
                number <- map["numberParam"]
                boolean <- map["booleanParam"]
            }
            
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: CustomEndpoint.Params(params)) { (response: [EchoType]?, error) in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            
            if let response = response {
                XCTAssertEqual(response.count, 2)
                
                if let response = response.first {
                    XCTAssertEqual(response.string, "Test 1")
                    XCTAssertEqual(response.number, 1)
                    XCTAssertEqual(response.boolean, true)
                    
                    XCTAssertNotNil(response.query)
                    if let queryParam = response.query {
                        XCTAssertNotNil(queryParam["age"] as? JsonDictionary)
                        if let age = queryParam["age"] as? JsonDictionary {
                            XCTAssertNotNil(age["$gte"] as? Int)
                            if let age = age["$gte"] as? Int {
                                XCTAssertEqual(age, 21)
                            }
                        }
                    }
                }
                
                if let response = response.last {
                    XCTAssertEqual(response.string, "Test 2")
                    XCTAssertEqual(response.number, 0)
                    XCTAssertEqual(response.boolean, false)
                    
                    XCTAssertNotNil(response.query)
                    if let queryParam = response.query {
                        XCTAssertNotNil(queryParam["age"] as? JsonDictionary)
                        if let age = queryParam["age"] as? JsonDictionary {
                            XCTAssertNotNil(age["$gte"] as? Int)
                            if let age = age["$gte"] as? Int {
                                XCTAssertEqual(age, 22)
                            }
                        }
                    }
                }
            }
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func testQueryCount() {
        signUp()
        
        let params = [
            "query" : Query(format: "colors.@count == %@", 2)
        ]
        
        if useMockData {
            mockResponse(json: [
                "query" : [
                    "colors" : [
                        "$size" : 2
                    ]
                ]
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: params) { (response: JsonDictionary?, error) in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            
            if let response = response {
                XCTAssertEqual(response.count, 1)
                
                XCTAssertNotNil(response["query"] as? JsonDictionary)
                if let query = response["query"] as? JsonDictionary {
                    XCTAssertNotNil(query["colors"] as? JsonDictionary)
                    if let colors = query["colors"] as? JsonDictionary {
                        XCTAssertNotNil(colors["$size"] as? Int)
                        if let size = colors["$size"] as? Int {
                            XCTAssertEqual(size, 2)
                        }
                    }
                }
            }
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func testQueryCountMappable() {
        signUp()
        
        struct QueryMappable: Mappable {
            
            var query: Query?
            
            init?(map: Map) {
            }
            
            init(_ query: Query?) {
                self.query = query
            }
            
            public mutating func mapping(map: Map) {
                query <- map["query"]
            }
            
        }
        
        let params = CustomEndpoint.Params(QueryMappable(Query(format: "colors.@count == %@", 2)))
        
        if useMockData {
            mockResponse(completionHandler: { (request) -> HttpResponse in
                let json = try! JSONSerialization.jsonObject(with: request)
                XCTAssertNotNil(json as? JsonDictionary)
                if let json = json as? JsonDictionary {
                    XCTAssertNotNil(json["query"])
                    if let query = json["query"] as? JsonDictionary {
                        XCTAssertEqual(query.count, 1)
                        XCTAssertNotNil(query["colors"] as? JsonDictionary)
                        if let colors = query["colors"] as? JsonDictionary {
                            XCTAssertNotNil(colors["$size"] as? Int)
                            if let size = colors["$size"] as? Int {
                                XCTAssertEqual(size, 2)
                            }
                        }
                    }
                }
                return HttpResponse(json: json as! JsonDictionary)
            })
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: params) { (response: JsonDictionary?, error) in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            
            if let response = response {
                XCTAssertEqual(response.count, 1)
                
                XCTAssertNotNil(response["query"] as? JsonDictionary)
                if let query = response["query"] as? JsonDictionary {
                    XCTAssertNotNil(query["colors"] as? JsonDictionary)
                    if let colors = query["colors"] as? JsonDictionary {
                        XCTAssertNotNil(colors["$size"] as? Int)
                        if let size = colors["$size"] as? Int {
                            XCTAssertEqual(size, 2)
                        }
                    }
                }
            }
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func testQueryCountStaticMappable() {
        signUp()
        
        struct QueryMappable: StaticMappable {
            
            var query: Query?
            
            public static func objectForMapping(map: Map) -> BaseMappable? {
                return QueryMappable(nil)
            }
            
            init(_ query: Query?) {
                self.query = query
            }
            
            public mutating func mapping(map: Map) {
                query <- map["query"]
            }
            
        }
        
        let params = CustomEndpoint.Params(QueryMappable(Query(format: "colors.@count == %@", 2)))
        
        if useMockData {
            mockResponse(completionHandler: { (request) -> HttpResponse in
                let json = try! JSONSerialization.jsonObject(with: request)
                XCTAssertNotNil(json as? JsonDictionary)
                if let json = json as? JsonDictionary {
                    XCTAssertNotNil(json["query"])
                    if let query = json["query"] as? JsonDictionary {
                        XCTAssertEqual(query.count, 1)
                        XCTAssertNotNil(query["colors"] as? JsonDictionary)
                        if let colors = query["colors"] as? JsonDictionary {
                            XCTAssertNotNil(colors["$size"] as? Int)
                            if let size = colors["$size"] as? Int {
                                XCTAssertEqual(size, 2)
                            }
                        }
                    }
                }
                return HttpResponse(json: json as! JsonDictionary)
            })
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: params) { (response: JsonDictionary?, error) in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            
            if let response = response {
                XCTAssertEqual(response.count, 1)
                
                XCTAssertNotNil(response["query"] as? JsonDictionary)
                if let query = response["query"] as? JsonDictionary {
                    XCTAssertNotNil(query["colors"] as? JsonDictionary)
                    if let colors = query["colors"] as? JsonDictionary {
                        XCTAssertNotNil(colors["$size"] as? Int)
                        if let size = colors["$size"] as? Int {
                            XCTAssertEqual(size, 2)
                        }
                    }
                }
            }
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func testQueryCountStaticMappableJsonArrayReturn() {
        signUp()
        
        struct QueryMappable: StaticMappable {
            
            var query: [Query]?
            
            public static func objectForMapping(map: Map) -> BaseMappable? {
                return QueryMappable(nil)
            }
            
            init(_ query: [Query]?) {
                self.query = query
            }
            
            public mutating func mapping(map: Map) {
                query <- map["query"]
            }
            
        }
        
        let params = CustomEndpoint.Params(QueryMappable([Query(format: "colors.@count == %@", 2), Query(format: "colors.@count == %@", 5)]))
        
        if useMockData {
            mockResponse(completionHandler: { (request) -> HttpResponse in
                let json = try! JSONSerialization.jsonObject(with: request) as? JsonDictionary
                XCTAssertNotNil(json)
                if let json = json {
                    XCTAssertNotNil(json["query"])
                    if let query = json["query"] as? [JsonDictionary] {
                        XCTAssertEqual(query.count, 2)
                        if let query = query.first {
                            XCTAssertEqual(query.count, 1)
                            XCTAssertNotNil(query["colors"] as? JsonDictionary)
                            if let colors = query["colors"] as? JsonDictionary {
                                XCTAssertNotNil(colors["$size"] as? Int)
                                if let size = colors["$size"] as? Int {
                                    XCTAssertEqual(size, 2)
                                }
                            }
                        }
                        if let query = query.last {
                            XCTAssertEqual(query.count, 1)
                            XCTAssertNotNil(query["colors"] as? JsonDictionary)
                            if let colors = query["colors"] as? JsonDictionary {
                                XCTAssertNotNil(colors["$size"] as? Int)
                                if let size = colors["$size"] as? Int {
                                    XCTAssertEqual(size, 5)
                                }
                            }
                        }
                    }
                }
                return HttpResponse(json: json!["query"] as! [JsonDictionary])
            })
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echoQueries", params: params) { (response: [JsonDictionary]?, error) in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            
            if let response = response {
                XCTAssertEqual(response.count, 2)
                
                XCTAssertNotNil(response.first)
                if let query = response.first {
                    XCTAssertNotNil(query["colors"] as? JsonDictionary)
                    if let colors = query["colors"] as? JsonDictionary {
                        XCTAssertNotNil(colors["$size"] as? Int)
                        if let size = colors["$size"] as? Int {
                            XCTAssertEqual(size, 2)
                        }
                    }
                }
            
                XCTAssertNotNil(response.last)
                if let query = response.last {
                    XCTAssertNotNil(query["colors"] as? JsonDictionary)
                    if let colors = query["colors"] as? JsonDictionary {
                        XCTAssertNotNil(colors["$size"] as? Int)
                        if let size = colors["$size"] as? Int {
                            XCTAssertEqual(size, 5)
                        }
                    }
                }
            }
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func test404Error() {
        signUp()
        
        let params = [String : Any]()
        
        if useMockData {
            mockResponse(statusCode: 404, json: [:])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: params) { (response: JsonDictionary?, error) in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func test404ErrorNoCompletionBlock() {
        signUp()
        
        let params = [String : Any]()
        
        if useMockData {
            mockResponse(statusCode: 404, json: [:])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        let completionHandler: ((JsonDictionary?, Swift.Error?) -> Void)? = nil
        let request = CustomEndpoint.execute("echo", params: params, completionHandler: completionHandler)
        XCTAssertTrue(wait(toBeTrue: !request.executing))
        expectationCustomEndpoint?.fulfill()
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func test404ErrorNoCompletionBlockNilParam() {
        signUp()
        
        if useMockData {
            mockResponse(statusCode: 404, json: [:])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        let params: JsonDictionary? = nil
        let completionHandler: ((JsonDictionary?, Swift.Error?) -> Void)? = nil
        let request = CustomEndpoint.execute("echo", params: params, completionHandler: completionHandler)
        XCTAssertTrue(wait(toBeTrue: !request.executing))
        expectationCustomEndpoint?.fulfill()
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func test404TError() {
        signUp()
        
        let params = [String : Any]()
        
        if useMockData {
            mockResponse(statusCode: 404, json: [:])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        struct EchoType: Mappable {
            
            var age: Int?
            
            public init?(map: Map) {
            }
            
            public mutating func mapping(map: Map) {
                age <- map["ageParam"]
            }
            
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: CustomEndpoint.Params(params)) { (response: EchoType?, error) in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func test404TErrorJsonReturn() {
        signUp()
        
        let params = [String : Any]()
        
        if useMockData {
            mockResponse(statusCode: 404, json: [:])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        struct EchoType: Mappable {
            
            var age: Int?
            
            public init?(map: Map) {
            }
            
            public mutating func mapping(map: Map) {
                age <- map["ageParam"]
            }
            
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: CustomEndpoint.Params(params)) { (response: JsonDictionary?, error) in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func test404TErrorJsonArrayReturn() {
        signUp()
        
        let params = [String : Any]()
        
        if useMockData {
            mockResponse(statusCode: 404, json: [:])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        struct EchoType: Mappable {
            
            var age: Int?
            
            public init?(map: Map) {
            }
            
            public mutating func mapping(map: Map) {
                age <- map["ageParam"]
            }
            
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: CustomEndpoint.Params(params)) { (response: [JsonDictionary]?, error) in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func test404TStaticMappableError() {
        signUp()
        
        let params = [String : Any]()
        
        if useMockData {
            mockResponse(statusCode: 404, json: [:])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        struct EchoType: StaticMappable {
            
            var age: Int?
            
            public static func objectForMapping(map: Map) -> BaseMappable? {
                return EchoType()
            }
            
            public mutating func mapping(map: Map) {
                age <- map["ageParam"]
            }
            
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: CustomEndpoint.Params(params)) { (response: EchoType?, error) in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func test404TArrayError() {
        signUp()
        
        let params = [String : Any]()
        
        if useMockData {
            mockResponse(statusCode: 404, json: [:])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        struct EchoType: Mappable {
            
            var age: Int?
            
            public init?(map: Map) {
            }
            
            public mutating func mapping(map: Map) {
                age <- map["ageParam"]
            }
            
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: CustomEndpoint.Params(params)) { (response: [EchoType]?, error) in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func test404TStaticMappableArrayError() {
        signUp()
        
        let params = [String : Any]()
        
        if useMockData {
            mockResponse(statusCode: 404, json: [:])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        struct EchoType: StaticMappable {
            
            var age: Int?
            
            public static func objectForMapping(map: Map) -> BaseMappable? {
                return EchoType()
            }
            
            public mutating func mapping(map: Map) {
                age <- map["ageParam"]
            }
            
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: CustomEndpoint.Params(params)) { (response: [EchoType]?, error) in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func testNestedDictionary() {
        signUp()
        
        let params = [
            "query" : [
                "query" : Query(format: "colors.@count == %@", 2)
            ]
        ]
        
        if useMockData {
            mockResponse(json: [
                "query" : [
                    "query" : [
                        "colors" : [
                            "$size" : 2
                        ]
                    ]
                ]
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: params) { (response: JsonDictionary?, error) in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            
            if let response = response {
                XCTAssertEqual(response.count, 1)
                
                XCTAssertNotNil(response["query"] as? JsonDictionary)
                if let query = response["query"] as? JsonDictionary {
                    XCTAssertNotNil(query["query"] as? JsonDictionary)
                    if let query = query["query"] as? JsonDictionary {
                        XCTAssertNotNil(query["colors"] as? JsonDictionary)
                        if let colors = query["colors"] as? JsonDictionary {
                            XCTAssertNotNil(colors["$size"] as? Int)
                            if let size = colors["$size"] as? Int {
                                XCTAssertEqual(size, 2)
                            }
                        }
                    }
                }
            }
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func testNestedArray() {
        signUp()
        
        let params = [
            "queries" : [
                Query(format: "colors.@count == %@", 2),
                Query(format: "colors.@count == %@", 5)
            ]
        ]
        
        if useMockData {
            mockResponse(json: [
                "queries" : [
                    [
                        "colors" : [
                            "$size" : 2
                        ]
                    ],
                    [
                        "colors" : [
                            "$size" : 5
                        ]
                    ]
                ]
            ])
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: params) { (response: JsonDictionary?, error) in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            
            if let response = response {
                XCTAssertEqual(response.count, 1)
                
                XCTAssertNotNil(response["queries"] as? [JsonDictionary])
                if let queries = response["queries"] as? [JsonDictionary] {
                    XCTAssertEqual(queries.count, 2)
                    
                    if queries.count > 1 {
                        XCTAssertNotNil(queries[0]["colors"] as? JsonDictionary)
                        if let colors = queries[0]["colors"] as? JsonDictionary {
                            XCTAssertNotNil(colors["$size"] as? Int)
                            if let size = colors["$size"] as? Int {
                                XCTAssertEqual(size, 2)
                            }
                        }
                        XCTAssertNotNil(queries[1]["colors"] as? JsonDictionary)
                        if let colors = queries[1]["colors"] as? JsonDictionary {
                            XCTAssertNotNil(colors["$size"] as? Int)
                            if let size = colors["$size"] as? Int {
                                XCTAssertEqual(size, 5)
                            }
                        }
                    }
                }
            }
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
}
