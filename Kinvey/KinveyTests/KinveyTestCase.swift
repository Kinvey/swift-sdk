//
//  KinveyTests.swift
//  KinveyTests
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

extension XCTestCase {
    
    @discardableResult
    func wait(toBeTrue evaluate: @escaping @autoclosure () -> Bool, timeout: TimeInterval = 60) -> Bool {
        var result = false
        
        let observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, CFRunLoopActivity.beforeWaiting.rawValue, true, 0) { (observer, activity) in
            if evaluate() {
                result = true
                CFRunLoopStop(CFRunLoopGetCurrent())
            }
        }
        
        CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, .defaultMode)
        CFRunLoopRunInMode(.defaultMode, timeout, false)
        CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), observer, .defaultMode)
        
        return result
    }
    
}

struct ChunkData {
    
    let data: Data
    let delay: TimeInterval?
    
    init(data: Data, delay: TimeInterval? = nil) {
        self.data = data
        self.delay = delay
    }
    
}

struct HttpResponse {
    
    let statusCode: Int?
    let headerFields: [String : String]?
    let chunks: [ChunkData]?
    let error: Swift.Error?
    
    init(error: Swift.Error) {
        statusCode = nil
        headerFields = nil
        chunks = nil
        self.error = error
    }
    
    init(statusCode: Int? = nil, headerFields: [String : String]? = nil, chunks: [ChunkData]? = nil) {
        var headerFields = headerFields ?? [:]
        if let chunks = chunks {
            let contentLength = chunks.reduce(0, { $0 + $1.data.count })
            headerFields["Content-Length"] = "\(contentLength)"
        }
        
        self.statusCode = statusCode
        self.headerFields = headerFields
        self.chunks = chunks
        error = nil
    }
    
    init(statusCode: Int? = nil, headerFields: [String : String]? = nil, data: Data? = nil) {
        self.init(statusCode: statusCode, headerFields: headerFields, chunks: data != nil ? [ChunkData(data: data!)] : nil)
    }
    
    init(statusCode: Int? = nil, headerFields: [String : String]? = nil, json: JsonDictionary) {
        var headerFields = headerFields ?? [:]
        headerFields["Content-Type"] = "application/json; charset=utf-8"
        let data = try! JSONSerialization.data(withJSONObject: json)
        self.init(statusCode: statusCode, headerFields: headerFields, data: data)
    }
    
    init(statusCode: Int? = nil, headerFields: [String : String]? = nil, json: [JsonDictionary]) {
        var headerFields = headerFields ?? [:]
        headerFields["Content-Type"] = "application/json; charset=utf-8"
        let data = try! JSONSerialization.data(withJSONObject: json)
        self.init(statusCode: statusCode, headerFields: headerFields, data: data)
    }
    
}

extension JSONSerialization {
    
    class func jsonObject(with request: URLRequest, options opt: JSONSerialization.ReadingOptions = []) throws -> Any {
        if let data = request.httpBody {
            return try jsonObject(with: data, options: opt)
        } else if let inputStream = request.httpBodyStream {
            inputStream.open()
            defer {
                inputStream.close()
            }
            return try jsonObject(with: inputStream, options: opt)
        } else {
            Swift.fatalError()
        }
    }
    
}

extension URLRequest {
    
    var httpBodyData: Data {
        if let data = httpBody {
            return data
        } else if let inputStream = httpBodyStream {
            inputStream.open()
            defer {
                inputStream.close()
            }
            let bufferSize = 4096
            var data = Data(capacity: bufferSize)
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            var read = 0
            repeat {
                read = inputStream.read(&buffer, maxLength: buffer.count)
                data.append(buffer, count: read)
            } while read > 0
            return data
        } else {
            Swift.fatalError()
        }
    }
    
    var httpBodyString: String {
        return String(data: httpBodyData, encoding: .utf8)!
    }
    
}

var protocolClasses = [URLProtocol.Type]() {
    willSet {
        for protocolClass in protocolClasses {
            URLProtocol.unregisterClass(protocolClass)
        }
    }
    didSet {
        for protocolClass in protocolClasses {
            URLProtocol.registerClass(protocolClass)
        }
    }
}

extension XCTestCase {
    
    func setURLProtocol(_ type: URLProtocol.Type?, client: Client = Kinvey.sharedClient) {
        if let type = type {
            let sessionConfiguration = URLSessionConfiguration.default
            protocolClasses = [type]
            sessionConfiguration.protocolClasses = protocolClasses
            client.urlSession = URLSession(configuration: sessionConfiguration, delegate: client.urlSession.delegate, delegateQueue: client.urlSession.delegateQueue)
            XCTAssertEqual(client.urlSession.configuration.protocolClasses!.count, 1)
        } else {
            protocolClasses = []
            client.urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: client.urlSession.delegate, delegateQueue: client.urlSession.delegateQueue)
        }
    }
    
    class MockURLProtocol: URLProtocol {
        
        static var completionHandler: ((URLRequest) -> HttpResponse)? = nil
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override class func canInit(with task: URLSessionTask) -> Bool {
            return true
        }
        
        override func startLoading() {
            let responseObj = MockURLProtocol.completionHandler!(self.request)
            if let error = responseObj.error {
                self.client!.urlProtocol(self, didFailWithError: error)
            } else {
                let response = HTTPURLResponse(url: self.request.url!, statusCode: responseObj.statusCode ?? 200, httpVersion: "HTTP/1.1", headerFields: responseObj.headerFields)
                self.client!.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
                if let chunks = responseObj.chunks {
                    for chunk in chunks {
                        self.client!.urlProtocol(self, didLoad: chunk.data)
                        if let delay = chunk.delay {                        
                            RunLoop.current.run(until: Date(timeIntervalSinceNow: delay))
                        }
                    }
                }
                self.client!.urlProtocolDidFinishLoading(self)
            }
        }
        
        override func stopLoading() {
        }
        
    }
    
    func mockResponse(statusCode: Int? = nil, headerFields: [String : String]? = nil, json: JsonDictionary) {
        var headerFields = headerFields ?? [:]
        headerFields["Content-Type"] = "application/json; charset=utf-8"
        mockResponse(statusCode: statusCode, headerFields: headerFields, data: try! JSONSerialization.data(withJSONObject: json))
    }
    
    func mockResponse(statusCode: Int? = nil, headerFields: [String : String]? = nil, json: [JsonDictionary]) {
        var headerFields = headerFields ?? [:]
        headerFields["Content-Type"] = "application/json; charset=utf-8"
        mockResponse(statusCode: statusCode, headerFields: headerFields, data: try! JSONSerialization.data(withJSONObject: json))
    }
    
    func mockResponse(statusCode: Int? = nil, headerFields: [String : String]? = nil, data: Data?) {
        MockURLProtocol.completionHandler = { _ in
            return HttpResponse(statusCode: statusCode, headerFields: headerFields, data: data)
        }
        setURLProtocol(MockURLProtocol.self)
    }
    
    func mockResponse(statusCode: Int? = nil, headerFields: [String : String]? = nil, chunks: [ChunkData]?) {
        MockURLProtocol.completionHandler = { _ in
            return HttpResponse(statusCode: statusCode, headerFields: headerFields, chunks: chunks)
        }
        setURLProtocol(MockURLProtocol.self)
    }
    
    func mockResponse(statusCode: Int? = nil, headerFields: [String : String]? = nil, data: [Data]?) {
        MockURLProtocol.completionHandler = { _ in
            return HttpResponse(statusCode: statusCode, headerFields: headerFields, chunks: data?.map { ChunkData(data: $0) })
        }
        setURLProtocol(MockURLProtocol.self)
    }
    
    func mockResponse(error: Swift.Error) {
        MockURLProtocol.completionHandler = { _ in
            return HttpResponse(error: error)
        }
        setURLProtocol(MockURLProtocol.self)
    }
    
    func mockResponse(client: Client = sharedClient, completionHandler: @escaping (URLRequest) -> HttpResponse) {
        MockURLProtocol.completionHandler = completionHandler
        setURLProtocol(MockURLProtocol.self, client: client)
    }
    
}

@inline(__always)
func XCTAssertMainThread() {
    XCTAssertTrue(Thread.isMainThread)
}

@inline(__always)
func XCTAssertTimeoutError(_ error: Swift.Error?) {
    XCTAssertNotNil(error)
    if let error = error {
        let error = error as NSError
        XCTAssertEqual(error.domain, NSURLErrorDomain)
        XCTAssertEqual(error.code, NSURLErrorTimedOut)
    }
}

class KinveyTestCase: XCTestCase {
    
    let client = Kinvey.sharedClient
    var encrypted = false
    var useMockData = appKey == nil || appSecret == nil
    
    static let defaultTimeout: TimeInterval = 30
    let defaultTimeout: TimeInterval = KinveyTestCase.defaultTimeout
    
    static let appKey = ProcessInfo.processInfo.environment["KINVEY_APP_KEY"]
    static let appSecret = ProcessInfo.processInfo.environment["KINVEY_APP_SECRET"]
    static let hostUrl: URL? = {
        guard let hostUrl = ProcessInfo.processInfo.environment["KINVEY_HOST_URL"] else {
            return nil
        }
        return URL(string: hostUrl)
    }()
    
    typealias AppInitialize = (appKey: String, appSecret: String)
    static let appInitializeDevelopment = AppInitialize(appKey: "kid_Wy35WH6X9e", appSecret: "d85f81cad5a649baaa6fdcd99a108ab1")
    static let appInitializeProduction = AppInitialize(appKey: MockKinveyBackend.kid, appSecret: "appSecret")
    static let appInitialize = appInitializeProduction
    
    func initializeDevelopment() {
        if !Kinvey.sharedClient.isInitialized() {
            Kinvey.sharedClient.initialize(
                appKey: KinveyTestCase.appInitializeDevelopment.appKey,
                appSecret: KinveyTestCase.appInitializeDevelopment.appSecret,
                apiHostName: URL(string: "https://v3yk1n-kcs.kinvey.com")!,
                encrypted: encrypted
            )
        }
    }
    
    func initializeProduction() {
        if !Kinvey.sharedClient.isInitialized() {
            Kinvey.sharedClient.initialize(
                appKey: KinveyTestCase.appKey ?? KinveyTestCase.appInitializeProduction.appKey,
                appSecret: KinveyTestCase.appSecret ?? KinveyTestCase.appInitializeProduction.appSecret,
                apiHostName: KinveyTestCase.hostUrl ?? Client.defaultApiHostName,
                encrypted: encrypted
            )
        }
        
    }
    
    private var originalLogLevel: LogLevel!
    
    override func setUp() {
        super.setUp()
        
        originalLogLevel = Kinvey.logLevel
        Kinvey.logLevel = .verbose
        
        if KinveyTestCase.appInitialize == KinveyTestCase.appInitializeDevelopment {
            initializeDevelopment()
        } else {
            initializeProduction()
        }
        
        XCTAssertNotNil(client.isInitialized())
        
        if let activeUser = client.activeUser {
            activeUser.logout()
        }
    }
    
    class SignUpMockURLProtocol: URLProtocol {
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: [ "Content-Type" : "application/json; charset=utf-8" ])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            var resquestBody: [String : Any]? = nil
            if let data = request.httpBody {
                resquestBody = try! JSONSerialization.jsonObject(with: data) as? [String : Any]
            } else if let httpBodyStream = request.httpBodyStream {
                httpBodyStream.open()
                defer {
                    httpBodyStream.close()
                }
                resquestBody = try! JSONSerialization.jsonObject(with: httpBodyStream) as? [String : Any]
            }
            
            var responseBody = [
                "_id" : UUID().uuidString,
                "username" : (resquestBody?["username"] as? String) ?? UUID().uuidString,
                "_kmd" : [
                    "lmt" : "2016-10-19T21:06:17.367Z",
                    "ect" : "2016-10-19T21:06:17.367Z",
                    "authtoken" : "my-auth-token"
                ],
                "_acl" : [
                    "creator" : "masterKey-creator-id"
                ]
            ] as [String : Any]
            if let resquestBody = resquestBody {
                responseBody += resquestBody
            }
            let data = try! JSONSerialization.data(withJSONObject: responseBody)
            client?.urlProtocol(self, didLoad: data)
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {
        }
        
    }
    
    func signUp<UserType: User>(username: String? = nil, password: String? = nil, user: UserType? = nil, mustHaveAValidUserInTheEnd: Bool = true, client: Client? = nil, completionHandler: ((UserType?, Swift.Error?) -> Void)? = nil) {
        let client = client ?? self.client
        if let user = client.activeUser {
            user.logout()
        }
        
        if useMockData {
            setURLProtocol(MockKinveyBackend.self)
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationSignUp = expectation(description: "Sign Up")
        
        let handler: (UserType?, Swift.Error?) -> Void = { user, error in
            if let completionHandler = completionHandler {
                completionHandler(user, error)
            } else {
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                XCTAssertNotNil(user)
            }
            
            expectationSignUp?.fulfill()
        }
        
        if let username = username {
            User.signup(username: username, password: password, user: user, completionHandler: handler)
        } else {
            User.signup(user: user, completionHandler: handler)
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSignUp = nil
        }
        
        if mustHaveAValidUserInTheEnd {
            XCTAssertNotNil(client.activeUser)
        }
    }
    
    func login<UserType: User>(username: String, password: String, mustHaveAValidUserInTheEnd: Bool = true, client: Client? = nil, mockHandler: ((URLRequest) -> HttpResponse)? = nil, completionHandler: ((UserType?, Swift.Error?) -> Void)? = nil) {
        let client = client ?? self.client
        if let user = client.activeUser {
            user.logout()
        }
        
        if useMockData {
            if let mockHandler = mockHandler {
                mockResponse(completionHandler: mockHandler)
            } else {
                setURLProtocol(MockKinveyBackend.self)
            }
        }
        defer {
            if useMockData {
                setURLProtocol(nil)
            }
        }
        
        weak var expectationLogin = expectation(description: "Login")
        
        let handler: (UserType?, Swift.Error?) -> Void = { user, error in
            if let completionHandler = completionHandler {
                completionHandler(user, error)
            } else {
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(error)
                XCTAssertNotNil(user)
            }
            
            expectationLogin?.fulfill()
        }
        
        User.login(username: username, password: password, client: client, completionHandler: handler)
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationLogin = nil
        }
        
        if mustHaveAValidUserInTheEnd {
            XCTAssertNotNil(client.activeUser)
        }
    }

    private func removeAll<T: Persistable>(_ type: T.Type) where T: NSObject {
        let store = DataStore<T>.collection()
        if let cache = store.cache {
            cache.clear(query: nil)
        }
    }
    
    var deleteUserDuringTearDown = true
    
    override func tearDown() {
        setURLProtocol(nil)
        
        if deleteUserDuringTearDown, let user = client.activeUser {
            if useMockData {
                setURLProtocol(MockKinveyBackend.self)
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectationDestroyUser = expectation(description: "Destroy User")
            
            user.destroy {
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
        
        client.cacheManager.clearAll()
        removeAll(Person.self)
        
        Kinvey.logLevel = originalLogLevel
        
        super.tearDown()
    }
    
    func decorateJsonFromPostRequest(_ request: URLRequest) -> JsonDictionary {
        XCTAssertEqual(request.httpMethod, "POST")
        var json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
        json[PersistableIdKey] = UUID().uuidString
        json[PersistableAclKey] = [
            Acl.Key.creator : self.client.activeUser!.userId
        ]
        json[PersistableMetadataKey] = [
            Metadata.LmtKey : Date().toString(),
            Metadata.EctKey : Date().toString()
        ]
        return json
    }
    
}
