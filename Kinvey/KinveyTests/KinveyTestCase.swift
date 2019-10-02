//
//  KinveyTests.swift
//  KinveyTests
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey
import Nimble

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
    
    init(request: URLRequest) {
        self.init(request: request, urlProcotolType: KinveyURLProtocol.self)
    }
    
    init<URLProtocolType>(
        request: URLRequest,
        urlProcotolType: URLProtocolType.Type
    ) where URLProtocolType: URLProtocol {
        let client = KinveyURLProtocolClient()
        let urlProtocol = URLProtocolType(request: request, cachedResponse: nil, client: client)
        urlProtocol.startLoading()
        urlProtocol.stopLoading()
        self.init(response: client.response, data: client.data)
    }
    
    init(response: URLResponse?, data: Data? = nil) {
        let httpURLResponse = response as? HTTPURLResponse
        let headerFields: [String : String]?
        if let allHeaderFields = httpURLResponse?.allHeaderFields {
            headerFields = [String : String](uniqueKeysWithValues: allHeaderFields.map({
                return (($0 as! String), ($1 as! String))
            }))
        } else {
            headerFields = nil
        }
        self.init(statusCode: httpURLResponse?.statusCode, headerFields: headerFields, data: data)
    }
    
}

extension JSONSerialization {
    
    class func jsonObject(with request: URLRequest, options opt: JSONSerialization.ReadingOptions = []) throws -> Any? {
        if let data = request.httpBody {
            return try jsonObject(with: data, options: opt)
        } else if let inputStream = request.httpBodyStream {
            inputStream.open()
            defer {
                inputStream.close()
            }
            return try jsonObject(with: inputStream, options: opt)
        } else {
            return nil
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
        while MockURLProtocol.running {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
    }
}

func kinveyInitialize() {
    guard !Kinvey.sharedClient.isInitialized() else {
        return
    }
    let appKey = ProcessInfo.processInfo.environment["KINVEY_APP_KEY"]
    let appSecret = ProcessInfo.processInfo.environment["KINVEY_APP_SECRET"]
    Kinvey.sharedClient.initialize(
        appKey: appKey ?? KinveyURLProtocol.appKey,
        appSecret: appSecret ?? KinveyURLProtocol.appSecret
    ) {
        switch $0 {
        case .success:
            break
        case .failure(let error):
            fail(error.localizedDescription)
        }
    }
    expect(Kinvey.sharedClient.isInitialized()).toEventually(beTrue())
}

func kinveyLogin() {
    if Kinvey.sharedClient.activeUser == nil {
        User.signup(options: nil) {
            switch $0 {
            case .success(let user):
                break
            case .failure(let error):
                fail(error.localizedDescription)
            }
        }
    }
    expect(Kinvey.sharedClient.activeUser).toEventuallyNot(beNil())
}

func kinveyLogout() {
    guard let user = Kinvey.sharedClient.activeUser else {
        return
    }
    user.logout {
        switch $0 {
        case .success:
            break
        case .failure(let error):
            fail(error.localizedDescription)
        }
    }
    expect(Kinvey.sharedClient.activeUser).toEventually(beNil())
}

@discardableResult
func kinveySave<T: Entity>(dataStore: DataStore<T>, entities: T...) -> (entities: AnyRandomAccessCollection<T>?, errors: [Swift.Error]?) {
    return kinveySave(dataStore: dataStore, entities: entities)
}

@discardableResult
func kinveySave<T: Entity, S: Sequence>(dataStore: DataStore<T>, entities: S) -> (entities: AnyRandomAccessCollection<T>?, errors: [Swift.Error]?) where S.Element == T {
    var items = [T?]()
    var errors = [Swift.Error?]()
    for entity in entities {
        let result = kinveySave(dataStore: dataStore, entity: entity)
        items.append(result.entity)
        errors.append(result.error)
    }
    return (entities: items.count > 0 ? AnyRandomAccessCollection(items.compactMap({ $0 })) : nil, errors: errors.count > 0 ? errors.compactMap({ $0 }) : nil)
}

@discardableResult
func kinveySaveMulti<T: Entity>(dataStore: DataStore<T>, entities: T...) -> (result: MultiSaveResultTuple<T>?, error: Swift.Error?) {
    return kinveySaveMulti(dataStore: dataStore, entities: entities)
}

@discardableResult
func kinveySaveMulti<T: Entity, S: RandomAccessCollection>(dataStore: DataStore<T>, entities: S) -> (result: MultiSaveResultTuple<T>?, error: Swift.Error?) where S.Element == T {
    var result: MultiSaveResultTuple<T>? = nil
    var error: Swift.Error? = nil
    waitUntil { done in
        dataStore.save(entities) {
            switch $0 {
            case .success(let _result):
                result = _result
            case .failure(let _error):
                error = _error
            }
            done()
        }
    }
    return (result: result, error: error)
}

@discardableResult
func kinveySave<T: Entity>(dataStore: DataStore<T>, numberOfItems: Int) -> (entities: AnyRandomAccessCollection<T>?, errors: [Swift.Error]?) {
    var entities = [T?]()
    var errors = [Swift.Error?]()
    for i in 0 ..< numberOfItems {
        let result = kinveySave(dataStore: dataStore)
        entities.append(result.entity)
        errors.append(result.error)
    }
    return (entities: entities.count > 0 ? AnyRandomAccessCollection(entities.compactMap({ $0 })) : nil, errors: errors.count > 0 ? errors.compactMap({ $0 }) : nil)
}

@discardableResult
func kinveySave<T: Entity>(dataStore: DataStore<T>, entity: T = T()) -> (entity: T?, error: Swift.Error?) {
    var entityPostSave: T? = nil
    var error: Swift.Error? = nil
    waitUntil { done in
        dataStore.save(entity) {
            switch $0 {
            case .success(let _entity):
                entityPostSave = _entity
            case .failure(let _error):
                error = _error
            }
            done()
        }
    }
    return (entity: entityPostSave, error: error)
}

func kinveyFind<T: Entity>(dataStore: DataStore<T>, query: Query = Query(), options: Options? = nil) -> (entities: AnyRandomAccessCollection<T>?, error: Swift.Error?) {
    var entities: AnyRandomAccessCollection<T>? = nil
    var error: Swift.Error? = nil
    waitUntil { done in
        dataStore.find(query, options: options) {
            switch $0 {
            case .success(let _entities):
                entities = _entities
            case .failure(let _error):
                error = _error
            }
            done()
        }
    }
    return (entities: entities, error: error)
}

func kinveyFind<T: Entity>(dataStore: DataStore<T>, id: String, options: Options? = nil) -> (result: T?, error: Swift.Error?) {
    var result: T? = nil
    var error: Swift.Error? = nil
    waitUntil { done in
        dataStore.find(id, options: options) {
            switch $0 {
            case .success(let entity):
                result = entity
            case .failure(let _error):
                error = _error
            }
            done()
        }
    }
    return (result: result, error: error)
}

func kinveyCount<T: Entity>(dataStore: DataStore<T>, query: Query = Query(), options: Options? = nil) -> (count: Int?, error: Swift.Error?) {
    var count: Int? = nil
    var error: Swift.Error? = nil
    waitUntil { done in
        dataStore.count(query, options: options) {
            switch $0 {
            case .success(let _count):
                count = _count
            case .failure(let _error):
                error = _error
            }
            done()
        }
    }
    return (count: count, error: error)
}

func kinveySync<T: Entity>(
    dataStore: DataStore<T>,
    query: Query = Query(),
    deltaSetCompletionHandler: ((AnyRandomAccessCollection<T>, AnyRandomAccessCollection<T>) -> Void)? = nil,
    options: Options? = nil
) -> (result: (count: UInt, entities: AnyRandomAccessCollection<T>)?, errors: [Swift.Error]?) {
    var result: (count: UInt, entities: AnyRandomAccessCollection<T>)? = nil
    var errors: [Swift.Error]? = nil
    waitUntil { done in
        dataStore.sync(
            query,
            deltaSetCompletionHandler: deltaSetCompletionHandler,
            options: options
        ) {
            switch $0 {
            case .success(let count, let entities):
                result = (count: count, entities: entities)
            case .failure(let _errors):
                errors = Array(_errors)
            }
            done()
        }
    }
    return (result: result, errors: errors)
}

@discardableResult
func kinveyPush<T: Entity>(
    dataStore: DataStore<T>,
    options: Options? = nil
) -> (count: UInt?, errors: [Swift.Error]?) {
    var count: UInt? = nil
    var errors: [Swift.Error]? = nil
    waitUntil { done in
        dataStore.push(options: options) {
            switch $0 {
            case .success(let _count):
                count = _count
            case .failure(let _errors):
                errors = Array(_errors)
            }
            done()
        }
    }
    return (count: count, errors: errors)
}

func kinveyPull<T: Entity>(
    dataStore: DataStore<T>,
    query: Query = Query(),
    deltaSetCompletionHandler: ((AnyRandomAccessCollection<T>, AnyRandomAccessCollection<T>) -> Void)? = nil,
    options: Options? = nil
) -> (entities: AnyRandomAccessCollection<T>?, error: Swift.Error?) {
    var entities: AnyRandomAccessCollection<T>? = nil
    var error: Swift.Error? = nil
    waitUntil { done in
        dataStore.pull(
            query,
            deltaSetCompletionHandler: deltaSetCompletionHandler,
            options: options
        ) {
            switch $0 {
            case .success(let _entities):
                entities = _entities
            case .failure(let _error):
                error = _error
            }
            done()
        }
    }
    return (entities: entities, error: error)
}

@discardableResult
func kinveyRemove<T: Entity>(
    dataStore: DataStore<T>,
    query: Query = Query(),
    options: Options? = nil
) -> (count: Int?, error: Swift.Error?) {
    var count: Int? = nil
    var error: Swift.Error? = nil
    waitUntil { done in
        dataStore.remove(
            query,
            options: options
        ) {
            switch $0 {
            case .success(let _count):
                count = _count
            case .failure(let _error):
                error = _error
            }
            done()
        }
    }
    return (count: count, error: error)
}

@discardableResult
func kinveyRemove<T: Entity>(
    dataStore: DataStore<T>,
    entity: T,
    options: Options? = nil
) -> (count: Int?, error: Swift.Error?) {
    var count: Int? = nil
    var error: Swift.Error? = nil
    waitUntil { done in
        do {
            try dataStore.remove(
                entity,
                options: options
            ) {
                switch $0 {
                case .success(let _count):
                    count = _count
                case .failure(let _error):
                    error = _error
                }
                done()
            }
        } catch let _error {
            error = _error
            done()
        }
    }
    return (count: count, error: error)
}

@discardableResult
func kinveyRemove<T: Entity>(
    dataStore: DataStore<T>,
    id: String,
    options: Options? = nil
) -> (count: Int?, error: Swift.Error?) {
    var count: Int? = nil
    var error: Swift.Error? = nil
    waitUntil { done in
        do {
            try dataStore.remove(
                byId: id,
                options: options
            ) {
                switch $0 {
                case .success(let _count):
                    count = _count
                case .failure(let _error):
                    error = _error
                }
                done()
            }
        } catch let _error {
            error = _error
            done()
        }
    }
    return (count: count, error: error)
}

@discardableResult
func kinveySave<T: Entity>(
    dataStore: DataStore<T>,
    entity: T,
    options: Options? = nil
) -> (entity: T?, error: Swift.Error?) {
    var entityPostSave: T? = nil
    var error: Swift.Error? = nil
    waitUntil { done in
        dataStore.save(
            entity,
            options: options
        ) {
            switch $0 {
            case .success(let entity):
                entityPostSave = entity
            case .failure(let _error):
                error = _error
            }
            done()
        }
    }
    return (entity: entityPostSave, error: error)
}

func kinveyDownload<FileType>(
    file: FileType,
    fileStore: FileStore<FileType>,
    storeType: StoreType,
    options: Options? = nil,
    timeout: TimeInterval = AsyncDefaults.Timeout
) -> (success: (file: FileType, url: URL)?, error: Swift.Error?) where FileType: File {
    var _success: (FileType, URL)? = nil
    var _error: Swift.Error? = nil
    waitUntil(timeout: timeout) { done in
        fileStore.download(
            file: file,
            storeType: storeType,
            options: options
        ) {
            switch $0 {
            case .success(let (file, url)):
                _success = (file: file, url: url)
            case .failure(let error):
                _error = error
            }
            done()
        }
    }
    return (success: _success, error: _error)
}

func kinveyUpload<FileType>(
    file: FileType,
    fileStore: FileStore<FileType>,
    data: Data,
    options: Options? = nil,
    timeout: TimeInterval = AsyncDefaults.Timeout
) -> (file: (FileType)?, error: Swift.Error?) where FileType: File {
    var _file: FileType? = nil
    var _error: Swift.Error? = nil
    waitUntil(timeout: timeout) { done in
        fileStore.upload(
            file,
            data: data,
            options: options
        ) {
            switch $0 {
            case .success(let file):
                _file = file
            case .failure(let error):
                _error = error
            }
            done()
        }
    }
    return (file: _file, error: _error)
}

class MockURLProtocol: URLProtocol {
    
    static var completionHandler: ((URLRequest) -> HttpResponse)? = nil
    static var function: String?
    static var runLoop: CFRunLoop?
    static var running = false
    
    override class func canInit(with request: URLRequest) -> Bool {
        while running {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
        var matches = false
        if let url = request.url,
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let host = urlComponents.host
        {
            matches = host.hasSuffix(".kinvey.com") || host.hasSuffix(".googleapis.com")
        }
        log.debug("Mock \(function ?? "") return \(matches) \(request.url!)")
        return matches
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        while running {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
        return request
    }
    
    override class func canInit(with task: URLSessionTask) -> Bool {
        while running {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
        var matches = false
        if let request = task.currentRequest {
            matches = canInit(with: request)
        }
        log.debug("Mock \(function ?? "") return \(matches) \(task.currentRequest!.url!)")
        return matches
    }
    
    override func startLoading() {
        while MockURLProtocol.running {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
        MockURLProtocol.running = true
        log.debug("Mock \(MockURLProtocol.function ?? "") \(request.url!)")
        let responseObj = MockURLProtocol.completionHandler!(self.request)
        if let error = responseObj.error {
            self.client!.urlProtocol(self, didFailWithError: error)
        } else {
            let response = HTTPURLResponse(url: self.request.url!, statusCode: responseObj.statusCode ?? 200, httpVersion: "HTTP/1.1", headerFields: responseObj.headerFields)
            self.client!.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
            if let chunks = responseObj.chunks {
                let currentRunLoop = CFRunLoopGetCurrent()
                for chunk in chunks {
                    self.client!.urlProtocol(self, didLoad: chunk.data)
                    if let delay = chunk.delay {
                        DispatchQueue.main.async { MockURLProtocol.runLoop = currentRunLoop }
                        RunLoop.current.run(until: Date(timeIntervalSinceNow: delay))
                        DispatchQueue.main.async { MockURLProtocol.runLoop = nil }
                    }
                }
            }
        }
        self.client!.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        log.debug("Mock \(MockURLProtocol.function ?? "") \(request.url!)")
        MockURLProtocol.running = false
    }
    
}

func mockResponse(statusCode: Int? = nil, headerFields: [String : String]? = nil, json: JsonDictionary, function: String = #function) {
    var headerFields = headerFields ?? [:]
    headerFields["Content-Type"] = "application/json; charset=utf-8"
    mockResponse(statusCode: statusCode, headerFields: headerFields, data: try! JSONSerialization.data(withJSONObject: json), function: function)
}

func mockResponse(statusCode: Int? = nil, headerFields: [String : String]? = nil, json: [JsonDictionary], function: String = #function) {
    var headerFields = headerFields ?? [:]
    headerFields["Content-Type"] = "application/json; charset=utf-8"
    mockResponse(statusCode: statusCode, headerFields: headerFields, data: try! JSONSerialization.data(withJSONObject: json), function: function)
}

func mockResponse(statusCode: Int? = nil, headerFields: [String : String]? = nil, string: String, function: String = #function) {
    mockResponse(statusCode: statusCode, headerFields: headerFields, data: string.data(using: .utf8), function: function)
}

func mockResponse(statusCode: Int? = nil, headerFields: [String : String]? = nil, data: Data?, function: String = #function) {
    mockResponse(httpResponse: HttpResponse(statusCode: statusCode, headerFields: headerFields, data: data), function: function)
}

func mockResponse(statusCode: Int? = nil, headerFields: [String : String]? = nil, chunks: [ChunkData]?, function: String = #function) {
    mockResponse(httpResponse: HttpResponse(statusCode: statusCode, headerFields: headerFields, chunks: chunks), function: function)
}

func mockResponse(statusCode: Int? = nil, headerFields: [String : String]? = nil, data: [Data]?, function: String = #function) {
    mockResponse(httpResponse: HttpResponse(statusCode: statusCode, headerFields: headerFields, chunks: data?.map { ChunkData(data: $0) }), function: function)
}

func mockResponse(error: Swift.Error, function: String = #function) {
    mockResponse(httpResponse: HttpResponse(error: error), function: function)
}

func mockResponse(httpResponse: HttpResponse, function: String = #function) {
    MockURLProtocol.completionHandler = { _ in
        return httpResponse
    }
    MockURLProtocol.function = function
    setURLProtocol(MockURLProtocol.self)
}

let insufficientCredentialsErrorDescription = "The credentials used to authenticate this request are not authorized to run this operation. Please retry your request with appropriate credentials."

let httpResponseInsufficientCredentialsError = HttpResponse(
    statusCode: 401,
    json: [
        "error" : "InsufficientCredentials",
        "description" : insufficientCredentialsErrorDescription,
        "debug" : ""
    ]
)

func mockResponseInsufficientCredentialsError(function: String = #function) {
    mockResponse(httpResponse: httpResponseInsufficientCredentialsError, function: function)
}

let entityNotFoundErrorDescription = "This entity not found in the collection."

func mockResponse(client: Client = sharedClient, function: String = #function, completionHandler: @escaping (URLRequest) -> HttpResponse) {
    MockURLProtocol.completionHandler = completionHandler
    MockURLProtocol.function = function
    setURLProtocol(MockURLProtocol.self, client: client)
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

func mach_task_self() -> task_t {
    return mach_task_self_
}

// got from https://forums.developer.apple.com/thread/64665
func getMegabytesUsed() -> Float? {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info) / MemoryLayout<integer_t>.size)
    let kerr = withUnsafeMutablePointer(to: &info) { infoPtr in
        return infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { (machPtr: UnsafeMutablePointer<integer_t>) in
            return task_info(
                mach_task_self(),
                task_flavor_t(MACH_TASK_BASIC_INFO),
                machPtr,
                &count
            )
        }
    }
    guard kerr == KERN_SUCCESS else {
        return nil
    }
    return Float(info.resident_size) / (1024 * 1024)
}

class KinveyTestCase: XCTestCase {
    
    let client = Kinvey.sharedClient
    var encrypted = false
    var useMockData = appKey == nil || appSecret == nil
    
    static let defaultTimeout: TimeInterval = {
        guard let timeout = ProcessInfo.processInfo.environment["TIMEOUT"], let timeInterval = TimeInterval(timeout) else {
            return 60
        }
        return timeInterval
    }()
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
            ) {
                switch $0 {
                case .success(let user):
                    if let user = user {
                        print(user)
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    func initializeProduction() {
        if !Kinvey.sharedClient.isInitialized() {
            Kinvey.sharedClient.initialize(
                appKey: KinveyTestCase.appKey ?? KinveyTestCase.appInitializeProduction.appKey,
                appSecret: KinveyTestCase.appSecret ?? KinveyTestCase.appInitializeProduction.appSecret,
                apiHostName: KinveyTestCase.hostUrl ?? Client.defaultApiHostName,
                encrypted: encrypted
            ) {
                switch $0 {
                case .success(let user):
                    if let user = user {
                        print(user)
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
        
    }
    
    private var originalLogLevel: LogLevel!
    private var running = false
    
    override func setUp() {
        if running {
            keyValueObservingExpectation(for: self, keyPath: NSExpression(forKeyPath: \KinveyTestCase.running).keyPath) { (obj, change) -> Bool in
                return !self.running
            }
            
            waitForExpectations(timeout: defaultTimeout)
        }
        XCTAssertFalse(MockURLProtocol.running)
        running = true
        
        super.setUp()
        
        originalLogLevel = Kinvey.logLevel
        Kinvey.logLevel = .error
        
        if KinveyTestCase.appInitialize == KinveyTestCase.appInitializeDevelopment {
            initializeDevelopment()
        } else {
            initializeProduction()
        }
        
        XCTAssertNotNil(client.isInitialized())
        
        if let activeUser = client.activeUser {
            activeUser.logout()
        }
        
        client.userType = User.self
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
    
    func signUp<UserType: User>(username: String? = nil, password: String? = nil, user: UserType? = nil, mustIncludeSocialIdentity: Bool = false, mustHaveAValidUserInTheEnd: Bool = true, client: Client? = nil, completionHandler: ((UserType?, Swift.Error?) -> Void)? = nil) {
        let client = client ?? self.client
        if let user = client.activeUser {
            user.logout()
        }
        
        let originalMustIncludeSocialIdentity = MockKinveyBackend.usersMustIncludeSocialIdentity
        if useMockData {
            MockKinveyBackend.usersMustIncludeSocialIdentity = mustIncludeSocialIdentity
            setURLProtocol(MockKinveyBackend.self)
        }
        defer {
            if useMockData {
                MockKinveyBackend.usersMustIncludeSocialIdentity = originalMustIncludeSocialIdentity
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
        let store = try! DataStore<T>.collection()
        if let cache = store.cache {
            cache.clear(query: nil)
        }
    }
    
    var deleteUserDuringTearDown = true
    
    override func tearDown() {
        defer {
            running = false
        }
        while MockURLProtocol.running {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
        XCTAssertFalse(MockURLProtocol.running)
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
        
        client.userType = User.self
        
        super.tearDown()
    }
    
    func decorate(json: inout JsonDictionary) {
        json[Entity.EntityCodingKeys.entityId] = UUID().uuidString
        json[Entity.EntityCodingKeys.acl] = [
            Acl.Key.creator : self.client.activeUser!.userId
        ]
        json[Entity.EntityCodingKeys.metadata] = [
            Metadata.CodingKeys.lastModifiedTime.rawValue : Date().toISO8601(),
            Metadata.CodingKeys.entityCreationTime.rawValue : Date().toISO8601()
        ]
    }
    
    func decorateJsonFromPostRequest(_ request: URLRequest) -> JsonDictionary {
        XCTAssertEqual(request.httpMethod, "POST")
        var json = try! JSONSerialization.jsonObject(with: request) as! JsonDictionary
        decorate(json: &json)
        return json
    }
    
    func decorateJsonArrayFromPostRequest(_ request: URLRequest) -> [JsonDictionary] {
        XCTAssertEqual(request.httpMethod, "POST")
        var jsonArray = try! JSONSerialization.jsonObject(with: request) as! [JsonDictionary]
        jsonArray = jsonArray.map {
            var json = $0
            decorate(json: &json)
            return json
        }
        return jsonArray
    }
    
    func startLogPolling(timeInterval: TimeInterval = 30, function: String = #function) -> DispatchSourceTimer {
        let startTime = Date()
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now() + timeInterval, repeating: timeInterval)
        timer.setEventHandler {
            autoreleasepool {
                print("Running \(function) for \(Int(round(-startTime.timeIntervalSinceNow)))s")
            }
        }
        timer.resume()
        return timer
    }
    
}
