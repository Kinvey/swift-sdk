//
//  DataTypeTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-22.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey
import ObjectMapper

class DataTypeTestCase: StoreTestCase {
    
    func testSave() {
        signUp()
        
        let store = DataStore<DataType>.getInstance(.Network)
        let dataType = DataType()
        dataType.boolValue = true
        dataType.colorValue = UIColor.orangeColor()
        
        let fullName = FullName()
        fullName.firstName = "Victor"
        fullName.lastName = "Barros"
        dataType.fullName = fullName
        
        let fullName2 = FullName2()
        fullName2.firstName = "Victor"
        fullName2.lastName = "Barros"
//        fullName2.fontDescriptor = UIFontDescriptor(name: "Arial", size: 12)
        dataType.fullName2 = fullName2
        
        let tuple = save(dataType, store: store)
        
        XCTAssertNotNil(tuple.savedPersistable)
        if let savedPersistable = tuple.savedPersistable {
            XCTAssertTrue(savedPersistable.boolValue)
        }
        
        let query = Query(format: "_acl.creator == %@", client.activeUser!.userId)
        
        weak var expectationFind = expectationWithDescription("Find")
        
        store.find(query) { results, error in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
                
                if let dataType = results.first {
                    XCTAssertTrue(dataType.boolValue)
                    XCTAssertEqual(dataType.colorValue, UIColor.orangeColor())
                    
                    XCTAssertNotNil(dataType.fullName)
                    if let fullName = dataType.fullName {
                        XCTAssertEqual(fullName.firstName, "Victor")
                        XCTAssertEqual(fullName.lastName, "Barros")
                    }
                    
                    XCTAssertNotNil(dataType.fullName2)
                    if let fullName = dataType.fullName2 {
                        XCTAssertEqual(fullName.firstName, "Victor")
                        XCTAssertEqual(fullName.lastName, "Barros")
                    }
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { (error) in
            expectationFind = nil
        }
    }
    
}

class DataType: NSObject, Persistable, BooleanType {
    
    dynamic var objectId: String?
    dynamic var boolValue: Bool = false
    dynamic var objectValue: NSObject?
    dynamic var colorValue: UIColor?
    dynamic var fullName: FullName?
    dynamic var fullName2: FullName2?
    
    static func kinveyCollectionName() -> String {
        return "DataType"
    }
    
    required init?(_ map: Map) {
    }
    
    override init() {
    }
    
    func mapping(map: Map) {
        objectId <- map[PersistableIdKey]
        boolValue <- map["boolValue"]
        objectValue <- map["objectValue"]
        colorValue <- map["colorValue"]
        fullName <- map["fullName"]
        fullName2 <- map["fullName2"]
    }
    
}

class FullName: NSObject, JsonObject {
    
    dynamic var firstName: String?
    dynamic var lastName: String?
    
    func toJson() -> JsonDictionary {
        var json = JsonDictionary()
        if let firstName = firstName {
            json["firstName"] = firstName
        }
        if let lastName = lastName {
            json["lastName"] = lastName
        }
        return json
    }
    
    func fromJson(json: JsonDictionary) {
        if let firstName = json["firstName"] as? String {
            self.firstName = firstName
        }
        if let lastName = json["lastName"] as? String {
            self.lastName = lastName
        }
    }
    
}

class FullName2: NSObject, JsonObject {
    
    dynamic var firstName: String?
    dynamic var lastName: String?
//    dynamic var fontDescriptor: UIFontDescriptor?
    
}

//extension UIFontDescriptor: Object {
//    
//    public func toJson() -> JsonDictionary {
//        return [
//            "name" : objectForKey(UIFontDescriptorNameAttribute)!,
//            "size" : objectForKey(UIFontDescriptorSizeAttribute)!
//        ]
//    }
//    
//    public convenience init?(json: JsonDictionary) {
//        self.init(name: json[UIFontDescriptorNameAttribute] as! String, size: json[UIFontDescriptorSizeAttribute] as! CGFloat)
//    }
//    
//}
