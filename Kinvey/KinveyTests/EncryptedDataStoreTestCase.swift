//
//  EncryptedDataStoreTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-22.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
import RealmSwift
@testable import Kinvey

class EncryptedDataStoreTestCase: StoreTestCase {
    
    lazy var filePath: NSString = {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        var filePath = paths.first! as NSString
        filePath = filePath.appendingPathComponent("com.kinvey.\(KinveyTestCase.appInitialize.appKey)_cache.realm") as NSString
        return filePath
    }()
    
    override func setUp() {
        encrypted = true
        
        deleteAllDocumentFiles()
        
        super.setUp()
    }
    
    func testEncryptedDataStore() {
        signUp()
        
        store = try! DataStore<Person>.collection(.network, options: try! Options(client: client))
        
        save(newPerson)
    }
    
    func testEncryptedDataStoreInstanceId() {
        dataStoreInstanceId(encrypted: true)
    }
    
    func testUnEncryptedDataStoreInstanceId() {
        dataStoreInstanceId(encrypted: false)
    }
    
    func dataStoreInstanceId(encrypted: Bool) {
        let appKey = UUID().uuidString
        let appSecret = UUID().uuidString
        let instanceId = "my-instance"
        
        let client = Client()
        client.initialize(appKey: appKey, appSecret: appSecret, instanceId: instanceId, encrypted: encrypted) {
            switch $0 {
            case .success(let user):
                XCTAssertNil(user)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        XCTContext.runActivity(named: "Pull") { activity in
            mockResponse(client: client) { request in
                XCTAssertEqual(request.url!.absoluteString, "https://\(instanceId)-baas.kinvey.com/appdata/\(appKey)/\(Person.collectionName())/")
                return HttpResponse(json: [])
            }
            defer {
                setURLProtocol(nil, client: client)
            }
            
            let options = try! Options(client: client)
            let dataStore = try! DataStore<Person>.collection(.sync, options: options)
            
            let expectationPull = expectation(description: "Pull")
            
            dataStore.pull(options: options) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 0)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationPull.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout)
            
            let data = try! Data(contentsOf: (dataStore.cache!.cache as! RealmCache<Person>).configuration.fileURL!)
            let dataString = String(data: data, encoding: .ascii)!
            let searchTerm = "Person"
            if encrypted {
                XCTAssertFalse(dataString.contains(searchTerm))
            } else {
                XCTAssertTrue(dataString.contains(searchTerm))
            }
        }
    }
    
    override func tearDown() {
        super.tearDown()
        
        store = nil
        
        deleteAllDocumentFiles()
    }
    
    fileprivate func deleteAllDocumentFiles() {
        let fileManager = FileManager.default
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let path = paths.first {
            let url = URL(fileURLWithPath: path)
            for url in try! fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [], options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]) {
                if fileManager.fileExists(atPath: url.path) {
                    try! fileManager.removeItem(at: url)
                }
            }
        }
    }
    
}
