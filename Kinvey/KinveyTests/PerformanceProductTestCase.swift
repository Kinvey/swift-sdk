//
//  PerformanceProductTestCase.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-02-28.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
import RealmSwift
import Kinvey
import PromiseKit
import ObjectMapper

class Product: Entity {
    
    let materialNumber = RealmOptional<Int>()
    
    @objc
    dynamic var productDescription: String?
    
    @objc
    dynamic var vertical: String?
    
    @objc
    dynamic var subVertical: String?
    
    @objc
    dynamic var classification: String?
    
    @objc
    dynamic var materialGroup: String?
    
    let materialFreightGroup = RealmOptional<Int>()
    
    @objc
    dynamic var materialType: String?
    
    @objc
    dynamic var baseUOM: String?
    let packageQuantity = RealmOptional<Int>()
    
    @objc
    dynamic var gsaFlag: String?
    
    @objc
    dynamic var discontinuedIndicator: String?
    
    @objc
    dynamic var deactivateDate: String?
    
    @objc
    dynamic var taaFlag: String?
    
    let minOrderQuantity = RealmOptional<Int>()
    let active = RealmOptional<Bool>()
    
    @objc
    dynamic var created: String?
    
    @objc
    dynamic var modified: String?
    
    override static func collectionName() -> String {
        return "Product"
    }
    
    override func propertyMapping(_ map: ObjectMapper.Map) {
        super.propertyMapping(map)
        
        materialNumber <- ("materialNumber", map["MaterialNumber"])
        productDescription <- ("productDescription", map["Description"])
        vertical <- ("vertical", map["Vertical"])
        subVertical <- ("subVertical", map["SubVertical"])
        classification <- ("classification", map["Classification"])
        materialGroup <- ("materialGroup", map["MaterialGroup"])
        materialFreightGroup <- ("materialFreightGroup", map["MaterialFreightGroup"])
        materialType <- ("materialType", map["MaterialType"])
        baseUOM <- ("baseUOM", map["BaseUOM"])
        packageQuantity <- ("packageQuantity", map["PackageQuantity"])
        gsaFlag <- ("gsaFlag", map["GSAFlag"])
        discontinuedIndicator <- ("discontinuedIndicator", map["DiscontinuedIndicator"])
        deactivateDate <- ("deactivateDate", map["DeactivateDate"])
        taaFlag <- ("taaFlag", map["TAAFlag"])
        minOrderQuantity <- ("minOrderQuantity", map["MinOrderQuantity"])
        active <- ("active", map["Active"])
        created <- ("created", map["Created"])
        modified <- ("modified", map["Modified"])
    }
    
}

class PerformanceProductTestCase: KinveyTestCase {
    
    var productsJsonArray: [JsonDictionary]?
    
    lazy var fileStore = FileStore()
    
    lazy var productsJsonFile: File? = {
        var productsJsonFile: File?
        
        weak var expectationFind = self.expectation(description: "Find")
        
        let query = Query(format: "_filename == %@", "products.json")
        self.fileStore.find(query) { (files, error) in
            XCTAssertNotNil(files)
            XCTAssertNotNil(files?.first)
            XCTAssertNil(error)
            
            productsJsonFile = files?.first
            
            expectationFind?.fulfill()
        }
        
        self.waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationFind = nil
        }
        
        return productsJsonFile
    }()
    
    override func setUp() {
        super.setUp()
        
        signUp()
    }
    
    func downloadJson(_ productsJsonFile: File) -> URL? {
        var localURL: URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        localURL!.appendPathComponent(client.appKey!)
        localURL!.appendPathComponent("files")
        localURL!.appendPathComponent(productsJsonFile.fileId!)
        guard !FileManager.default.fileExists(atPath: localURL!.path) else {
            return localURL
        }
        
        weak var expectationDownload = expectation(description: "Download")
        
        let request = fileStore.download(productsJsonFile) { (file, url: URL?, error) in
            XCTAssertNotNil(file)
            XCTAssertNotNil(url)
            XCTAssertNil(error)
            
            localURL = url
            
            expectationDownload?.fulfill()
        }
        
        keyValueObservingExpectation(for: request.progress, keyPath: #selector(getter: request.progress.fractionCompleted).description) { (object, info) -> Bool in
            XCTAssertLessThanOrEqual(request.progress.completedUnitCount, request.progress.totalUnitCount)
            XCTAssertGreaterThanOrEqual(request.progress.fractionCompleted, 0.0)
            XCTAssertLessThanOrEqual(request.progress.fractionCompleted, 1.0)
            let percentage = request.progress.fractionCompleted * 100.0
            print("\(request.progress.completedUnitCount) / \(request.progress.totalUnitCount) \(String(format:"%3.2f", percentage))%")
            return request.progress.fractionCompleted >= 1.0
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationDownload = nil
        }
        
        return localURL
    }
    
    lazy var count: Int? = {
        var count: Int?
        
        let store = try! DataStore<Product>.collection(.network)
        
        weak var expectationCount = self.expectation(description: "Count")
        
        store.count {
            switch $0 {
            case .success(let _count):
                count = _count
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationCount?.fulfill()
        }
        
        self.waitForExpectations(timeout: self.defaultTimeout) { (error) in
            expectationCount = nil
        }
        
        return count
    }()
    
    func loadMockData() {
        guard productsJsonArray == nil else {
            return
        }
        
        XCTAssertNotNil(productsJsonFile)
        
        let productsJsonLocalURL = downloadJson(productsJsonFile!)
        
        XCTAssertNotNil(productsJsonLocalURL)
        
        if let productsJsonLocalURL = productsJsonLocalURL, let inputStream = InputStream(url: productsJsonLocalURL) {
            inputStream.open()
            defer {
                inputStream.close()
            }
            
            let checkpoint = Date()
            let object = try! JSONSerialization.jsonObject(with: inputStream)
            productsJsonArray = object as? [JsonDictionary]
            XCTAssertNotNil(productsJsonArray)
            print(String(format: "JSON Parse: %3.3f second(s)", -checkpoint.timeIntervalSinceNow))
        }
        
        XCTAssertNotNil(productsJsonArray)
        
        XCTAssertNotNil(productsJsonArray?.first)
        if let productJson = productsJsonArray?.first, let product = Product(JSON: productJson) {
            XCTAssertEqual(product.entityId, "58a36d82cbb5aa4c3f9c3b27")
            XCTAssertEqual(product.materialNumber.value, 1000054)
            XCTAssertEqual(product.productDescription, "14\" X 7\" Bustr Scraper, Poly D")
            XCTAssertEqual(product.vertical, "HT000")
            XCTAssertEqual(product.subVertical, "HT900")
            XCTAssertEqual(product.classification, "HT900040")
            XCTAssertEqual(product.materialGroup, "HT")
            XCTAssertEqual(product.materialFreightGroup.value, 1)
            XCTAssertEqual(product.materialType, "YBUK")
            XCTAssertEqual(product.baseUOM, "EA")
            XCTAssertEqual(product.packageQuantity.value, 1)
            XCTAssertEqual(product.gsaFlag, "N")
            XCTAssertEqual(product.discontinuedIndicator, "Y")
            XCTAssertEqual(product.deactivateDate, "2014-02-21")
            XCTAssertEqual(product.taaFlag, "N")
            XCTAssertEqual(product.minOrderQuantity.value, 1)
            XCTAssertEqual(product.active.value, true)
            XCTAssertEqual(product.created, "2016-10-27 20:47:07")
            XCTAssertEqual(product.modified, "2016-10-27 20:47:09")
            XCTAssertEqual(product.acl?.creator, "kid_SyKhgJWKg")
            XCTAssertEqual(KinveyDateTransform().transformToJSON(product.metadata?.lastModifiedTime), "2017-02-14T20:50:10.583Z")
            XCTAssertEqual(KinveyDateTransform().transformToJSON(product.metadata?.entityCreationTime), "2017-02-14T20:50:10.583Z")
        }
    }
    
    func testPerformanceIgnoringNetworkLatency() {
        loadMockData()
        
        mockResponse { (request) -> HttpResponse in
            switch request.url!.path {
            case "/appdata/\(self.client.appKey!)/Product/_count":
                return HttpResponse(json: ["count" : self.productsJsonArray!.count])
            case "/appdata/\(self.client.appKey!)/Product":
                let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                let skip = urlComponents.queryItems!.filter { $0.name == "skip" }.map { Int($0.value!)! }.first!
                let limit = urlComponents.queryItems!.filter { $0.name == "limit" }.map { Int($0.value!)! }.first!
                let productsJsonArrayFiltered = [JsonDictionary](self.productsJsonArray![skip ..< skip + limit])
                return HttpResponse(json: productsJsonArrayFiltered)
            default:
                fatalError()
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        XCTAssertNotNil(count)
        
        let store = try! DataStore<Product>.collection(.network)
        
        self.measure {
            let query = Query()
            query.skip = 0
            query.limit = 10000
            while query.skip! + query.limit! < self.count! {
                weak var expectationFind = self.expectation(description: "Find")
                
                store.find(query) {
                    switch $0 {
                    case .success(let products):
                        break
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationFind?.fulfill()
                }
                
                self.waitForExpectations(timeout: self.defaultTimeout) { (error) in
                    expectationFind = nil
                }
                
                query.skip! += query.limit!
            }
        }
    }
    
    func testPerformanceSave() {
        var promises = [Promise<Void>]()
        
        let batchSize = 100
        let skip = 249600
        let count = self.productsJsonArray!.count
        var checkpoint = Date()
        
        let store = try! DataStore<Product>.collection(.network)
        
        for productJson in self.productsJsonArray![skip ..< count] {
            if let product = Product(JSON: productJson) {
                let promise = Promise<Void> { resolver in
                    store.save(product) {
                        switch $0 {
                        case .success(let product):
                            break
                        case .failure(let error):
                            XCTFail(error.localizedDescription)
                        }
                        
                        resolver.fulfill(())
                    }
                }
                promises.append(promise)
            }
            
            if promises.count >= batchSize {
                weak var expectationSave = self.expectation(description: "Save")
                
                when(fulfilled: promises).done {
                    expectationSave?.fulfill()
                }.catch { error in
                    expectationSave?.fulfill()
                }
                
                self.waitForExpectations(timeout: self.defaultTimeout) { (error) in
                    expectationSave = nil
                }
                
                print(String(format: "%3.3f second(s)", Double(-checkpoint.timeIntervalSinceNow) / Double(batchSize)))
                
                promises.removeAll()
                
                checkpoint = Date()
            }
        }
    }
    
    func testPerformanceConsideringNetworkLatency() {
        XCTAssertNotNil(count)
        
        let store = try! DataStore<Product>.collection(.network)
        
        self.measure {
            let query = Query()
            query.skip = 0
            query.limit = 10000
            while query.skip! + query.limit! < self.count! {
                weak var expectationFind = self.expectation(description: "Find")
                
                store.find(query) {
                    switch $0 {
                    case .success(let products):
                        break
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationFind?.fulfill()
                }
                
                self.waitForExpectations(timeout: self.defaultTimeout) { (error) in
                    expectationFind = nil
                }
                
                query.skip! += query.limit!
            }
        }
    }
    
    func testPerformance_ConsideringNetworkLatency_10K() {
        let query = Query()
        query.skip = 0
        query.limit = 10000
        
        let store = try! DataStore<Product>.collection(.network)
        
        self.measure {
            weak var expectationFind = self.expectation(description: "Find")
            
            store.find(query) {
                switch $0 {
                case .success(let products):
                    XCTAssertGreaterThan(products.count, 0)
                    XCTAssertLessThanOrEqual(products.count, query.limit!)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            self.waitForExpectations(timeout: 120) { (error) in
                expectationFind = nil
            }
            
            query.skip! += query.limit!
        }
    }
    
    func testPerformance_CacheStore_ConsideringNetworkLatency_10K() {
        let query = Query()
        query.skip = 0
        query.limit = 10000
        
        let store = try! DataStore<Product>.collection(.cache)
        
        self.measure {
            weak var expectationFindLocal = self.expectation(description: "Find Local")
            weak var expectationFindNetwork = self.expectation(description: "Find Network")
            
            store.find(query) {
                switch $0 {
                case .success(let products):
                    if expectationFindLocal == nil {
                        XCTAssertGreaterThan(products.count, 0)
                    }
                    XCTAssertLessThanOrEqual(products.count, query.limit!)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                if expectationFindLocal != nil {
                    expectationFindLocal?.fulfill()
                    expectationFindLocal = nil
                } else {
                    expectationFindNetwork?.fulfill()
                }
            }
            
            self.waitForExpectations(timeout: 120) { (error) in
                expectationFindLocal = nil
                expectationFindNetwork = nil
            }
            
            query.skip! += query.limit!
        }
    }
    
    func testPerformance_SyncStore_ConsideringNetworkLatency_10K() {
        let query = Query()
        query.skip = 0
        query.limit = 10000
        
        let store = try! DataStore<Product>.collection(.sync)
        
        for _ in 1 ... 10 {
            weak var expectationFindLocal = self.expectation(description: "Find Local")
            weak var expectationFindNetwork = self.expectation(description: "Find Network")
            
            store.find(query, options: try! Options(readPolicy: .both)) {
                switch $0 {
                case .success(let products):
                    if expectationFindLocal == nil {
                        XCTAssertGreaterThan(products.count, 0)
                    }
                    XCTAssertLessThanOrEqual(products.count, query.limit!)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                if expectationFindLocal != nil {
                    expectationFindLocal?.fulfill()
                    expectationFindLocal = nil
                } else {
                    expectationFindNetwork?.fulfill()
                }
            }
            
            self.waitForExpectations(timeout: 120) { (error) in
                expectationFindLocal = nil
                expectationFindNetwork = nil
            }
            
            query.skip! += query.limit!
        }
        
        query.skip = 0
        query.limit = 10000
        
        self.measure {
            weak var expectationFind = self.expectation(description: "Find")
            
            store.find(query) {
                switch $0 {
                case .success(let products):
                    XCTAssertGreaterThan(products.count, 0)
                    XCTAssertLessThanOrEqual(products.count, query.limit!)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            self.waitForExpectations(timeout: 120) { (error) in
                expectationFind = nil
            }
            
            query.skip! += query.limit!
        }
    }
    
    func testPerformanceConsideringNetworkLatencyDeltaSet10K() {
        let query = Query()
        query.skip = 0
        query.limit = 10000
        
        let store = try! DataStore<Product>.collection(.network)
        
        self.measure {
            weak var expectationFind = self.expectation(description: "Find")
            
            store.find(query, options: try! Options(deltaSet: true)) {
                switch $0 {
                case .success(let products):
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            self.waitForExpectations(timeout: self.defaultTimeout) { (error) in
                expectationFind = nil
            }
            
            query.skip! += query.limit!
        }
    }
    
    func testPerformanceIgnoringNetworkLatency10K() {
        loadMockData()
        
        mockResponse { (request) -> HttpResponse in
            switch request.url!.path {
            case "/appdata/\(self.client.appKey!)/Product/_count":
                return HttpResponse(json: ["count" : self.productsJsonArray!.count])
            case "/appdata/\(self.client.appKey!)/Product":
                let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                let skip = urlComponents.queryItems!.filter { $0.name == "skip" }.map { Int($0.value!)! }.first!
                let limit = urlComponents.queryItems!.filter { $0.name == "limit" }.map { Int($0.value!)! }.first!
                let productsJsonArrayFiltered = [JsonDictionary](self.productsJsonArray![skip ..< skip + limit])
                return HttpResponse(json: productsJsonArrayFiltered)
            default:
                fatalError()
            }
        }
        defer {
            setURLProtocol(nil)
        }
        
        XCTAssertNotNil(count)
        
        let query = Query()
        query.skip = 0
        query.limit = 10000
        
        let store = try! DataStore<Product>.collection(.network)
        
        self.measure {
            weak var expectationFind = self.expectation(description: "Find")
            
            store.find(query) {
                switch $0 {
                case .success(let products):
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationFind?.fulfill()
            }
            
            self.waitForExpectations(timeout: self.defaultTimeout) { (error) in
                expectationFind = nil
            }
            
            query.skip! += query.limit!
        }
    }
    
    func testPerformancePush_100() {
        XCTAssertNotNil(client.activeUser)
        
        loadMockData()
        
        let store = try! DataStore<Product>.collection(.sync)
        
        var skip = 0
        let limit = 100
        
        measure {
            for productJson in self.productsJsonArray![skip ..< skip + limit] {
                let product = Product(JSON: productJson)!
                
                weak var expectationSave = self.expectation(description: "Save")
                
                store.save(product) {
                    switch $0 {
                    case .success(let product):
                        break
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationSave?.fulfill()
                }
                
                self.waitForExpectations(timeout: self.defaultTimeout) { (error) in
                    expectationSave = nil
                }
            }
            
            skip += limit
            
            weak var expectationPush = self.expectation(description: "Push")
            
            store.push { (count, errors) in
                XCTAssertNotNil(count)
                XCTAssertNil(errors)
                
                if let count = count {
                    XCTAssertGreaterThan(count, UInt(0))
                }
                
                expectationPush?.fulfill()
            }
            
            self.waitForExpectations(timeout: 60 * 5) { (error) in
                expectationPush = nil
            }
        }
    }
    
    func testPerformancePush_1000() {
        XCTAssertNotNil(client.activeUser)
        
        loadMockData()
        
        let store = try! DataStore<Product>.collection(.sync)
        
        var skip = 0
        let limit = 1000
        
        measure {
            for productJson in self.productsJsonArray![skip ..< skip + limit] {
                let product = Product(JSON: productJson)!
                
                weak var expectationSave = self.expectation(description: "Save")
                
                store.save(product) {
                    switch $0 {
                    case .success(let product):
                        break
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationSave?.fulfill()
                }
                
                self.waitForExpectations(timeout: self.defaultTimeout) { (error) in
                    expectationSave = nil
                }
            }
            
            skip += limit
            
            weak var expectationPush = self.expectation(description: "Push")
            
            store.push { (count, errors) in
                XCTAssertNotNil(count)
                XCTAssertNil(errors)
                
                if let count = count {
                    XCTAssertGreaterThan(count, UInt(0))
                }
                
                expectationPush?.fulfill()
            }
            
            self.waitForExpectations(timeout: 60 * 5) { (error) in
                expectationPush = nil
            }
        }
    }
    
}
